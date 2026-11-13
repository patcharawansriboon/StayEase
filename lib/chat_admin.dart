import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'services/chat_service.dart';

import 'widgets/app_sizes.dart';
class ChatAdminScreen extends StatefulWidget {
  final VoidCallback? onBack;

  /// งานซ่อมที่กำลังคุย (ต้องมี repairId เพื่อโหลดห้องแชทจริง)
  final String? repairId;
  final String tenantName;
  final String roomNumber;
  final String jobId;
  final String status; // 'new' | 'in_progress' | 'done'

  const ChatAdminScreen({
    super.key,
    this.onBack,
    this.repairId,
    this.tenantName = 'ผู้เช่า',
    this.roomNumber = '-',
    this.jobId = '',
    this.status = 'new',
  });

  @override
  State<ChatAdminScreen> createState() => _ChatAdminScreenState();
}

class _ChatAdminScreenState extends State<ChatAdminScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _chat = ChatService();

  String? _chatRoomId;
  bool _loading = true;
  late String _status = widget.status;

  // รูปโปรไฟล์ของผู้เช่า (เจ้าของงานซ่อม) ที่แสดงใน header
  String _headerAvatarUrl = '';

  // cache รูปโปรไฟล์ผู้ส่ง (key = sender_id)
  final Map<String, String> _avatarCache = {};

  /// ดึง avatar_url ของผู้ส่งจาก tenants/roommate_invites/admins
  Future<void> _loadAvatarFor(String senderId) async {
    if (senderId.isEmpty || _avatarCache.containsKey(senderId)) return;
    _avatarCache[senderId] = ''; // mark กันเรียกซ้ำ
    final db = Supabase.instance.client;
    for (final table in ['tenants', 'roommate_invites', 'admins']) {
      try {
        final row = await db
            .from(table)
            .select('avatar_url')
            .eq('id', senderId)
            .maybeSingle();
        final url = row?['avatar_url']?.toString();
        if (url != null && url.isNotEmpty) {
          if (mounted) setState(() => _avatarCache[senderId] = url);
          return;
        }
      } catch (e) {
        // ignore: avoid_print
        print('⚠️ _loadAvatarFor $table error: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.repairId == null) {
      setState(() => _loading = false);
      return;
    }
    await _resolveRoom();
  }

  Future<void> _resolveRoom() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final roomId = await _chat.resolveChatRoomId(widget.repairId!);
    if (!mounted) return;
    setState(() {
      _chatRoomId = roomId;
      _loading = false;
    });
    if (roomId != null) _loadHeaderAvatar();
  }

  /// โหลดรูปโปรไฟล์ของผู้เช่าเจ้าของงานซ่อม → แสดงใน header
  Future<void> _loadHeaderAvatar() async {
    try {
      final db = Supabase.instance.client;
      // หา user_id เจ้าของงานซ่อม
      final repair = await db
          .from('repairs')
          .select('user_id')
          .eq('id', widget.repairId!)
          .maybeSingle();
      final ownerId = repair?['user_id']?.toString();
      if (ownerId == null || ownerId.isEmpty) return;

      for (final table in ['tenants', 'roommate_invites', 'admins']) {
        final row = await db
            .from(table)
            .select('avatar_url')
            .eq('id', ownerId)
            .maybeSingle();
        final url = row?['avatar_url']?.toString();
        if (url != null && url.isNotEmpty) {
          if (mounted) setState(() => _headerAvatarUrl = url);
          return;
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ _loadHeaderAvatar error: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatRoomId == null) return;
    _messageController.clear();
    await _chat.sendMessage(
      chatRoomId: _chatRoomId!,
      senderRole: 'admin',
      text: text,
    );
  }

  Future<void> _changeStatus(BuildContext buttonContext) async {
    if (_chatRoomId == null) return;

    // โหลดงานซ่อมทั้งหมดในห้องนี้ → เลือกเฉพาะที่ยังไม่เสร็จ (active)
    final allRepairs = await _chat.getRepairsForChatRoom(_chatRoomId!);
    final activeRepairs = allRepairs
        .where((r) => (r['status']?.toString() ?? 'new') != 'done')
        .toList();

    if (!mounted) return;
    if (activeRepairs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีงานซ่อมที่ต้องอัปเดต',
              style: TextStyle(fontFamily: 'Noto Sans Thai')),
        ),
      );
      return;
    }

    // ── ขั้นที่ 1: ถ้ามีงาน active หลายงาน → ให้เลือกงานก่อน ──
    Map<String, dynamic> targetRepair;
    if (activeRepairs.length == 1) {
      targetRepair = activeRepairs.first;
    } else {
      final picked = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'เลือกงานที่ต้องการอัปเดตสถานะ',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final r in activeRepairs)
                ListTile(
                  leading: Icon(Icons.circle,
                      size: 12,
                      color: _statusColor(r['status']?.toString() ?? 'new')),
                  title: Text(
                    r['category']?.toString() ?? '-',
                    style: const TextStyle(fontFamily: 'Noto Sans Thai'),
                  ),
                  subtitle: Text(
                    ChatService.statusLabel(r['status']?.toString() ?? 'new'),
                    style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 12,
                        color: Color(0xFF999999)),
                  ),
                  onTap: () => Navigator.pop(ctx, r),
                ),
            ],
          ),
        ),
      );
      if (picked == null || !mounted) return;
      targetRepair = picked;
    }

    final targetId = targetRepair['id']?.toString() ?? '';
    final targetCategory = targetRepair['category']?.toString() ?? '';
    final targetStatus = targetRepair['status']?.toString() ?? 'new';
    if (targetId.isEmpty) return;

    // ── ขั้นที่ 2: เลือกสถานะใหม่ ──
    final button = buttonContext.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(buttonContext).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.bottomLeft(Offset.zero),
            ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<String>(
      context: buttonContext,
      position: position,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        // 'new' ไม่ให้เลือก (เป็นสถานะเตือนงานเข้าใหม่อัตโนมัติ)
        for (final s in const ['in_progress', 'done'])
          PopupMenuItem<String>(
            value: s,
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: _statusColor(s)),
                const SizedBox(width: 10),
                Text(
                  ChatService.statusLabel(s),
                  style: const TextStyle(
                      fontFamily: 'Noto Sans Thai', fontSize: 14),
                ),
                if (targetStatus == s) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check, size: 16, color: Color(0xFF4F8FDB)),
                ],
              ],
            ),
          ),
      ],
    );

    if (selected == null || selected == targetStatus || !mounted) return;
    setState(() => _status = selected);
    final ok = await _chat.updateRepairStatus(
      repairId: targetId,
      chatRoomId: _chatRoomId!,
      status: selected,
      category: targetCategory,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'เปลี่ยนสถานะไม่สำเร็จ (ตรวจสอบ RLS ตาราง repairs)',
            style: TextStyle(fontFamily: 'Noto Sans Thai'),
          ),
          backgroundColor: Color(0xFFFF0303),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return const Color(0xFF4CAF50); // เขียว
      case 'in_progress':
        return const Color(0xFFE6A700); // เหลือง
      case 'new':
      default:
        return const Color(0xFFE05C5C); // แดง
    }
  }

  /// สีพื้นหลัง (อ่อน) ของกรอบสถานะ
  Color _statusBg(String status) {
    switch (status) {
      case 'done':
        return const Color(0xFFE9F7EC); // เขียวอ่อน
      case 'in_progress':
        return const Color(0xFFFFF8E5); // เหลืองอ่อน
      case 'new':
      default:
        return const Color(0xFFFCE9E9); // แดงอ่อน
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessages()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F8FDB)),
      );
    }
    if (_chatRoomId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 40, color: Color(0xFFBDBDBD)),
              const SizedBox(height: 12),
              const Text(
                'ไม่พบห้องแชทงานซ่อมนี้',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 14,
                  color: Color(0xFF70766E),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.repairId == null ? null : _resolveRoom,
                child: const Text(
                  'ลองใหม่',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    color: Color(0xFF4F8FDB),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chat.messagesStream(_chatRoomId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4F8FDB)),
          );
        }
        // dedupe ด้วย id — กันข้อความซ้ำชั่วคราวจาก stream ตอน insert ใหม่
        final seen = <String>{};
        final messages = <Map<String, dynamic>>[];
        for (final m in snapshot.data!) {
          final id = m['id']?.toString() ?? '';
          if (id.isEmpty || seen.add(id)) messages.add(m);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: messages.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (_, i) => _buildBubble(messages[i]),
        );
      },
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final role = msg['sender_role']?.toString() ?? 'tenant';
    final meta = msg['meta'] as Map<String, dynamic>?;
    final time = _formatTime(msg['created_at']?.toString());

    if (role == 'bot' && meta?['type'] == 'repair_summary') {
      return _buildBotSummaryMessage(meta!, time);
    }
    if (role == 'bot') {
      return _buildBotTextMessage(text: msg['text']?.toString() ?? '', time: time);
    }
    if (role == 'admin') {
      // ข้อความแอดมิน (ฝั่งขวา)
      return _buildAdminMessage(
        text: msg['text']?.toString() ?? '',
        imageUrl: msg['image_url']?.toString(),
        time: time,
      );
    }
    // ผู้เช่า/Roommate (ฝั่งซ้าย)
    final senderId = msg['sender_id']?.toString() ?? '';
    _loadAvatarFor(senderId);
    return _buildTenantMessage(
      text: msg['text']?.toString() ?? '',
      imageUrl: msg['image_url']?.toString(),
      time: time,
      roleLabel: role == 'roommate' ? 'Roommate' : 'ผู้เช่า',
      avatarUrl: _avatarCache[senderId] ?? '',
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildHeader() {
    final roomJob = widget.roomNumber.isNotEmpty ? 'ห้อง ${widget.roomNumber}' : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: const Icon(Icons.chevron_left,
                size: kBackIconSize, color: Color(0xFF000000)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: ClipOval(
              child: _headerAvatarUrl.isNotEmpty
                  ? _buildImage(_headerAvatarUrl, 40, 40)
                  : Image.asset('assets/images/user_avatar.png',
                      fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.tenantName,
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roomJob,
                  style: const TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          Builder(
            builder: (btnContext) => GestureDetector(
              onTap: () => _changeStatus(btnContext),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusBg(_status),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor(_status)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ChatService.statusLabel(_status),
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 11,
                        color: _statusColor(_status),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down,
                        size: 16, color: _statusColor(_status)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotSummaryMessage(Map<String, dynamic> meta, String time) {
    final imageUrl = meta['image_url']?.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 46),
          child: Text(
            'StayEase Bot',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBotAvatar(),
            const SizedBox(width: 10),
            Flexible(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(child: _summaryCardBody(meta, imageUrl)),
                  const SizedBox(width: 6),
                  Text(
                    time,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 11,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImage(String src, double w, double h) {
    if (src.startsWith('http') || src.startsWith('blob:')) {
      return Image.network(src,
          width: w,
          height: h,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imgFallback(w, h));
    }
    if (kIsWeb) return _imgFallback(w, h);
    final file = File(src);
    if (file.existsSync()) {
      return Image.file(file, width: w, height: h, fit: BoxFit.cover);
    }
    return _imgFallback(w, h);
  }

  Widget _imgFallback(double w, double h) => Container(
        width: w,
        height: h,
        color: const Color(0xFFF0F0F0),
        child: const Icon(Icons.image_outlined, size: 40, color: Color(0xFFAAAAAA)),
      );

  /// เนื้อการ์ดสรุป — ดีไซน์ใหม่: header แถบสี + rows ที่มีไอคอนนำ
  Widget _summaryCardBody(Map<String, dynamic> meta, String? imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EEF7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFFEAF2FB),
            child: Row(
              children: const [
                Icon(Icons.assignment_outlined,
                    size: 18, color: Color(0xFF4181CB)),
                SizedBox(width: 8),
                Text(
                  'สรุปข้อมูลการแจ้งซ่อม',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4181CB),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRowNew(Icons.meeting_room_outlined, 'ห้องพัก',
                    meta['room']?.toString() ?? '-'),
                const SizedBox(height: 8),
                _summaryRowNew(Icons.build_outlined, 'ประเภท',
                    meta['category']?.toString() ?? '-'),
                const SizedBox(height: 8),
                _summaryRowNew(Icons.notes_outlined, 'รายละเอียด',
                    meta['description']?.toString() ?? '-'),
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildImage(imageUrl, double.infinity, 120),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRowNew(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8FB4E0)),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 13,
              color: Color(0xFF999999),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminMessage({
    required String text,
    String? imageUrl,
    required String time,
  }) {
    final bubble = (imageUrl != null && imageUrl.isNotEmpty)
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(imageUrl, 180, 140),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD6E8F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(text,
                style: const TextStyle(
                    fontFamily: 'Noto Sans Thai', fontSize: 13, color: Color(0xFF000000))),
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (time.isNotEmpty) ...[
          Text(time,
              style: const TextStyle(
                  fontFamily: 'Noto Sans Thai', fontSize: 11, color: Color(0xFF999999))),
          const SizedBox(width: 6),
        ],
        Flexible(child: bubble),
      ],
    );
  }

  Widget _buildTenantMessage({
    required String text,
    String? imageUrl,
    required String time,
    required String roleLabel,
    String avatarUrl = '',
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
          ),
          child: ClipOval(
            child: avatarUrl.isNotEmpty
                ? _buildImage(avatarUrl, 36, 36)
                : Image.asset('assets/images/user_avatar.png',
                    fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImage(imageUrl, 180, 140),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(text,
                            style: const TextStyle(
                                fontFamily: 'Noto Sans Thai',
                                fontSize: 13,
                                color: Color(0xFF000000))),
                      ),
              ),
              if (time.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(time,
                    style: const TextStyle(
                        fontFamily: 'Noto Sans Thai', fontSize: 11, color: Color(0xFF999999))),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotTextMessage({required String text, required String time}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 46),
          child: Text(
            'StayEase Bot',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBotAvatar(),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(text,
                    style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 13,
                        color: Color(0xFF000000))),
              ),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(time,
                  style: const TextStyle(
                      fontFamily: 'Noto Sans Thai', fontSize: 11, color: Color(0xFF999999))),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFFEEF4FB),
        shape: BoxShape.circle,
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
          const Icon(Icons.image_outlined, size: 26, color: Color(0xFF999999)),
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
                onSubmitted: (_) => _send(),
                style: const TextStyle(
                    fontFamily: 'Noto Sans Thai', fontSize: 13, color: Color(0xFF000000)),
                decoration: const InputDecoration(
                  hintText: 'พิมพ์ข้อความ',
                  hintStyle: TextStyle(
                    fontFamily: 'Noto Sans Thai',
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
            onTap: _send,
            child: const Icon(Icons.send, size: 24, color: Color(0xFF4F8FDB)),
          ),
        ],
      ),
    );
  }
}
