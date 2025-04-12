import Foundation

struct Question: Codable, Identifiable {
    var id: String
    var text: String
    var options: [Option]
}

struct Option: Codable, Identifiable {
    var id: String
    var text: String
}

struct Questionnaire: Codable {
    var questions: [Question]
}

class UserResponses: ObservableObject {
    // For each question, store an ordered array of option IDs representing priorities
    @Published var prioritizedResponses: [String: [String]] = [:] {
        didSet {
            // Don't save the entire response set on each change
            // Instead we'll save individual question responses
        }
    }
    
    init() {
        loadResponsesFromDatabase()
    }
    
    // Add an option to the priority list or update its priority
    func toggleResponse(questionId: String, optionId: String) {
        // Initialize the array if it doesn't exist yet
        if prioritizedResponses[questionId] == nil {
            prioritizedResponses[questionId] = []
        }
        
        // If option is already selected, remove it and shift priorities
        if let index = prioritizedResponses[questionId]?.firstIndex(of: optionId) {
            prioritizedResponses[questionId]?.remove(at: index)
        } else {
            // Otherwise add it to the end (lowest priority of selected items)
            prioritizedResponses[questionId]?.append(optionId)
        }
        
        // Save this specific question's response immediately
        if let options = prioritizedResponses[questionId] {
            DatabaseManager.shared.saveQuestionnaireResponses(questionId: questionId, optionIds: options)
        }
    }
    
    // Get the priority of an option (1-based) or nil if not selected
    func getPriority(questionId: String, optionId: String) -> Int? {
        guard let options = prioritizedResponses[questionId],
              let index = options.firstIndex(of: optionId) else {
            return nil
        }
        return index + 1 // Convert to 1-based priority
    }
    
    // Check if an option is selected
    func isSelected(questionId: String, optionId: String) -> Bool {
        return prioritizedResponses[questionId]?.contains(optionId) ?? false
    }
    
    // Get the formatted responses as a string for the LLM
    func getFormattedResponses() -> String {
        var result = "User's prioritized goals:\n"
        
        for (questionId, optionIds) in prioritizedResponses {
            if let question = QuestionLoader.shared.getQuestion(id: questionId) {
                result += "- \(question.text)\n"
                
                for (index, optionId) in optionIds.enumerated() {
                    if let option = question.options.first(where: { $0.id == optionId }) {
                        result += "  Priority \(index + 1): \(option.text)\n"
                    }
                }
                result += "\n"
            }
        }
        
        return result
    }
    
    func clear() {
        prioritizedResponses = [:]
        DatabaseManager.shared.clearQuestionnaireResponses()
        setQuestionnaireCompleted(false)
    }
    
    // MARK: - Database Operations
    
    private func saveResponsesToDatabase() {
        // This is now only used for complete resets
        DatabaseManager.shared.clearQuestionnaireResponses()
        
        // Save all responses
        for (questionId, optionIds) in prioritizedResponses {
            DatabaseManager.shared.saveQuestionnaireResponses(questionId: questionId, optionIds: optionIds)
        }
    }
    
    private func loadResponsesFromDatabase() {
        prioritizedResponses = DatabaseManager.shared.getQuestionnaireResponses()
    }
    
    func setQuestionnaireCompleted(_ completed: Bool) {
        DatabaseManager.shared.saveUserSettings(key: "questionnaire_completed", value: completed ? "true" : "false")
    }
    
    func isQuestionnaireCompleted() -> Bool {
        return DatabaseManager.shared.getUserSetting(key: "questionnaire_completed") == "true"
    }
}

class QuestionLoader {
    static let shared = QuestionLoader()
    
    private var questionnaire: Questionnaire?
    
    private init() {
        loadQuestions()
    }
    
    func loadQuestions() {
        if let url = Bundle.main.url(forResource: "questions", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                questionnaire = try JSONDecoder().decode(Questionnaire.self, from: data)
            } catch {
                print("Error loading questions: \(error)")
            }
        }
    }
    
    func getQuestions() -> [Question] {
        return questionnaire?.questions ?? []
    }
    
    func getQuestion(id: String) -> Question? {
        return questionnaire?.questions.first(where: { $0.id == id })
    }
} 