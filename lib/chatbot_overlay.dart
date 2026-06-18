import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_state.dart';

class ChatbotOverlay extends StatefulWidget {
  final Widget child;
  const ChatbotOverlay({super.key, required this.child});

  @override
  State<ChatbotOverlay> createState() => _ChatbotOverlayState();
}

class _ChatbotOverlayState extends State<ChatbotOverlay> {
  bool _isOpen = false;
  final TextEditingController _msgCtrl = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollCtrl = ScrollController();

  double _dx = 20;
  double _dy = 80;

  // Ganti dengan API Key Groq Anda yang asli
  // Menggunakan API key secara langsung untuk pengujian seperti permintaan pengguna
  static const String _groqApiKey = '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';

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _msgCtrl.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    if (_groqApiKey.isEmpty || _groqApiKey == 'gsk_...o1A4') {
      setState(() {
        _messages.add({
          "role": "assistant",
          "content": "API Key Groq belum dikonfigurasi. Masukkan API Key Anda di chatbot_overlay.dart.",
        });
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile', // Bisa juga 'mixtral-8x7b-32768'
          'messages': [
            {
              'role': 'system',
              'content': 'Kamu adalah asisten pendidikan untuk EduQuiz Interactive. Jawab pertanyaan siswa dan guru tentang materi pelajaran, kuis, dan penggunaan aplikasi. Gunakan bahasa Indonesia yang ramah dan mudah dipahami.'
            },
            ..._messages.map((m) => {
              'role': m['role'] == 'user' ? 'user' : 'assistant',
              'content': m['content']
            }),
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'];
        setState(() {
          _messages.add({"role": "assistant", "content": reply});
        });
      } else {
        String errorMsg = "Gagal: ${response.statusCode} - ${response.body}";
        setState(() {
          _messages.add({"role": "assistant", "content": errorMsg});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"role": "assistant", "content": "Error: $e"});
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appThemeMode.value == ThemeMode.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final borderColor = isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          ValueListenableBuilder<bool>(
            valueListenable: showChatbot,
            builder: (context, visible, _) {
              if (!visible) return const SizedBox.shrink();
              return Stack(
                children: [
                  if (_isOpen)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _isOpen = false),
                      child: Container(color: Colors.black.withValues(alpha: 0.01)),
                    ),
                  if (_isOpen)
                    Positioned(
                      bottom: _dy,
                      right: _dx,
                      width: 320,
                      height: 480,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(16),
                        color: bgColor,
                        child: Column(
                          children: [
                            GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  _dx -= details.delta.dx;
                                  _dy -= details.delta.dy;
                                  final size = MediaQuery.of(context).size;
                                  if (_dx < 0) _dx = 0;
                                  if (_dy < 0) _dy = 0;
                                  if (_dx > size.width - 320) _dx = size.width - 320;
                                  if (_dy > size.height - 480) _dy = size.height - 480;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0056A8),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("EduQuiz AI Helper", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => setState(() => _isOpen = false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: _messages.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.smart_toy_outlined, size: 48, color: isDark ? Colors.grey[600] : const Color(0xFFCBD5E1)),
                                            const SizedBox(height: 16),
                                            Text("Hai! Saya asisten AI EduQuiz.\nTanyakan apa saja tentang pelajaran!", textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.grey[400] : const Color(0xFF94A3B8), fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: _scrollCtrl,
                                      padding: const EdgeInsets.all(12),
                                      itemCount: _messages.length,
                                      itemBuilder: (context, index) {
                                        final msg = _messages[index];
                                        final isUser = msg["role"] == "user";
                                        return Align(
                                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            constraints: const BoxConstraints(maxWidth: 260),
                                            decoration: BoxDecoration(
                                              color: isUser ? const Color(0xFF0056A8) : (isDark ? Colors.grey[800] : const Color(0xFFF1F5F9)),
                                              borderRadius: BorderRadius.circular(12).copyWith(
                                                bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                                                bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                                              ),
                                            ),
                                            child: SelectableText(msg["content"]!, style: TextStyle(color: isUser ? Colors.white : textColor, fontSize: 14)),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            if (_isLoading)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                    const SizedBox(width: 8),
                                    Text("Sedang mengetik...", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : const Color(0xFF94A3B8))),
                                  ],
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(border: Border(top: BorderSide(color: borderColor))),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _msgCtrl,
                                      style: TextStyle(color: textColor, fontSize: 14),
                                      decoration: InputDecoration(
                                        hintText: "Tanya sesuatu...",
                                        hintStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: borderColor)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: borderColor)),
                                      ),
                                      onSubmitted: (_) => _sendMessage(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: _sendMessage,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(color: Color(0xFF0056A8), shape: BoxShape.circle),
                                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: _dy,
                    right: _dx,
                    child: _isOpen
                        ? const SizedBox.shrink()
                        : GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _dx -= details.delta.dx;
                                _dy -= details.delta.dy;
                                if (_dx < 0) _dx = 0;
                                if (_dy < 0) _dy = 0;
                                final size = MediaQuery.of(context).size;
                                if (_dx > size.width - 56) _dx = size.width - 56;
                                if (_dy > size.height - 56) _dy = size.height - 56;
                              });
                            },
                            child: FloatingActionButton(
                              heroTag: 'chatbot_fab',
                              backgroundColor: const Color(0xFF0056A8),
                              onPressed: () => setState(() => _isOpen = true),
                              child: const Icon(Icons.chat, color: Colors.white),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
