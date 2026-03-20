import SwiftUI

struct ChatSwiftUIView: View {
    @StateObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Auto-scroll to bottom
    @Namespace private var bottomID
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Message List
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        // Spacer at top if few messages
                        Spacer()
                            .frame(minHeight: 0, maxHeight: .infinity)
                        
                        ForEach(viewModel.chatMessages.indices, id: \.self) { index in
                            let msg = viewModel.chatMessages[index]
                            ChatBubbleView(message: msg)
                                .id(index)
                        }
                        
                        // Reference for scrolling to bottom
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding()
                }
                .onChange(of: viewModel.chatMessages.count) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onAppear {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            
            // MARK: - Input Bar
            Divider()
            
            HStack(spacing: 12) {
                TextField("메시지를 입력하세요", text: $viewModel.messageText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.vertical, 8)
                    .submitLabel(.send)
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Text("전송")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewModel.messageText.isEmpty ? Color.gray : Color.green)
                        .cornerRadius(8)
                }
                .disabled(viewModel.messageText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(Color(UIColor.systemBackground))
        }
        .navigationTitle("\(viewModel.otherId) 님과의 대화")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
            }
        }
        .task {
            viewModel.connect()
            await viewModel.loadHistory()
        }
    }
}

// MARK: - Chat Bubble View
struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isMe == true {
                Spacer()
                
                // Time
                Text(formatTime(message.time))
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                // Bubble
                Text(message.message)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
            } else {
                // Bubble
                Text(message.message)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                // Time
                Text(formatTime(message.time))
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
    }
    
    func formatTime(_ fullTimeStr: String?) -> String {
        guard let fullTimeStr = fullTimeStr else { return "" }
        // original format: "yyyy-MM-dd HH:mm"
        // Return only "HH:mm" for better UI
        let parts = fullTimeStr.components(separatedBy: " ")
        if parts.count >= 2 {
            return parts[1]
        }
        return fullTimeStr
    }
}

#Preview {
    NavigationView {
        ChatSwiftUIView(viewModel: ChatViewModel(
            roomId: "test_room",
            currentUserId: "user1",
            buyerId: "user1",
            branchId: "user2"
        ))
    }
}
