import SwiftUI

struct QuestionnaireView: View {
    @StateObject private var userResponses = UserResponses()
    @State private var currentQuestionIndex = 0
    @State private var showChat = false
    
    private var questions: [Question] = QuestionLoader.shared.getQuestions()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Tell me about yourself")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 30)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                if questions.isEmpty {
                    Text("No questions available")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                } else if currentQuestionIndex < questions.count {
                    questionView
                } else {
                    completionView
                }
            }
            .padding()
            .navigationDestination(isPresented: $showChat) {
                ChatView(userResponses: userResponses)
            }
        }
    }
    
    private var questionView: some View {
        let question = questions[currentQuestionIndex]
        
        return VStack(alignment: .leading, spacing: 20) {
            Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(question.text)
                .font(.title2)
                .fontWeight(.medium)
                .padding(.bottom, 5)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
            
            Text("Select options in order of priority (click again to deselect)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
            
            ForEach(question.options) { option in
                PriorityOptionButton(
                    option: option,
                    questionId: question.id,
                    userResponses: userResponses
                )
            }
            
            Spacer()
            
            HStack {
                if currentQuestionIndex > 0 {
                    Button(action: {
                        withAnimation {
                            currentQuestionIndex -= 1
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.gray)
                        .cornerRadius(10)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        if userResponses.prioritizedResponses[question.id]?.isEmpty == false {
                            currentQuestionIndex += 1
                        }
                    }
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(userResponses.prioritizedResponses[question.id]?.isEmpty == false ? Color.blue : Color.gray)
                    .cornerRadius(10)
                }
                .disabled(userResponses.prioritizedResponses[question.id]?.isEmpty != false)
            }
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 20) {
            Text("Thank you for answering!")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("I now have a better understanding of your goals. Let's start our coaching session.")
                .multilineTextAlignment(.center)
                .padding()
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: {
                showChat = true
            }) {
                Text("Begin Coaching Session")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button(action: {
                userResponses.clear()
                currentQuestionIndex = 0
            }) {
                Text("Start Over")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
    }
}

struct PriorityOptionButton: View {
    let option: Option
    let questionId: String
    @ObservedObject var userResponses: UserResponses
    
    var body: some View {
        Button(action: {
            userResponses.toggleResponse(questionId: questionId, optionId: option.id)
        }) {
            HStack {
                Text(option.text)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .primary)
                    .padding()
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if let priority = userResponses.getPriority(questionId: questionId, optionId: option.id) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                        
                        Text("\(priority)")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    private var isSelected: Bool {
        userResponses.isSelected(questionId: questionId, optionId: option.id)
    }
} 