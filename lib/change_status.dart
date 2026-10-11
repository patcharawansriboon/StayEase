import 'package:flutter/material.dart';

class ChangeStatusScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final String currentStatus;
  final void Function(String newStatus)? onConfirm;

  const ChangeStatusScreen({
    super.key,
    this.onBack,
    this.currentStatus = 'กำลังเช่า',
    this.onConfirm,
  });

  @override
  State<ChangeStatusScreen> createState() => _ChangeStatusScreenState();
}

class _ChangeStatusScreenState extends State<ChangeStatusScreen> {
  late String _selectedStatus;

  final List<Map<String, String>> _statusOptions = [
    {'label': 'กำลังเช่า', 'desc': 'ผู้เช่าอาศัยอยู่ในห้องปกติ'},
    {'label': 'รอเข้าพัก', 'desc': 'มีการจอง/รอเข้าพัก'},
    {'label': 'ย้ายห้อง', 'desc': 'พักการใช้งานชั่วคราว'},
    {'label': 'ระงับการใช้งาน', 'desc': 'พักการใช้งานชั่วคราว'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          _buildProfileRow(),
          const SizedBox(height: 20),
          _buildCurrentStatusSection(),
          const SizedBox(height: 20),
          _buildNewStatusSection(),
          const Spacer(),
          _buildConfirmButton(),
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
            child: const Icon(
              Icons.chevron_left,
              size: 24,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'เปลี่ยนสถานะ',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildProfileRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: const AssetImage('assets/images/user_avatar.png'),
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'พัชราวรรณ  ศรีบุญ',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'ห้อง A303',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 13,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สถานะปัจจุบัน',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 14,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.currentStatus,
              style: const TextStyle(
                fontFamily: 'Prompt',
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewStatusSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สถานะใหม่',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 14,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 10),
          ..._statusOptions.map((option) =>
              _buildStatusOption(option['label']!, option['desc']!)),
        ],
      ),
    );
  }

  Widget _buildStatusOption(String label, String desc) {
    final isSelected = _selectedStatus == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = label),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FAF1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4CAF50)
                : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFCCCCCC),
              size: 22,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF000000),
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
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
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => widget.onConfirm?.call(_selectedStatus),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B93D4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: const Text(
            'ยืนยัน',
            style: TextStyle(
              fontFamily: 'Prompt',
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
