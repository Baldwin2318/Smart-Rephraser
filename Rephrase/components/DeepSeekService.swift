//
//  DeepSeekService.swift
//  Rephrase
//
//  Created by Baldwin Kiel Malabanan on 2025-06-21.
//

import Foundation

class DeepSeekService {
    let apiKey = APIKeys.deepSeek
    
    func sendPrompt(_ prompt: String, model: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.deepseek.com/v1/chat/completions") else { return }

        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: -1)))
                return
            }
            
            // Print the raw response to see what we're getting
            if let responseString = String(data: data, encoding: .utf8) {
                print("DeepSeek Response:", responseString)
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    // Check for API error first
                    if let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        let errorMessage = "DeepSeek API Error: \(message)"
                        completion(.failure(NSError(domain: "DeepSeek", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                        return
                    }
                    
                    // Parse success response
                    if let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
                    } else {
                        completion(.failure(NSError(domain: "Invalid response structure", code: -1)))
                    }
                } else {
                    completion(.failure(NSError(domain: "Invalid JSON", code: -1)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
