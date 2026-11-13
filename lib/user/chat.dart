import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/chat_service.dart';

import '../widgets/app_sizes.dart';
class ChatScreen extends StatefulWidget {
  final VoidCallback? onBack;

  /// ถ้าส่ง repairId มา = เปิดห้องแชทงานซ่อมเดิม (คุยต่อ)
  /// ถ้าไม่ส่ง + isRepairFlow=true = เริ่ม flow แจ้งซ่อมใหม่ด้วยบอท
  /// ถ้าไม่ส่ง + isRepairFlow=false = เปิดแชทห้องพัก (คุยทั่วไป)
  final String? repairId;

  /// true = โหมดแจ้งซ่อมด้วยบอท, false = แชทห้องพักทั่วไป
  final bool isRepairFlow;

  /// บทบาทผู้ส่งในห้องนี้: 'tenant' (ผู้เช่าหลัก) หรือ 'roommate'
  final String senderRole;

  const ChatScreen({
    super.key,
    this.onBack,
    this.repairId,
    this.isRepairFlow = false,
    this.senderRole = 'tenant',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final _chat = ChatService();
  final ScrollController _scrollController = ScrollController();

  // ── โหมดบอท (แจ้งซ่อมใหม่) ──
  final List<_ChatMessage> _botMessages = [];
  int _currentStep = 0;
  String? _selectedCategoryOption;
  String _description = '';

  // ── โหมดห้องแชทจริง ──
  String? _chatRoomId;
  bool _liveMode = false;
  bool _loading = false;        // loading ตอนเข้า live mode ครั้งแรก
  bool _uploadingImage = false; // loading ตอน upload รูปใน live mode
  bool _isSubmitting = false;   // guard กัน double-submit ใน bot mode
  Stream<List<Map<String, dynamic>>>? _messagesStream; // cache stream ไม่สร้างใหม่ทุก setState

  // cache รูปโปรไฟล์ของผู้ส่ง (key = sender_id)
  final Map<String, String> _avatarCache = {};

  /// ดึง avatar_url ของผู้ส่งจากตาราง admins/tenants/roommate_invites
  Future<void> _loadAvatarFor(String senderId) async {
    if (senderId.isEmpty || _avatarCache.containsKey(senderId)) return;
    // mark ทันทีเพื่อป้องกันเรียกซ้ำระหว่าง query (build ถูกเรียกหลายครั้ง)
    _avatarCache[senderId] = '';

    final db = Supabase.instance.client;
    for (final table in ['admins', 'tenants', 'roommate_invites']) {
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
    if (widget.repairId != null) {
      // เปิดห้องแชทงานเดิม → เข้าโหมด live ทันที
      _enterLiveMode(repairId: widget.repairId!);
    } else if (widget.isRepairFlow) {
      // เริ่ม flow บอท → แสดงตัวเลือกประเภทของปัญหาทันที (ไม่ถามก่อนว่าจะแจ้งอะไร)
      _botMessages.add(_ChatMessage(
        isBot: true,
        text: 'สวัสดีครับ 👋\nกรุณาเลือกประเภทของปัญหา',
      ));
      _currentStep = 1;
    } else {
      // เปิดแชทห้องพัก (คุยทั่วไป) → เข้าโหมด live ทันที
      _enterRoomChat();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _enterRoomChat() async {
    setState(() => _loading = true);
    final roomId = await _chat.getOrCreateRoomChatForCurrentUser();
    if (!mounted) return;
    setState(() {
      _chatRoomId = roomId;
      _liveMode = true;
      _loading = false;
      _messagesStream =
          roomId != null ? _chat.messagesStream(roomId) : null;
    });
  }

  Future<void> _enterLiveMode({required String repairId}) async {
    setState(() => _loading = true);
    final roomId = await _chat.resolveChatRoomId(repairId);
    if (!mounted) return;
    setState(() {
      _chatRoomId = roomId;
      _liveMode = true;
      _loading = false;
      _messagesStream =
          roomId != null ? _chat.messagesStream(roomId) : null;
    });
  }

  // ── บอท: เลือกตัวเลือก ──
  void _selectOption(String option) {
    setState(() {
      if (_currentStep == 1) {
        _selectedCategoryOption = option;
        _botMessages.add(_ChatMessage(isBot: false, text: option));
        _botMessages.add(_ChatMessage(
          isBot: true,
          text: 'กรุณาอธิบายปัญหาที่พบ',
        ));
        _currentStep = 2;
      }
    });
  }

  // ── ส่งข้อความ (ทั้งโหมดบอทและ live) ──
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_liveMode && _chatRoomId != null) {
      _messageController.clear();
      await _chat.sendMessage(
        chatRoomId: _chatRoomId!,
        senderRole: widget.senderRole,
        text: text,
      );
      return;
    }

    // โหมดบอท
    setState(() {
      _botMessages.add(_ChatMessage(isBot: false, text: text));
      _messageController.clear();
      if (_currentStep == 2) {
        _description = text;
        _botMessages.add(_ChatMessage(
          isBot: true,
          text: 'รับทราบค่ะ\nกรุณาแนบรูปภาพ (ถ้ามี) เพื่อให้แอดมิน\nตรวจสอบได้เร็วขึ้นค่ะ',
        ));
        _currentStep = 3;
      }
    });
  }

  // ── จบ flow บอท → สร้างงานซ่อม + ห้องแชท + บอทสรุป ──
  Future<void> _submitRepair({String? imagePath}) async {
    if (_isSubmitting) return; // ป้องกัน double submit
    _isSubmitting = true;
    setState(() => _loading = true);
    final result = await _chat.createRepairWithChat(
      category: _selectedCategoryOption ?? 'อื่นๆ',
      description: _description,
      // เฟส 1: ยังไม่อัปโหลดรูปขึ้น storage → ส่ง path ไว้ก่อน (เฟส 3 ค่อยทำจริง)
      imageUrl: imagePath,
      senderRole: widget.senderRole,
    );
    if (!mounted) return;
    if (result != null && result.containsKey('repairId')) {
      setState(() {
        _chatRoomId = result['chatRoomId'];
        _liveMode = true;
        _loading = false;
        _isSubmitting = false;
        _messagesStream = _chat.messagesStream(result['chatRoomId']!);
      });
    } else {
      setState(() { _loading = false; _isSubmitting = false; });
      final errMsg = result?['error'] ?? 'ไม่ทราบสาเหตุ';
      // ignore: avoid_print
      print('❌ _submitRepair failed: $errMsg');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ส่งคำขอไม่สำเร็จ: $errMsg',
            style: const TextStyle(fontFamily: 'Noto Sans Thai'),
          ),
          backgroundColor: const Color(0xFFFF0303),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (_currentStep == 3 && !_liveMode) {
      // upload รูปก่อน แล้วค่อยส่งคำขอ
      // _loading อยู่ true ตลอด (ทั้งช่วง upload + submit) เพื่อป้องกัน double submit
      setState(() => _loading = true);
      String? uploadedUrl;
      try {
        final bytes = await image.readAsBytes();
        final ext = image.path.split('.').last.toLowerCase();
        final uid =
            Supabase.instance.client.auth.currentUser?.id ?? 'unknown';
        final path =
            'repair-images/${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await Supabase.instance.client.storage
            .from('dormitory-images')
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
        uploadedUrl = Supabase.instance.client.storage
            .from('dormitory-images')
            .getPublicUrl(path);
      } catch (e) {
        // ignore: avoid_print
        print('❌ repair image upload error: $e');
        // upload ล้มเหลว → reset loading แล้วหยุด ไม่ส่งคำขอ
        if (mounted) setState(() => _loading = false);
        return;
      }
      // _loading ยัง true อยู่ → _submitRepair จะจัดการ reset เอง
      await _submitRepair(imagePath: uploadedUrl);
    } else if (_liveMode && _chatRoomId != null) {
      // Live mode → upload รูปขึ้น Storage แล้วส่งเป็น message
      setState(() => _uploadingImage = true);
      try {
        final bytes = await image.readAsBytes();
        final ext = image.path.split('.').last.toLowerCase();
        final uid =
            Supabase.instance.client.auth.currentUser?.id ?? 'unknown';
        final path =
            'chat-images/${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        await Supabase.instance.client.storage
            .from('dormitory-images')
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );

        final url = Supabase.instance.client.storage
            .from('dormitory-images')
            .getPublicUrl(path);

        final ok = await _chat.sendMessage(
          chatRoomId: _chatRoomId!,
          senderRole: widget.senderRole,
          imageUrl: url,
        );
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึก message ไม่สำเร็จ (ตรวจสอบ RLS ตาราง chat_messages)',
                  style: TextStyle(fontFamily: 'Noto Sans Thai')),
              backgroundColor: Color(0xFFFF0303),
              duration: Duration(seconds: 6),
            ),
          );
        }
      } catch (e) {
        // ignore: avoid_print
        print('❌ _pickImage live mode error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ส่งรูปไม่สำเร็จ: $e',
                style: const TextStyle(fontFamily: 'Noto Sans Thai'),
              ),
              backgroundColor: const Color(0xFFFF0303),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _uploadingImage = false);
      }
    } else {
      // โหมดบอท (ขั้นอื่นๆ) → แสดงรูปใน chat bubble ตามปกติ
      setState(() {
        _botMessages.add(_ChatMessage(isBot: false, imagePath: image.path));
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    if (_currentStep == 3 && !_liveMode) {
      // upload รูปก่อนส่งคำขอ (เหมือน _pickImage)
      setState(() => _loading = true);
      String? uploadedUrl;
      try {
        final bytes = await image.readAsBytes();
        final ext = image.path.split('.').last.toLowerCase();
        final uid =
            Supabase.instance.client.auth.currentUser?.id ?? 'unknown';
        final path =
            'repair-images/${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await Supabase.instance.client.storage
            .from('dormitory-images')
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
        uploadedUrl = Supabase.instance.client.storage
            .from('dormitory-images')
            .getPublicUrl(path);
      } catch (e) {
        // ignore: avoid_print
        print('❌ repair photo upload error: $e');
        if (mounted) setState(() => _loading = false);
        return;
      }
      await _submitRepair(imagePath: uploadedUrl);
    } else {
      setState(() {
        _botMessages.add(_ChatMessage(isBot: false, imagePath: image.path));
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
          if (_currentStep == 3 && !_liveMode) _buildSkipImageBar(),
          Expanded(
            child: Builder(
              builder: (context) {
                try {
                  return _liveMode ? _buildLiveList() : _buildBotList();
                } catch (e, stack) {
                  // ignore: avoid_print
                  print('❌ chat build error: $e\n$stack');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'เกิดข้อผิดพลาด: $e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 13,
                          color: Color(0xFF856404),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── ปุ่มข้ามการแนบรูป (ส่งคำขอโดยไม่มีรูป) ──
  Widget _buildSkipImageBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _loading ? null : () => _submitRepair(),
          child: const Text(
            'ข้าม / ส่งคำขอเลย',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 13,
              color: Color(0xFF4F8FDB),
            ),
          ),
        ),
      ),
    );
  }

  // ── รายการข้อความโหมดบอท ──
  Widget _buildBotList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _botMessages.length + (_currentStep < 2 ? 1 : 0),
      itemBuilder: (context, index) {
        try {
          if (index < _botMessages.length) {
            return _buildMessageBubble(_botMessages[index]);
          }
          if (_currentStep == 1) return _buildCategoryOptions();
          return const SizedBox.shrink();
        } catch (e, stack) {
          // ignore: avoid_print
          print('❌ _buildBotList[$index] error: $e\n$stack');
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'แสดงข้อความไม่ได้: $e',
                style: const TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 11,
                  color: Color(0xFF856404),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  // ── รายการข้อความโหมด live (realtime) ──
  Widget _buildLiveList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4F8FDB)),
      );
    }
    if (_chatRoomId == null || _messagesStream == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _messagesStream,
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
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: messages.length,
          itemBuilder: (_, i) {
            try {
              return _buildLiveBubble(messages[i]);
            } catch (e, stack) {
              // ignore: avoid_print
              print('❌ _buildLiveBubble[$i] error: $e\n$stack');
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'แสดงข้อความไม่ได้: $e',
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 11,
                      color: Color(0xFF856404),
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Widget _buildLiveBubble(Map<String, dynamic> msg) {
    final role = msg['sender_role']?.toString() ?? 'tenant';
    // safe cast: Supabase JSONB อาจ return Map<dynamic,dynamic> แทน Map<String,dynamic>
    final rawMeta = msg['meta'];
    final meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : null;
    final isMine = msg['sender_id']?.toString() == _chat.currentUserId;
    final time = _formatTime(msg['created_at']?.toString());

    // การ์ดสรุปของบอท
    if (role == 'bot' && meta?['type'] == 'repair_summary') {
      return _buildSummaryCard(meta!, time);
    }
    // ข้อความบอททั่วไป (เช่น เปลี่ยนสถานะ) — มีเวลาด้วย
    if (role == 'bot') {
      return _buildBotTextMessage(
        text: msg['text']?.toString() ?? '',
        time: time,
      );
    }
    // ข้อความของฉัน → ฝั่งขวา ไม่มี avatar
    if (isMine) {
      return _buildMyMessage(
        text: msg['text']?.toString() ?? '',
        imageUrl: msg['image_url']?.toString(),
        time: time,
      );
    }
    // ข้อความคนอื่น (แอดมิน/Roommate) → ฝั่งซ้าย + รูปโปรไฟล์วงกลม
    final senderId = msg['sender_id']?.toString() ?? '';
    final senderRole = msg['sender_role']?.toString() ?? 'tenant';
    _loadAvatarFor(senderId); // โหลด avatar (cache)
    String senderLabel;
    if (senderRole == 'roommate') {
      senderLabel = 'Roommate';
    } else if (senderRole == 'admin') {
      senderLabel = 'แอดมิน';
    } else {
      senderLabel = 'ผู้เช่า';
    }
    return _buildOtherMessage(
      text: msg['text']?.toString() ?? '',
      imageUrl: msg['image_url']?.toString(),
      avatarUrl: _avatarCache[senderId] ?? '',
      time: time,
      senderLabel: senderLabel,
    );
  }

  /// แปลง ISO timestamp → HH:mm
  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  /// bubble ข้อความของฉัน (ฝั่งขวา) + เวลา
  Widget _buildMyMessage({
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
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 13,
                color: Color(0xFF000000),
              ),
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (time.isNotEmpty) ...[
            Text(
              time,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 11,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }

  /// bubble ข้อความของคนอื่น (แอดมิน/Roommate/ผู้เช่า) พร้อมรูปโปรไฟล์วงกลม + เวลา
  Widget _buildOtherMessage({
    required String text,
    String? imageUrl,
    required String avatarUrl,
    required String time,
    required String senderLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 4),
            child: Text(
              senderLabel,
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? _buildImage(avatarUrl, 32, 32)
                      : Image.asset('assets/images/user_avatar.png',
                          fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 8),
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
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontFamily: 'Noto Sans Thai',
                              fontSize: 13,
                              color: Color(0xFF000000),
                            ),
                          ),
                        ),
                ),
                if (time.isNotEmpty) ...[
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
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// bubble ข้อความบอททั่วไป (เช่น แจ้งเปลี่ยนสถานะ) พร้อม label + เวลา
  Widget _buildBotTextMessage({required String text, required String time}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 46, bottom: 4),
            child: Text(
              'StayEase Bot',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF4FB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.apartment,
                    size: 22, color: Color(0xFF4F8FDB)),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 13,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              ),
              if (time.isNotEmpty) ...[
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> meta, [String time = '']) {
    final imageUrl = meta['image_url']?.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 46, bottom: 4),
            child: Text(
              'StayEase Bot',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF4FB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.smart_toy_outlined,
                          size: 22, color: Color(0xFF4F8FDB)),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(width: 8),
                Flexible(child: _summaryCardBody(meta, imageUrl)),
                if (time.isNotEmpty) ...[
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
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          // ── header แถบสีฟ้า ──
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
          // ── เนื้อหา ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow(Icons.meeting_room_outlined, 'ห้องพัก',
                    meta['room']?.toString() ?? '-'),
                const SizedBox(height: 8),
                _summaryRow(Icons.build_outlined, 'ประเภท',
                    meta['category']?.toString() ?? '-'),
                const SizedBox(height: 8),
                _summaryRow(Icons.notes_outlined, 'รายละเอียด',
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

  Widget _summaryRow(IconData icon, String label, String value) {
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

  /// รูปอาจเป็น path ในเครื่อง (mobile) หรือ blob/http URL (web/live)
  Widget _buildImage(String src, double w, double h) {
    // URL (http/https/blob) → ใช้ Image.network
    if (src.startsWith('http') || src.startsWith('blob:')) {
      return Image.network(
        src,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imgFallback(w, h),
      );
    }
    // Web ไม่รองรับ dart:io File → fallback
    if (kIsWeb) return _imgFallback(w, h);
    // Mobile → ใช้ File
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
        child: const Icon(Icons.image_outlined,
            size: 40, color: Color(0xFFAAAAAA)),
      );

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: const Icon(Icons.chevron_left, size: kBackIconSize),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.apartment,
                size: 20, color: Color(0xFF4F8FDB)),
          ),
          const SizedBox(width: 10),
          const Text(
            'StayEase',
            style: TextStyle(
              fontFamily: 'Noto Sans Thai',
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
    if (message.imagePath != null || message.imageUrl != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment:
              message.alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(
              message.imagePath ?? message.imageUrl ?? '',
              180,
              140,
            ),
          ),
        ),
      );
    }

    if (message.isBot) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 46, bottom: 4),
              child: Text(
                'StayEase Bot',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF4FB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.apartment,
                      size: 22, color: Color(0xFF4F8FDB)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.text ?? '',
                      style: const TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 13,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Align(
          alignment:
              message.alignRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: message.alignRight
                  ? const Color(0xFF4F8FDB)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text ?? '',
              style: TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 13,
                color: message.alignRight ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      );
    }
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
                  fontFamily: 'Noto Sans Thai',
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
    // ในโหมดบอท ก่อนถึงขั้นพิมพ์รายละเอียด (step 2) ไม่ให้พิมพ์
    final canType = _liveMode || _currentStep >= 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: (_uploadingImage || _loading || _isSubmitting) ? null : _pickImage,
            child: (_uploadingImage || _isSubmitting)
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF4F8FDB),
                    ),
                  )
                : const Icon(Icons.image_outlined,
                    size: 24, color: Color(0xFF4F8FDB)),
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
                enabled: canType,
                style: const TextStyle(fontFamily: 'Noto Sans Thai', fontSize: 13),
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'พิมพ์ข้อความ',
                  hintStyle: TextStyle(
                    fontFamily: 'Noto Sans Thai',
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
            child: const Icon(Icons.send, size: 22, color: Color(0xFF4F8FDB)),
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
  final String? imageUrl;
  final bool alignRight;

  _ChatMessage({
    required this.isBot,
    this.text,
    this.imagePath,
    this.imageUrl,
    bool? alignRight,
  }) : alignRight = alignRight ?? !isBot;
}
