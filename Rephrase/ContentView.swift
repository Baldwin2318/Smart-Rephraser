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
    
    let openAIService = OpenAIService()
    
    private var clipBoardHasText: Bool {
        UIPasteboard.general.hasStrings
    }

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Text("Smart Rephraser ✍️")
                    .font(.largeTitle.bold())
                
                TextEditor(text: $inputText)
                    .frame(height: 150)
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray))
                    .focused($isTextEditorFocused)
                
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
                }
                .disabled(isLoading || inputText.isEmpty)
                
                if isLoading {
                    ProgressView("Asking ChatGPT...")
                } else {
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

                Spacer()
            }
            .padding()
            
            VStack {
                Spacer()
                withAnimation{
                    HStack{
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
             summarize
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
            prompt = "Summarize this sentence(straight to the point) in simple words and give analogy if necessary:\n\(inputText)"
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
}
