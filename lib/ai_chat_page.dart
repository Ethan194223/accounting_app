import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Make sure this import is here

// A simple data model for a chat message.
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  // Controller for the text input field.
  final TextEditingController _textController = TextEditingController();
  // List to hold all chat messages.
  final List<ChatMessage> _messages = [];
  // State to show a loading indicator when the AI is typing.
  bool _isLoading = false;

  // STEP 1: Replace this placeholder with your new, valid OpenAI API key.
  // Do not share your new key publicly again.
  final String _apiKey = "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"; //

  @override
  void initState() {
    super.initState();
    // Add an initial "greeting" message from the AI.
    _messages.add(
      ChatMessage(
        text: "Hi! How can I help you with your budget today?", //
        isUser: false,
      ),
    );
  }

  // This function is called when the user taps the send button.
  void _handleSendPressed() async {
    final text = _textController.text; //
    if (text.isEmpty) return;

    // Clear the input field.
    _textController.clear(); //

    // Add the user's message to the chat list and update the UI.
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true)); //
      _isLoading = true; // Show loading indicator
    });

    try {
      // Send the message to the OpenAI API and get the response.
      final response = await _getGptResponse(text); //

      // Add the AI's response to the chat list.
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false)); //
        _isLoading = false; // Hide loading indicator
      });
    } catch (e) {
      // Handle any errors that occur during the API call.
      setState(() {
        _messages.add(ChatMessage(
            text: "Sorry, I'm having trouble connecting. Please try again.", //
            isUser: false));
        _isLoading = false; // Hide loading indicator
      });
      // You can also print the error to the console for debugging.
      debugPrint("Error fetching AI response: $e");
    }
  }

  // Function to communicate with the OpenAI Chat API.
  Future<String> _getGptResponse(String message) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions'); //

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json', //
        'Authorization': 'Bearer $_apiKey', //
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo', //
        // Construct the conversation history for the API.
        'messages': _messages.map((msg) {
          return {'role': msg.isUser ? 'user' : 'assistant', 'content': msg.text};
        }).toList(), //
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body); //
      // Extract the AI's message content from the response.
      return data['choices'][0]['message']['content'].trim(); //
    } else {
      // Throw an exception if the API call fails.
      throw Exception('Failed to get response from API: ${response.body}'); //
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'), //
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // The main chat area.
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatMessageBubble(message: message);
              },
            ),
          ),
          // Show a "typing" indicator while waiting for the AI response.
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  SizedBox(width: 8),
                  Text("AI is thinking..."),
                ],
              ),
            ),
          // The text input field and send button.
          _buildTextInputArea(),
        ],
      ),
    );
  }

  // Builds the text input widget at the bottom of the screen.
  Widget _buildTextInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Ask anything about budgeting...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                ),
                onSubmitted: (value) => _handleSendPressed(),
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _handleSendPressed,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A widget to display a single chat bubble with appropriate styling.
class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final bubbleAlignment =
    message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor =
    message.isUser ? Colors.blue[400] : Colors.grey[200];
    final textColor = message.isUser ? Colors.white : Colors.black87;

    return Align(
      alignment: bubbleAlignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(20.0),
        ),
        constraints: BoxConstraints(
          // Set a max width for bubbles so they don't span the entire screen.
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message.text,
          style: TextStyle(color: textColor, fontSize: 16),
        ),
      ),
    );
  }
}