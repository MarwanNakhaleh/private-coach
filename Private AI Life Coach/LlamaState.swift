//
//  LlamaState.swift
//  Private AI Life Coach
//
//  Created by Marwan Nakhaleh on 4/10/25.
//

import Foundation

@MainActor
class LlamaState: ObservableObject {
    @Published var messages = ""
    private var llamaContext: LlamaContext?

    func loadModel() throws {
        if let modelPath = Bundle.main.path(forResource: "Llama-3.2-1B-Instruct-Q4_K_M", ofType: "gguf") {
            llamaContext = try LlamaContext.create_context(path: modelPath)
            return
        }
    }

    func complete(text: String) async {
        guard let llamaContext else {
            return
        }

        let coachingPrompt = """
        You are a helpful life coach who understands people's underlying values and desires. You can recognize emotions in their words and recommend proactive actions to help them become the most effective person they can be in all areas of their lives.

        When responding, first acknowledge the emotions and values you detect in their message, then provide thoughtful guidance and specific actionable steps they can take.

        User's message: 
        """
        
        let fullPrompt = coachingPrompt + text
        
        await llamaContext.completion_init(text: fullPrompt)
        Task.detached {
            while await !llamaContext.is_done {
                let result = await llamaContext.completion_loop()
                await MainActor.run {
                    self.messages += "\(result)"
                }
            }
            await MainActor.run {
                self.messages += "\n"
            }
            await llamaContext.clear()
        }
    }

    func clear() async {
        guard let llamaContext else {
            return
        }
        await llamaContext.clear()
        messages = ""
    }
}

