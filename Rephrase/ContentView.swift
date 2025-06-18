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
    @FocusState private var isTextEditorFocused: Bool
    @State private var isShowingScanner = false
    @State private var didCopy: Bool = false
    
    @State private var promptSuggestions: [String] = []
    @State private var isFetchingSuggestions = false
    
    let openAIService = OpenAIService()
    
    private var clipBoardHasText: Bool {
        UIPasteboard.general.hasStrings
    }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Text("Smart Rephraser")
                    .font(.largeTitle.bold())
                
                TextEditor(text: $inputText)
                    .frame(height: 150)
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                    .focused($isTextEditorFocused)
                
                ScrollView(.horizontal, showsIndicators: false){
                    
                    HStack {
                        Button("Rephrase") {
                            runAction(type: .rephrase)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Fix Grammar") {
                            runAction(type: .fixGrammar)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Summarize") {
                            runAction(type: .summarize)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Explain") {
                            runAction(type: .exlplain)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Analogy") {
                            runAction(type: .analogy)
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Send to ChatGPT") {
                            runAction(type: .chatgpt)
                        }
                        .buttonStyle(.bordered)
                    }
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
                    // Show AI-generated prompt suggestion buttons
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
                        fetchPromptSuggestions()
                    }
                }

                Spacer()
            }
            .padding()
            
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
    }
    
    enum ActionType {
        case rephrase,
             fixGrammar,
             summarize,
             exlplain,
             analogy,
             chatgpt
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

        openAIService.sendPrompt(prompt) { result in
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
    }
    
    /// Fetches 20 prompt suggestions from the AI.
    private func fetchPromptSuggestions() {
        guard !isFetchingSuggestions else { return }
        isFetchingSuggestions = true
        let suggestionPrompt = "Provide 20 concise prompt suggestions for asking ChatGPT. Give me straight in bullet points"
        openAIService.sendPrompt(suggestionPrompt) { result in
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
}
struct BouncingDots: View {
    @State private var scale: [CGFloat] = [1, 1, 1]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(scale[i])
                    .animation(Animation
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(i) * 0.2), value: scale[i])
            }
        }
        .onAppear {
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    scale[i] = 0.5
                }
            }
        }
    }
}
