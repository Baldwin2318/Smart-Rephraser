//
//  OpenAIService.swift
//  Rephrase
//
//  Created by Baldwin Kiel Malabanan on 2025-06-16.
//

import Foundation

class OpenAIService {
    let apiKey = APIKeys.openAI
    
    func sendPrompt(_ prompt: String, model: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else { return }

        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        let body: [String: Any] = [
            "model": "gpt-4o",
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
            print(String(data: data, encoding: .utf8)!)

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content.trimmingCharacters(in: .whitespacesAndNewlines)))
                } else {
                    completion(.failure(NSError(domain: "Invalid response", code: -1)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
