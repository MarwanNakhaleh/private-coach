import Foundation
import GRDB

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private var dbQueue: DatabaseQueue!
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            let fileManager = FileManager.default
            let folderURL = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("database", isDirectory: true)
            
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            
            let dbURL = folderURL.appendingPathComponent("coach.sqlite")
            dbQueue = try DatabaseQueue(path: dbURL.path)
            
            try dbQueue.write { db in
                try db.create(table: "user_settings", ifNotExists: true) { t in
                    t.column("id", .text).primaryKey()
                    t.column("value", .text)
                }
                
                try db.create(table: "questionnaire_responses", ifNotExists: true) { t in
                    t.column("question_id", .text)
                    t.column("option_ids", .text)
                    t.primaryKey(["question_id"])
                }
            }
            
            // Print database path for debugging
            print("Database path: \(dbURL.path)")
        } catch {
            print("Database setup error: \(error)")
        }
    }
    
    func saveUserSettings(key: String, value: String) {
        do {
            try dbQueue.write { db in
                try db.execute(
                    sql: "INSERT OR REPLACE INTO user_settings (id, value) VALUES (?, ?)",
                    arguments: [key, value]
                )
            }
        } catch {
            print("Error saving user setting: \(error)")
        }
    }
    
    func getUserSetting(key: String) -> String? {
        do {
            return try dbQueue.read { db in
                try String.fetchOne(db, sql: "SELECT value FROM user_settings WHERE id = ?", arguments: [key])
            }
        } catch {
            print("Error reading user setting: \(error)")
            return nil
        }
    }
    
    func saveQuestionnaireResponses(questionId: String, optionIds: [String]) {
        do {
            let optionsJson = try JSONEncoder().encode(optionIds)
            let optionsString = String(data: optionsJson, encoding: .utf8)!
            
            try dbQueue.write { db in
                try db.execute(
                    sql: "INSERT OR REPLACE INTO questionnaire_responses (question_id, option_ids) VALUES (?, ?)",
                    arguments: [questionId, optionsString]
                )
            }
        } catch {
            print("Error saving questionnaire response: \(error)")
        }
    }
    
    func getQuestionnaireResponses() -> [String: [String]] {
        do {
            let rows = try dbQueue.read { db in
                try Row.fetchAll(db, sql: "SELECT question_id, option_ids FROM questionnaire_responses")
            }
            
            var results: [String: [String]] = [:]
            
            for row in rows {
                let questionId = row["question_id"] as! String
                let optionsString = row["option_ids"] as! String
                
                if let optionsData = optionsString.data(using: .utf8),
                   let options = try? JSONDecoder().decode([String].self, from: optionsData) {
                    results[questionId] = options
                }
            }
            
            return results
        } catch {
            print("Error reading questionnaire responses: \(error)")
            return [:]
        }
    }
    
    func clearQuestionnaireResponses() {
        do {
            try dbQueue.write { db in
                try db.execute(sql: "DELETE FROM questionnaire_responses")
            }
        } catch {
            print("Error clearing questionnaire responses: \(error)")
        }
    }
    
    func saveLastAnsweredQuestionIndex(_ index: Int) {
        saveUserSettings(key: "last_answered_question_index", value: String(index))
    }
    
    func getLastAnsweredQuestionIndex() -> Int {
        if let indexStr = getUserSetting(key: "last_answered_question_index"),
           let index = Int(indexStr) {
            return index
        }
        return 0
    }
} 