//
//  UsageFetcher.swift
//  Rephrase
//
//  Created by Baldwin Kiel Malabanan on 2026-02-10.
//

import Foundation

struct UsageInfo {
    let provider: String
    let totalUsed: Double
    let limit: Double?
    let unit: String // "USD", "credits", etc.
    let details: String?
}

class UsageFetcher {
    
    // MARK: - OpenAI
    // Note: OpenAI requires organization access for billing API
    static func fetchOpenAIUsage(completion: @escaping (Result<UsageInfo, Error>) -> Void) {
        // First validate the API key by listing models
        guard let modelsURL = URL(string: "https://api.openai.com/v1/models") else { return }
        
        var modelsRequest = URLRequest(url: modelsURL)
        modelsRequest.addValue("Bearer \(APIKeys.openAI)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: modelsRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let httpResponse = response as? HTTPURLResponse
            let isValid = httpResponse?.statusCode == 200
            
            guard isValid else {
                let usage = UsageInfo(
                    provider: "OpenAI",
                    totalUsed: 0,
                    limit: nil,
                    unit: "USD",
                    details: "API key invalid"
                )
                completion(.success(usage))
                return
            }
            
            // Key is valid — now try fetching costs (requires admin key)
            let now = Date()
            let calendar = Calendar.current
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            
            let startTimestamp = Int(startOfMonth.timeIntervalSince1970)
            let endTimestamp = Int(now.timeIntervalSince1970)
            
            guard let costsURL = URL(string: "https://api.openai.com/v1/organization/costs?start_time=\(startTimestamp)&end_time=\(endTimestamp)") else { return }
            
            var costsRequest = URLRequest(url: costsURL)
            costsRequest.addValue("Bearer \(APIKeys.openAIAdmin)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: costsRequest) { data, response, error in
                let costsResponse = response as? HTTPURLResponse
                
                // If costs endpoint fails (no admin key), still show valid key status
                guard costsResponse?.statusCode == 200,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    let usage = UsageInfo(
                        provider: "OpenAI",
                        totalUsed: 0,
                        limit: nil,
                        unit: "USD",
                        details: "Key valid • Usage: check platform.openai.com"
                    )
                    completion(.success(usage))
                    return
                }
                
                var totalCents: Double = 0
                if let results = json["data"] as? [[String: Any]] {
                    for result in results {
                        if let costs = result["results"] as? [[String: Any]] {
                            for cost in costs {
                                totalCents += cost["amount"] as? Double ?? 0
                            }
                        }
                    }
                }
                
                let totalUSD = totalCents / 100.0
                
                let usage = UsageInfo(
                    provider: "OpenAI",
                    totalUsed: totalUSD,
                    limit: nil,
                    unit: "USD",
                    details: "This month's usage"
                )
                completion(.success(usage))
            }.resume()
            
        }.resume()
    }
    
    // MARK: - Gemini (Google AI)
    // Note: Gemini free tier doesn't have a billing API
    // For Vertex AI, you'd use Google Cloud Billing API
    static func fetchGeminiUsage(completion: @escaping (Result<UsageInfo, Error>) -> Void) {
        // Verify API key is valid by listing models
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(APIKeys.gemini)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let httpResponse = response as? HTTPURLResponse
            let isValid = httpResponse?.statusCode == 200
            
            let usage = UsageInfo(
                provider: "Gemini",
                totalUsed: 0,
                limit: nil,
                unit: "requests",
                details: isValid ? "Free tier: 60 req/min, 1500/day" : "API key invalid"
            )
            completion(.success(usage))
        }.resume()
    }
    
    // MARK: - DeepSeek
    static func fetchDeepSeekUsage(completion: @escaping (Result<UsageInfo, Error>) -> Void) {
        guard let url = URL(string: "https://api.deepseek.com/user/balance") else { return }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(APIKeys.deepSeek)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failure(NSError(domain: "Parse error", code: -1)))
                return
            }
            
            // DeepSeek returns balance info
            let balanceInfo = json["balance_infos"] as? [[String: Any]] ?? []
            var totalBalance: Double = 0
            
            for info in balanceInfo {
                if let balance = info["total_balance"] as? String {
                    totalBalance += Double(balance) ?? 0
                }
            }
            
            let usage = UsageInfo(
                provider: "DeepSeek",
                totalUsed: totalBalance,
                limit: nil,
                unit: "CNY",
                details: "Available balance"
            )
            
            completion(.success(usage))
        }.resume()
    }
}
