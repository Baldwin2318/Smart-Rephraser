//
//  GeminiService.swift
//  Rephrase
//
//  Created by Baldwin Kiel Malabanan on 2025-02-10.
//

import Foundation

class GeminiService {
    let apiKey = APIKeys.gemini
    
    func sendPrompt(_ prompt: String, model: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Use Gemini 2.0 or 2.5 - the 1.5 models are deprecated
        let geminiModel = "gemini-2.0-flash"
        
        // Correct endpoint from official docs
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(geminiModel):generateContent?key=\(apiKey)") else { return }

        let headers = [
            "Content-Type": "application/json"
        ]

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
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
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    // Check for API error
                    if let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        let errorMessage = "Gemini API Error: \(message)"
                        completion(.failure(NSError(domain: "Gemini", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                        return
                    }
                    
                    // Parse Gemini response structure
                    if let candidates = json["candidates"] as? [[String: Any]],
                       let content = candidates.first?["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let text = parts.first?["text"] as? String {
                        completion(.success(text.trimmingCharacters(in: .whitespacesAndNewlines)))
                    } else {
                        completion(.failure(NSError(domain: "Invalid response", code: -1)))
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
