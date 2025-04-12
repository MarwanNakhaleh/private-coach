//
//  Private_AI_Life_CoachApp.swift
//  Private AI Life Coach
//
//  Created by Marwan Nakhaleh on 4/9/25.
//

import SwiftUI
import CoreML

@main
struct Private_AI_Life_CoachApp: App {
    @State private var model: MLModel? = nil
    
    init() {
    }
    
    var body: some Scene {
        WindowGroup {
            QuestionnaireView()
        }
    }
}
