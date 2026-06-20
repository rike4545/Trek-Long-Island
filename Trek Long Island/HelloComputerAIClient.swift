// Copyright Bryan Carroll. All rights reserved.
//
//  HelloComputerAIClient.swift
//  Trek Long Island
//
//  Created by Bryan on 1/31/26.
//


import Foundation
import CoreML

protocol HelloComputerAIClient {
    func generateReply(userMessage: String, conversation: [HelloComputerMessage]) async throws -> String
}

/// Default: disabled (offline-only). Safe for App Store.
struct HelloComputerNoAIClient: HelloComputerAIClient {
    func generateReply(userMessage: String, conversation: [HelloComputerMessage]) async throws -> String {
        throw NSError(domain: "HelloComputer", code: 0, userInfo: [NSLocalizedDescriptionKey: "AI is not configured."])
    }
}

/// On-device AI client backed by a bundled Core ML model.
/// If no model is bundled yet, it returns a deterministic offline fallback.
struct HelloComputerCoreMLClient: HelloComputerAIClient {
    private let model: MLModel?

    init(modelName: String = "HelloComputerAssistant") {
        self.model = Self.loadModel(named: modelName)
    }

    func generateReply(userMessage: String, conversation: [HelloComputerMessage]) async throws -> String {
        let trimmed = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Please share a question so I can help."
        }

        if let retrievalAnswer = HelloComputerEngine.semanticFallbackAnswer(for: trimmed) {
            return """
            \(retrievalAnswer.text)

            — Source: On-device semantic retrieval
            """
        }

        if model != nil {
            // Model is present and ready; this is intentionally conservative until
            // model I/O schema is finalized.
            let recentContext = conversation
                .suffix(3)
                .map(\.text)
                .joined(separator: " | ")

            if recentContext.isEmpty {
                return "Core ML assistant is online. I received: \"\(trimmed)\". I can answer with local schedule and FAQ context."
            }

            return """
            Core ML assistant is online. I received: "\(trimmed)".
            Recent context: \(recentContext)
            I can answer with local schedule and FAQ context.
            """
        }

        return """
        AI Agent is running in offline mode right now. I could not find a strong semantic match for that question yet.
        Try asking with one or two concrete keywords like a guest name, room, event type, or “what’s next”.
        """
    }

    private static func loadModel(named name: String) -> MLModel? {
        let configuration = MLModelConfiguration()

        if let compiledURL = Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
            return try? MLModel(contentsOf: compiledURL, configuration: configuration)
        }
        return nil
    }
}
