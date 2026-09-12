import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ChatScreen({super.key, this.onBack});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatMessage> _messages = [];
  final ImagePicker _picker = ImagePicker();
  int _currentStep = 0;
  String? _selectedInitialOption;
  String? _selectedCategoryOption;

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      isBot: true,
      text: 'สวัสดีค่ะ 👋\nต้องการแจ้งปัญหาอะไรคะ',
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _selectOption(String option) {
    setState(() {
      if (_currentStep == 0) {
        _selectedInitialOption = option;
        _messages.add(_ChatMessage(isBot: false, text: option));
        _messages.add(_ChatMessage(
          isBot: true,
          text: 'กรุณาเลือกประเภทของปัญหา',
        ));
        _currentStep = 1;
      } else if (_currentStep == 1) {
        _selectedCategoryOption = option;
        _messages.add(_ChatMessage(isBot: false, text: option));
        _messages.add(_ChatMessage(
          isBot: true,
          text: 'กรุณาอธิบายปัญหาที่พบ',
        ));
        _currentStep = 2;
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(isBot: false, text: text));
      _messageController.clear();
      if (_currentStep == 2) {
        _messages.add(_ChatMessage(
          isBot: true,
          text: 'รับทราบค่ะ\nกรุณาแนบรูปภาพ (ถ้ามี) เพื่อให้แอดมิน\nตรวจสอบได้เร็วขึ้นค่ะ',
        ));
        _currentStep = 3;
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _messages.add(_ChatMessage(isBot: false, imagePath: image.path));
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _messages.add(_ChatMessage(isBot: false, imagePath: image.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _messages.length + (_currentStep < 2 ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index]);
                }
                if (_currentStep == 0) return _buildInitialOptions();
                if (_currentStep == 1) return _buildCategoryOptions();
                return const SizedBox.shrink();
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: const Icon(Icons.chevron_left, size: 24),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.apartment, size: 20, color: Color(0xFF78A2D2)),
          ),
          const SizedBox(width: 10),
          const Text(
            'StayEase',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    if (message.imagePath != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: Alignment.centerRight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(message.imagePath!),
              width: 180,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    if (message.isBot) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.apartment, size: 16, color: Color(0xFF78A2D2)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.text ?? '',
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 13,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF78A2D2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text ?? '',
              style: const TextStyle(
                fontFamily: 'Prompt',
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildInitialOptions() {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 8),
      child: FractionallySizedBox(
        widthFactor: 0.65,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOptionButton(
                icon: Icons.build_outlined,
                label: 'แจ้งซ่อม',
                isHighlighted: _selectedInitialOption == 'แจ้งซ่อม',
                onTap: () => _selectOption('แจ้งซ่อม'),
              ),
              const SizedBox(height: 6),
              _buildOptionButton(
                icon: Icons.search,
                label: 'ติดตามงานช่อม',
                isHighlighted: _selectedInitialOption == 'ติดตามงานซ่อม',
                onTap: () => _selectOption('ติดตามงานซ่อม'),
              ),
              const SizedBox(height: 6),
              _buildOptionButton(
                icon: Icons.chat_outlined,
                label: 'สอบถามข้อมูล',
                isHighlighted: _selectedInitialOption == 'สอบถามข้อมูล',
                onTap: () => _selectOption('สอบถามข้อมูล'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryOptions() {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 8),
      child: FractionallySizedBox(
        widthFactor: 0.65,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOptionButton(
                icon: Icons.ac_unit,
                label: 'เครื่องปรับอากาศ',
                isHighlighted: _selectedCategoryOption == 'เครื่องปรับอากาศ',
                onTap: () => _selectOption('เครื่องปรับอากาศ'),
              ),
              const SizedBox(height: 6),
              _buildOptionButton(
                icon: Icons.bolt_outlined,
                label: 'ระบบไฟฟ้า',
                isHighlighted: _selectedCategoryOption == 'ระบบไฟฟ้า',
                onTap: () => _selectOption('ระบบไฟฟ้า'),
              ),
              const SizedBox(height: 6),
              _buildOptionButton(
                icon: Icons.water_drop_outlined,
                label: 'ระบบประปา',
                isHighlighted: _selectedCategoryOption == 'ระบบประปา',
                onTap: () => _selectOption('ระบบประปา'),
              ),
              const SizedBox(height: 6),
              _buildOptionButton(
                icon: Icons.chair_outlined,
                label: 'เฟอร์นิเจอร์/อุปกรณ์',
                isHighlighted: _selectedCategoryOption == 'เฟอร์นิเจอร์/อุปกรณ์',
                onTap: () => _selectOption('เฟอร์นิเจอร์/อุปกรณ์'),
              ),
              const SizedBox(height: 6),
              _buildOptionButton(
                icon: Icons.wifi,
                label: 'อื่นๆ',
                isHighlighted: _selectedCategoryOption == 'อื่นๆ',
                onTap: () => _selectOption('อื่นๆ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required bool isHighlighted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFFFEFFAF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF444444)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 13,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: const Icon(Icons.image_outlined, size: 24, color: Color(0xFF78A2D2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(fontFamily: 'Prompt', fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'พิมพ์ข้อความ',
                  hintStyle: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 13,
                    color: Color(0xFFAAAAAA),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: const Icon(Icons.send, size: 22, color: Color(0xFF78A2D2)),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _takePhoto,
            child: const Icon(Icons.camera_alt_outlined, size: 24, color: Color(0xFF78A2D2)),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isBot;
  final String? text;
  final String? imagePath;

  _ChatMessage({required this.isBot, this.text, this.imagePath});
}
