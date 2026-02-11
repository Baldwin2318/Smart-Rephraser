//
//  UsageView.swift
//  Rephrase
//
//  Created by Baldwin Kiel Malabanan on 2026-02-10.
//

import SwiftUI

struct UsageView: View {
    @State private var openAIUsage: UsageInfo?
    @State private var geminiUsage: UsageInfo?
    @State private var deepSeekUsage: UsageInfo?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    // OpenAI
                    UsageRow(
                        provider: "OpenAI",
                        icon: "brain.head.profile",
                        color: .green,
                        usage: openAIUsage
                    )
                    
                    // Gemini
                    UsageRow(
                        provider: "Gemini",
                        icon: "sparkles",
                        color: .blue,
                        usage: geminiUsage
                    )
                    
                    // DeepSeek
                    UsageRow(
                        provider: "DeepSeek",
                        icon: "magnifyingglass",
                        color: .purple,
                        usage: deepSeekUsage
                    )
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("API Usage")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: fetchAllUsage) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            fetchAllUsage()
        }
    }
    
    private func fetchAllUsage() {
        isLoading = true
        errorMessage = nil
        
        let group = DispatchGroup()
        
        // OpenAI
        group.enter()
        UsageFetcher.fetchOpenAIUsage { result in
            DispatchQueue.main.async {
                if case .success(let usage) = result {
                    openAIUsage = usage
                }
                group.leave()
            }
        }
        
        // Gemini
        group.enter()
        UsageFetcher.fetchGeminiUsage { result in
            DispatchQueue.main.async {
                if case .success(let usage) = result {
                    geminiUsage = usage
                }
                group.leave()
            }
        }
        
        // DeepSeek
        group.enter()
        UsageFetcher.fetchDeepSeekUsage { result in
            DispatchQueue.main.async {
                if case .success(let usage) = result {
                    deepSeekUsage = usage
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            isLoading = false
        }
    }
}

struct UsageRow: View {
    let provider: String
    let icon: String
    let color: Color
    let usage: UsageInfo?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(provider)
                    .font(.headline)
                
                if let usage = usage {
                    Text(String(format: "%.4f %@", usage.totalUsed, usage.unit))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let details = usage.details {
                        Text(details)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let limit = usage.limit {
                        ProgressView(value: usage.totalUsed, total: limit)
                            .tint(usage.totalUsed / limit > 0.8 ? .red : .green)
                        Text("\(Int((usage.totalUsed / limit) * 100))% of \(String(format: "%.2f", limit)) \(usage.unit)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Unable to fetch")
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
