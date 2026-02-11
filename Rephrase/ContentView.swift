//
//  ContentView.swift
//  Rephrase
//
//  Created by Baldwin Kiel Malabanan on 2025-06-16.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var isLoading: Bool = false
    @State private var isShowingScanner = false
    @State private var didCopy: Bool = false
    @State private var isFetchingSuggestions = false
    @State private var promptSuggestions: [String] = []
    @State private var availableModels: [String] = []
    @State private var isLoadingModels: Bool = false

    
    // Provider selection
    @State private var selectedProvider: AIProvider = .gemini
    @State private var selectedModel: String = "gemini-2.0-flash"
    
    @FocusState private var isTextEditorFocused: Bool
    
    // All services
    let openAIService = OpenAIService()
    let geminiService = GeminiService()
    let deepSeekService = DeepSeekService()
    
    enum AIProvider: String, CaseIterable {
        case openai = "OpenAI"
        case gemini = "Gemini"
        case deepseek = "DeepSeek"
    }

//    // Models per provider
//    var availableModels: [String] {
//        switch selectedProvider {
//        case .openai:
//            return [
//                "gpt-4o",
//                "gpt-4o-mini",
//                "gpt-4-turbo",
//                "gpt-4",
//                "gpt-3.5-turbo"
//            ]
//        case .gemini:
//            return [
//                "gemini-2.0-flash",
//                "gemini-2.5-flash",
//                "gemini-2.5-pro"
//            ]
//        case .deepseek:
//            return [
//                "deepseek-chat",
//                "deepseek-coder"
//            ]
//        }
//    }
    
    private var clipBoardHasText: Bool { UIPasteboard.general.hasStrings }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 16) {
//                    Text("MUX")
//                        .font(.largeTitle.bold())
                    
                    HStack {
                        Picker("Model", selection: $selectedModel) {
                            ForEach(availableModels, id: \.self) { model in
                                Text(formatModelName(model)).tag(model)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    TextEditor(text: $inputText)
                        .frame(height: 150)
                        .padding()
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                        .focused($isTextEditorFocused)
                 
                    HStack{
                        ScrollView(.horizontal, showsIndicators: false){
                            HStack {
                                Button("Rephrase") { runAction(type: .rephrase) }.buttonStyle(.bordered)
                                Button("Fix Grammar") { runAction(type: .fixGrammar) }.buttonStyle(.bordered)
//                                Button("Summarize") { runAction(type: .summarize) }.buttonStyle(.bordered)
//                                Button("Explain") { runAction(type: .exlplain) }.buttonStyle(.bordered)
//                                Button("Analogy") { runAction(type: .analogy) }.buttonStyle(.bordered)
                            }
                            .disabled(isLoading || inputText.isEmpty)
                        }
                        Spacer()
                        Button(action: { runAction(type: .chatgpt) }) {
                            Image(systemName: "arrow.up")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoading || inputText.isEmpty)
                    }
                    
                    if isLoading {
                        HStack(spacing: 10) {
                            BouncingDots()
                        }
                    } else if !outputText.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(outputText)
                                    .padding()
                                    .padding(.top, 30)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                    .overlay(alignment: .topTrailing) {
                                        Button(action: {
                                            UIPasteboard.general.string = outputText
                                            didCopy = true
                                        }) {
                                            Label(didCopy ? "Copied!" : "Copy", systemImage: "doc.on.docs")
                                                .padding(8)
                                            //.background(Color(.systemBackground).opacity(0.8))
                                                .clipShape(Capsule())
                                        }
                                        .padding(8)
                                        .disabled(outputText.isEmpty || didCopy)
                                    }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                    else if outputText.isEmpty{
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(promptSuggestions, id: \.self) { suggestion in
                                    Button(action: {
                                        inputText = suggestion
                                    }) {
                                        Text(suggestion)
                                            .padding(.horizontal)
                                            .padding(.vertical, 8)
                                            .background(Color.gray.opacity(0))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                        .onAppear {
                            //                        fetchPromptSuggestions()
                        }
                    }
                    Spacer()
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Picker("Provider", selection: $selectedProvider) {
                            ForEach(AIProvider.allCases, id: \.self) { provider in
                                Text(provider.rawValue).tag(provider)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(destination: UsageView()) {
                            Image(systemName: "chart.bar.fill")
                        }
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                
                VStack {
                    Spacer()
                    withAnimation{
                        HStack{
                            if (!inputText.isEmpty){
                                Button(action: {
                                    inputText = ""
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.title2)
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .foregroundStyle(.red)
                                        .clipShape(Circle())
                                        .shadow(radius: 6)
                                }
                            }
                            
                            Spacer()
                            
                            //                        Button(action: {
                            //                            isShowingScanner = true
                            //                        }) {
                            //                            Image(systemName: "doc.viewfinder")
                            //                                .font(.title2)
                            //                                .padding()
                            //                                .background(Color(.systemBackground))
                            //                                .clipShape(Circle())
                            //                                .shadow(radius: 4)
                            //                        }
                            
                            Button(action: {
                                if let pasteText = UIPasteboard.general.string {
                                    inputText = pasteText
                                }
                            }) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.title2)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            .disabled(!clipBoardHasText)
                            
                            
                            if isTextEditorFocused {
                                Button(action: {
                                    isTextEditorFocused = false
                                }) {
                                    Image(systemName: "keyboard.chevron.compact.down")
                                        .font(.title2)
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                }
                            }
                        }
                        .padding()
                    }
                    .animation(.easeInOut(duration: 0.5), value: isTextEditorFocused)
                }
                
            }
            .sheet(isPresented: $isShowingScanner) {
                DocumentScannerView { scannedText in
                    self.inputText = scannedText
                }
            }
            .onChange(of: outputText) { _ in
                didCopy = false
            }
            .onChange(of: selectedProvider) { _ in
                selectedModel = availableModels.first ?? ""
            }
            .onAppear {
                fetchModelsForProvider()
            }
            .onChange(of: selectedProvider) { _ in
                fetchModelsForProvider()
            }
        }
    }
    
    enum ActionType {
        case rephrase,
             fixGrammar,
             summarize,
             exlplain,
             analogy,
             chatgpt
    }
    
    class ModelCache {
        static let shared = ModelCache()
        
        private var cache: [AIProvider: [String]] = [:]
        
        func get(_ provider: AIProvider) -> [String]? {
            return cache[provider]
        }
        
        func set(_ provider: AIProvider, models: [String]) {
            cache[provider] = models
        }
    }

    func runAction(type: ActionType) {
        isLoading = true
        outputText = ""

        let prompt: String
        switch type {
        case .rephrase:
            prompt = "Rephrase the following sentence in a clearer way:\n\(inputText)"
        case .fixGrammar:
            prompt = "Fix any grammar and punctuation mistakes in this sentence:\n\(inputText)"
        case .summarize:
            prompt = "Summarize this sentence in simple words, make a bullet points:\n\(inputText)"
        case .exlplain:
            prompt = "Explain this sentence in simple words:\n\(inputText)"
        case .analogy:
            prompt = "Give this sentence an analogy:\n\(inputText)"
        case .chatgpt:
            prompt = "\(inputText)"
        }

        let completion: (Result<String, Error>) -> Void = { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    self.outputText = response
                case .failure(let error):
                    self.outputText = "Error: \(error.localizedDescription)"
                }
            }
        }
        
        // Call the appropriate service
        switch selectedProvider {
        case .openai:
            openAIService.sendPrompt(prompt, model: selectedModel, completion: completion)
        case .gemini:
            geminiService.sendPrompt(prompt, model: selectedModel, completion: completion)
        case .deepseek:
            deepSeekService.sendPrompt(prompt, model: selectedModel, completion: completion)
        }
    }
    
    /// Fetches 20 prompt suggestions from the AI.
    private func fetchPromptSuggestions() {
        guard !isFetchingSuggestions else { return }
        isFetchingSuggestions = true
        let suggestionPrompt = "Hello what can you do? answer in simple, basic, short and friendly way"
        openAIService.sendPrompt(suggestionPrompt, model: selectedModel) { result in
            DispatchQueue.main.async {
                isFetchingSuggestions = false
                switch result {
                case .success(let response):
                    // Split on newlines and trim
                    promptSuggestions = response
                        .split(separator: "\n")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                case .failure:
                    promptSuggestions = []
                }
            }
        }
    }
    
    private func fetchModelsForProvider() {
        isLoadingModels = true
        availableModels = []
        
        let completion: (Result<[String], Error>) -> Void = { result in
            DispatchQueue.main.async {
                isLoadingModels = false
                switch result {
                case .success(let models):
                    availableModels = models
                    selectedModel = models.first ?? ""
                case .failure(let error):
                    print("Failed to fetch models: \(error)")
                    // Fallback to defaults
                    availableModels = getDefaultModels()
                    selectedModel = availableModels.first ?? ""
                }
            }
        }
        
        switch selectedProvider {
        case .openai:
            ModelFetcher.fetchOpenAIModels(completion: completion)
        case .gemini:
            ModelFetcher.fetchGeminiModels(completion: completion)
        case .deepseek:
            ModelFetcher.fetchDeepSeekModels(completion: completion)
        }
    }
    
    private func getDefaultModels() -> [String] {
        switch selectedProvider {
        case .openai: return ["gpt-4o", "gpt-4o-mini"]
        case .gemini: return ["gemini-2.0-flash", "gemini-2.5-flash"]
        case .deepseek: return ["deepseek-chat"]
        }
    }
    
    private func formatModelName(_ model: String) -> String {
        model.replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

