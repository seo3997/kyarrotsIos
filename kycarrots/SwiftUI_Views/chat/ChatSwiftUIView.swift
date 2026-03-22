import SwiftUI

struct ChatSwiftUIView: View {
    @StateObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Auto-scroll to bottom
    @Namespace private var bottomID
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Custom Header (Matches Android Activity Bar)
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.leading, 12)
                
                Spacer()
                
                Text(viewModel.otherId)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Placeholder to keep title centered
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .frame(height: 56)
            .background(Color(UIColor.systemBackground))
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            
            // MARK: - Message List
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            // Spacer at top to push content down if list is short
                            Spacer(minLength: 0)
                            
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
                        .frame(minHeight: geometry.size.height)
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
        .toolbar(.hidden, for: .navigationBar)   // ✅ Hide system bar
        .task {
            viewModel.connect()
            await viewModel.loadHistory()
        }
        .onDisappear {
            viewModel.disconnect()
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
