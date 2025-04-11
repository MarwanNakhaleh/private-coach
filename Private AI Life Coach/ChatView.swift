import SwiftUI

struct ChatView: View {
    @StateObject private var llamaState = LlamaState()
    @State private var multiLineText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat messages area
            ScrollViewReader { proxy in
                Text("Private AI Life Coach")
                    .font(.largeTitle)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                ScrollView {
                    VStack {
                        Text(.init(llamaState.messages))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        // Invisible view at the bottom for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("bottomID")
                    }
                }
                .onChange(of: llamaState.messages) {
                    withAnimation {
                        proxy.scrollTo("bottomID", anchor: .bottom)
                    }
                }
                .onAppear {
                    // Scroll to bottom when view appears
                    proxy.scrollTo("bottomID", anchor: .bottom)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            
            Divider()
                 
            // Input area
            HStack(alignment: .bottom) {
                // Text editor
                ZStack(alignment: .leading) {
                    TextEditor(text: $multiLineText)
                        .padding(4)
                        .cornerRadius(10)
                        .frame(minHeight: 40, maxHeight: 120)
                }
                
                // Send button
                VStack(spacing: 8) {
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.blue)
                    }
                    
                    // Clear button
                    Button(action: clearMessages) {
                        Image(systemName: "trash.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
        }
    }
    
    private func sendMessage() {
        llamaState.messages += "\n\n"
        llamaState.messages += "*\(multiLineText)*"
        llamaState.messages += "\n\n"
        do {
            try llamaState.loadModel()
        } catch {
            llamaState.messages += "Error!\n"
        }
        Task {
            await llamaState.complete(text: multiLineText)
            multiLineText = ""
        }
    }
    
    private func clearMessages() {
        Task {
            await llamaState.clear()
        }
    }
}
