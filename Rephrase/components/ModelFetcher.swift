//
//  ModelFetcher.swift
//  Rephrase
//
//  Created by Baldwin Kiel Malabanan on 2026-02-10.
//

import Foundation

class ModelFetcher {
    
    // MARK: - OpenAI
    static func fetchOpenAIModels(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/models") else { return }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(APIKeys.openAI)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let models = json["data"] as? [[String: Any]] else {
                completion(.failure(NSError(domain: "Parse error", code: -1)))
                return
            }
            
            let modelIds = models
                .compactMap { $0["id"] as? String }
                .filter { $0.contains("gpt") } // Filter to just GPT models
                .sorted()
            
            completion(.success(modelIds))
        }.resume()
    }
    
    // MARK: - Gemini
    static func fetchGeminiModels(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(APIKeys.gemini)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let models = json["models"] as? [[String: Any]] else {
                completion(.failure(NSError(domain: "Parse error", code: -1)))
                return
            }
            
            let modelIds = models
                .compactMap { $0["name"] as? String }
                .map { $0.replacingOccurrences(of: "models/", with: "") } // Remove "models/" prefix
                .filter { $0.contains("gemini") } // Filter to Gemini models
                .sorted()
            
            completion(.success(modelIds))
        }.resume()
    }
    
    // MARK: - DeepSeek
    static func fetchDeepSeekModels(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: "https://api.deepseek.com/models") else { return }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(APIKeys.deepSeek)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let models = json["data"] as? [[String: Any]] else {
                completion(.failure(NSError(domain: "Parse error", code: -1)))
                return
            }
            
            let modelIds = models
                .compactMap { $0["id"] as? String }
                .sorted()
            
            completion(.success(modelIds))
        }.resume()
    }
}
