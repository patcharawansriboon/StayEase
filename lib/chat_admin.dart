import 'package:flutter/material.dart';

class ChatAdminScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ChatAdminScreen({super.key, this.onBack});

  @override
  State<ChatAdminScreen> createState() => _ChatAdminScreenState();
}

class _ChatAdminScreenState extends State<ChatAdminScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _buildBotSummaryMessage(),
                const SizedBox(height: 16),
                _buildAdminMessage(
                  text: 'รับเรื่องแล้วครับ\nจะเข้าตรวจสอบให้ครับ',
                  time: '09:15',
                ),
                const SizedBox(height: 16),
                _buildTenantMessage(
                  text: 'ขอบคุณค่ะ',
                  time: '09:16',
                ),
                const SizedBox(height: 16),
                _buildBotTextMessage(
                  text: 'สถานะการซ่อมเปลี่ยนเป็น "กำลังดำเนินการ"\nจะมีการแจ้งอัปเดตให้ทราบครับ',
                  time: '09:20',
                ),
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: const Icon(Icons.chevron_left,
                size: 28, color: Color(0xFF000000)),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundImage:
                const AssetImage('assets/images/user_avatar.png'),
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'พัชราวรรณ  ศรีบุญ',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'ห้อง A303',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                    Text(
                      '  •  ',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                    Text(
                      '#JK-2569-0002',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'กำลังดำเนินการ',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 11,
                    color: Color(0xFFE6A700),
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down,
                    size: 16, color: Color(0xFFE6A700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotSummaryMessage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'StayEase Bot',
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 4),
            _buildBotAvatar(),
          ],
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'สรุปข้อมูลการแจ้งซ่อม',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4181CB),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('ห้องพัก', 'A303'),
                    _buildInfoRow('ประเภท', 'เครื่องปรับอากาศ'),
                    _buildInfoRow('รายละเอียด', 'แอร์เปิดแต่ไม่เย็น เสียงดัง'),
                    const SizedBox(height: 4),
                    const Text(
                      'รูปภาพ :',
                      style: TextStyle(
                        fontFamily: 'Prompt',
                        fontSize: 13,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/air_conditioner.png',
                        width: 160,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 160,
                          height: 100,
                          color: const Color(0xFFF0F0F0),
                          child: const Icon(Icons.image_outlined,
                              size: 40, color: Color(0xFFAAAAAA)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '09:12',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 11,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontFamily: 'Prompt',
            fontSize: 13,
            color: Color(0xFF333333),
          ),
          children: [
            TextSpan(text: '$label : '),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMessage({
    required String text,
    required String time,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFD6E8F7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Prompt',
              fontSize: 13,
              color: Color(0xFF000000),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontFamily: 'Prompt',
            fontSize: 11,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  Widget _buildTenantMessage({
    required String text,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  const AssetImage('assets/images/user_avatar.png'),
              backgroundColor: Colors.grey.shade200,
            ),
          ],
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ผู้เช่า',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 13,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 11,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotTextMessage({
    required String text,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'StayEase Bot',
              style: TextStyle(
                fontFamily: 'Prompt',
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 4),
            _buildBotAvatar(),
          ],
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 13,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 11,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.smart_toy_outlined,
          size: 20, color: Color(0xFF4F8FDB)),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_outlined,
              size: 26, color: Color(0xFF999999)),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 13,
                    color: Color(0xFF000000)),
                decoration: const InputDecoration(
                  hintText: 'พิมพ์ข้อความ',
                  hintStyle: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 13,
                    color: Color(0xFFAAAAAA),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.send,
                size: 24, color: Color(0xFF4F8FDB)),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF4F8FDB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.camera_alt_outlined,
                size: 22, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
