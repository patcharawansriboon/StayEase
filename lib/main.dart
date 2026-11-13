import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'services/auth_service.dart';
import 'services/mock_service.dart';
import 'services/room_members_service.dart';
import 'services/tenant_auth_service.dart';
import 'services/chat_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user/onboarding_screen.dart';
import 'user/select_user.dart';
import 'user/sign_up_user.dart';
import 'user/add_profile.dart';
import 'user/send_request.dart';
import 'user/already_approved.dart';
import 'user/home_user.dart';
import 'user/sign_in.dart';
import 'user/rental_fee.dart';
import 'user/bill.dart';
import 'bill_details.dart';
import 'user/payment.dart';
import 'user/rental_fee_history.dart';
import 'user/bill_history.dart';
import 'user/chat.dart';
import 'user/announce.dart';
import 'user/announce_details.dart';
import 'user/report.dart';
import 'profile.dart';
import 'user/change_number.dart';
import 'user/change_number_otp.dart';
import 'user/confirm_change_number.dart';
import 'user/privacy_policy.dart';
import 'user/change_password.dart';
import 'user/confirm_change_password.dart';
import 'user/forgot_password.dart';
import 'user/rental_information.dart';
import 'user/edite_rental_information.dart';
import 'user/terms_of_use.dart';
import 'user/map.dart';
import 'user/contact_us.dart';
import 'user/room_members.dart';
import 'user/invitation_code.dart';
import 'user/leave_the_room.dart';
import 'user/participate.dart';
import 'user/join_the_room.dart';
import 'user/close_account.dart';
import 'user/deletion_failed.dart';
import 'user/application_process.dart';
import 'user/pending_room_transfer.dart';
import 'select_dormitory.dart';
import 'build_new_dormitory.dart';
import 'Dashboard.dart';
import 'tenant_bill.dart';
import 'tenant.dart';
import 'tenant_details.dart';
import 'edite_tenant.dart';
import 'edite_announce.dart';
import 'build_tenant_bill.dart';
import 'notification.dart';
import 'request.dart';
import 'dormitory_request.dart';
import 'dormitory_settings.dart';
import 'report_a_repair.dart';
import 'chat_admin.dart';
import 'user/tenant_google_signup.dart';
import 'user/tenant_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rkzieigonelmksbjpiep.supabase.co',
    anonKey: 'sb_publishable_Wr4gO5pH3y9lJOBZztn2Cw_HjLMOFkX',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;
final authService = AuthService();

/// Generate UUID v4 โดยไม่ต้องใช้ package
String _generateUuid() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}'
      '-${hex(bytes[4])}${hex(bytes[5])}'
      '-${hex(bytes[6])}${hex(bytes[7])}'
      '-${hex(bytes[8])}${hex(bytes[9])}'
      '-${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StayMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F8FDB)),
        useMaterial3: true,
        fontFamily: 'Noto Sans Thai',
        textTheme: GoogleFonts.notoSansThaiTextTheme(),
      ),
      home: const AppScreenManager(),
    );
  }
}

enum AppScreen {
  onboarding,
  selectUser,
  signUp,
  verifyNumber,
  sendRequest,
  alreadyApproved,
  homeUser,
  signIn,
  rentalFee,
  bill,
  billDetails,
  payment,
  paymentHistory,
  billHistory,
  chat,
  announce,
  announceDetails,
  userReportRepair,
  profile,
  changeNumber,
  otp,
  confirmChangeNumber,
  privacyPolicy,
  changePassword,
  confirmChangePassword,
  rentalInformation,
  editeRentalInformation,
  termsOfUse,
  map,
  dara,
  roomMembers,
  invitationCode,
  leaveTheRoom,
  participate,
  joinTheRoom,
  closeAccount,
  applicationProcess,
  pendingRoomTransfer,
  deletionFailed,
  signUpAdmin,
  selectDormitory,
  dormitorySettings,
  buildNewDormitory,
  dashboard,
  tenant,
  masterTenant,
  editeTenant,
  notification,
  dormitoryRequest,
  reportRepair,
  chatAdmin,
  tenantBill,
  request,
  announceAdmin,
  editeAnnounce,
  buildTenantBill,
  tenantSignup,
  tenantDashboard,
  forgotPassword,
}

class AppScreenManager extends StatefulWidget {
  const AppScreenManager({super.key});

  @override
  State<AppScreenManager> createState() => _AppScreenManagerState();
}

class _AppScreenManagerState extends State<AppScreenManager> {
  AppScreen _currentScreen = AppScreen.onboarding;

  // ── กู้หน้าเดิมหลังหน้าเว็บรีโหลด (เช่น หลังเปิดตัวเลือกรูปบนมือถือ) ──
  static const _lastScreenKey = 'last_screen';

  /// หน้าที่กู้คืนได้ฝั่งผู้เช่า (หน้าที่ไม่ต้องใช้ข้อมูลชั่วคราวประกอบ)
  static const _userRestorable = {
    AppScreen.homeUser,
    AppScreen.rentalFee,
    AppScreen.announce,
    AppScreen.userReportRepair,
    AppScreen.profile,
  };

  /// หน้าที่กู้คืนได้ฝั่งแอดมิน
  static const _adminRestorable = {
    AppScreen.dashboard,
    AppScreen.tenant,
    AppScreen.tenantBill,
    AppScreen.announceAdmin,
    AppScreen.reportRepair,
    AppScreen.request,
    AppScreen.profile,
  };

  /// true ระหว่างตรวจ session ตอนเปิดแอป (แสดง loading แทนหน้า onboarding วูบ)
  bool _restoring = true;
  int _onboardingPage = 0;
  String _verifyPhoneNumber = '';
  String _verifyDormCode = '';
  String _verifyRoomNumber = '';
  String _verifyInviteCode = '';
  String _userPhoneNumber = '099-9999999';
  String _userName = '';
  String _avatarUrl = '';
  int _changeNumberFlowKey = 0; // increment เพื่อ reset flow
  int _changePasswordFlowKey = 0;
  int _rentalInfoKey = 0; // increment เมื่อ save ข้อมูลการเช่า
  int _homeReloadSeq = 0; // increment ทุกครั้งที่เข้าหน้า Home ผู้เช่า
  int _buildBillKey = 0; // increment ทุกครั้งที่เริ่มสร้างบิลใหม่
  bool _justSavedRental = false; // true หลังกดบันทึกข้อมูลการเช่า
  bool _justSavedProfile = false; // true หลังยืนยันเปลี่ยนเบอร์/รหัสผ่าน
  bool _forgotPasswordFlow = false; // true = มาจาก ลืมรหัสผ่าน
  String _oldPasswordForChange = ''; // รหัสเดิมที่กรอกในหน้าเปลี่ยนรหัสผ่าน
  bool _isRoommate = false; // true = สมัครด้วยรหัสคำเชิญ
  bool _isAdmin = false; // true = ผู้ดูแล
  Map<String, String> _rentalInfo = {}; // ข้อมูลการเช่าที่บันทึก
  String? _editingAnnouncementId; // id ของประกาศที่กำลังแก้ไข
  Map<String, String>? _editingInitialData; // ข้อมูลเริ่มต้นของประกาศที่แก้ไข
  int _editAnnounceSeq = 0; // เพิ่มทุกครั้งที่เปิดหน้าเพิ่ม/แก้ไขประกาศ เพื่อสร้างหน้าใหม่ด้วยข้อมูลล่าสุด

  // ── แชทงานแจ้งซ่อม ──
  // repairId ของงานที่เปิดห้องแชทอยู่ (null = ไม่มี/โหมดอื่น)
  String? _chatRepairId;
  // true = เปิด ChatScreen เป็น flow แจ้งซ่อมใหม่ (บอท), false = แชทห้องพักทั่วไป/งานซ่อมเดิม
  bool _chatIsRepairFlow = false;
  // ข้อมูลหัวการ์ดฝั่งแอดมิน (ชื่อ/ห้อง/jobId/สถานะ)
  Map<String, dynamic> _chatRepairInfo = {};

  Future<void> _loadUserAvatar() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      String? avatar;
      // Try tenants first
      final tenant = await supabase
          .from('tenants')
          .select('avatar_url')
          .eq('id', uid)
          .maybeSingle();
      avatar = tenant?['avatar_url']?.toString();
      // If not found, try roommate_invites
      if ((avatar == null || avatar.isEmpty) && _isRoommate) {
        final roommate = await supabase
            .from('roommate_invites')
            .select('avatar_url')
            .eq('id', uid)
            .maybeSingle();
        avatar = roommate?['avatar_url']?.toString();
      }
      // If still not found, try admins
      if ((avatar == null || avatar.isEmpty) && _isAdmin) {
        final admin = await supabase
            .from('admins')
            .select('avatar_url')
            .eq('id', uid)
            .maybeSingle();
        avatar = admin?['avatar_url']?.toString();
      }
      if (avatar != null && avatar.isNotEmpty && mounted) {
        setState(() {
          _avatarUrl = avatar!;
        });
      }
    } catch (e) {
      debugPrint('load avatar error: $e');
    }
  }

  Future<void> _loadRentalInfo() async {
    final info = await TenantAuthService().getTenantRentalInfo();
    if (info != null) {
      setState(() {
        _rentalInfo = info;
      });
    }
  }

  /// โหลดค่าเช่ารายคนในห้อง (ผู้เช่าหลัก + Roommate) สำหรับการ์ดค่าเช่า
  Future<void> _loadRentBreakdown() async {
    try {
      final breakdown = await RoomMembersService().loadRoomRentBreakdown();
      if (!mounted) return;
      setState(() {
        _rentBreakdown = breakdown;
      });
    } catch (e) {
      print('❌ _loadRentBreakdown error: $e');
    }
  }

  /// โหลดบิลปัจจุบันของห้อง (ให้สถานะตามผู้เช่าหลัก เช่น รอตรวจสอบ)
  Future<void> _reloadCurrentBill() async {
    try {
      final bill = await mockService.getCurrentBill(
        roomNumber: _tenantRoom['room_number']?.toString(),
        roomId: _tenantRoom['room_id']?.toString(),
      );
      if (!mounted) return;
      setState(() {
        _currentBill = bill;
      });
    } catch (e) {
      print('❌ _reloadCurrentBill error: $e');
    }
  }

  /// โหลดรายชื่อผู้เช่าใหม่ (ชื่อ/เบอร์อาจถูกผู้เช่าแก้ไขได้)
  Future<void> _loadTenantList() async {
    try {
      final list = await mockService.getTenantList(dormitoryId: _dormitoryId);
      if (!mounted) return;
      setState(() {
        _tenantList = list;
      });
    } catch (e) {
      print('❌ _loadTenantList error: $e');
    }
  }

  AppScreen _previousScreen = AppScreen.homeUser; // หน้าก่อนหน้าสำหรับ back
  AppScreen? _forgotPasswordBackTo; // หน้าที่กลับไปหลังลืมรหัสผ่าน
  String _selectedAnnouncementImage = 'assets/images/announcement_1.png';
  Map<String, String> _selectedAnnouncement = {}; // ประกาศที่เลือกดูรายละเอียด
  bool _isAdminAnnounceDetails = false; // true = เปิด details จากฝั่ง admin
  String? _dormitoryId; // admin's dormitory id
  final _requestKey = GlobalKey<RequestScreenState>();
  final _dormitoryRequestKey = GlobalKey<DormitoryRequestScreenState>();
  final _invitationCodeKey = GlobalKey<InvitationCodeScreenState>();
  final _roomMembersKey = GlobalKey<RoomMembersScreenState>();
  final _tenantKey = GlobalKey<TenantScreenState>();
  final _masterTenantKey = GlobalKey<MasterTenantScreenState>();
  final _editeTenantKey = GlobalKey<EditeTenantScreenState>();
  final _dormitorySettingsKey = GlobalKey<DormitorySettingsScreenState>();
  final _tenantBillKey = GlobalKey<TenantBillScreenState>();
  final _reportRepairKey = GlobalKey<ReportARepairScreenState>();
  final _dashboardKey = GlobalKey<DashboardScreenState>();
  final _paymentHistoryKey = GlobalKey<PaymentHistoryScreenState>();
  String? _selectedDormRequestId;
  String? _tenantUserId;
  int _announceReloadSeq = 0; // เพิ่มเพื่อ reload หน้า announce admin

  // ── Chat unread badge (จุดแดงที่ไอคอนแชท — ฝั่งผู้เช่า) ──
  bool _hasChatBadge = false;
  // ── Repair badge (จุดแดงที่ไอคอนแจ้งซ่อม — ฝั่งแอดมิน) ──
  bool _hasRepairBadge = false;
  RealtimeChannel? _chatBadgeChannel;

  // ── Mock/Supabase data ────────────────────────────────────
  Map<String, dynamic> _currentBill = {};
  Map<String, int> _dashboardStats = {};
  List<Map<String, String>> _tenantList = [];

  /// ค่าเช่ารายคนในห้อง (ผู้เช่าหลัก + Roommate) สำหรับการ์ดค่าเช่า
  List<Map<String, dynamic>> _rentBreakdown = [];
  List<Map<String, dynamic>> _bills = [];
  Map<String, int> _billStats = {};
  Map<int, String> _tenantStatuses = {};
  Map<String, String> _selectedTenantData = {};
  String? _selectedMemberId;

  /// เพิ่มทุกครั้งที่ผู้เช่าเข้าสู่ขั้นตอน "รอผลอนุมัติ" ใหม่
  /// ใช้เป็น key ของ SendRequestScreen เพราะทั้งหมดอยู่ใน IndexedStack
  /// (ถ้าไม่เปลี่ยน key หน้าจอจะเก็บสถานะเก่าไว้ เช่น rejected ค้างแม้สมัครใหม่)
  int _sendRequestSeq = 0;

  /// เพิ่มทุกครั้งที่เข้าหน้า "รอย้ายห้อง/ยกระดับเป็นผู้เช่าหลัก" ใหม่
  /// ใช้เป็น key ของ PendingRoomTransferScreen เพราะอยู่ใน IndexedStack
  /// (ถ้าไม่เปลี่ยน key หน้าจอจะเก็บ _status เดิมไว้ และ timer poll ที่ถูก
  ///  cancel ไปแล้วตอน approved/rejected จะไม่เริ่มใหม่ → ค้างสถานะเก่า)
  int _pendingTransferSeq = 0;

  /// ประเภทคำขอที่หน้า "รออนุมัติ" กำลังแสดง
  /// (ยกระดับเป็นผู้เช่าหลัก หรือ เข้าร่วมห้องด้วยรหัสเชิญ)
  PendingRequestType _pendingRequestType = PendingRequestType.upgrade;

  int _selectedTenantIndex = -1;
  List<Map<String, String>> _repairRequests = [];
  List<Map<String, String>> _announcements = [];
  RealtimeChannel? _announcementChannel;
  Map<String, dynamic> _tenantRoom = {};
  Map<String, dynamic> _selectedBill = {};
  String _selectedBillTenant = '';
  String _selectedBillRoom = '';

  @override
  void initState() {
    super.initState();
    _loadMockData();
    _subscribeAnnouncements();
    _refreshChatBadge();
    _subscribeChatBadge();
    _restoreSession();
  }

  /// ถ้ายังมี session ล็อกอินค้างอยู่ (Supabase เก็บไว้ในเบราว์เซอร์) ให้ข้าม onboarding
  /// กลับไปหน้าล่าสุดที่เปิดอยู่ ไม่ต้องเข้าสู่ระบบใหม่
  /// ผู้เช่าต้องได้รับอนุมัติแล้วเท่านั้น (คนที่ยังรอ/ถูกปฏิเสธเริ่มจากหน้าแรกตามเดิม)
  Future<void> _restoreSession() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final info = await mockService.getCurrentUser();
      // getCurrentUser คืนค่า fallback (ไม่มี avatar_url) เมื่อไม่พบแถวผู้ใช้
      if (!info.containsKey('avatar_url')) return;
      final isAdmin = info['role'] == 'admin';

      if (!isAdmin) {
        final member = await supabase
            .from('dormitory_members')
            .select('status')
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (member?['status']?.toString() != 'approved') return;
      }

      final prefs = await SharedPreferences.getInstance();
      final saved = AppScreen.values.asNameMap()[prefs.getString(_lastScreenKey)];
      final allowed = isAdmin ? _adminRestorable : _userRestorable;
      final target = (saved != null && allowed.contains(saved))
          ? saved
          : (isAdmin ? AppScreen.dashboard : AppScreen.homeUser);

      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
        _userName = info['full_name'] ?? '';
        final phone = info['phone'] ?? '';
        if (phone.isNotEmpty) _userPhoneNumber = phone;
        _avatarUrl = info['avatar_url'] ?? '';
      });

      // โหลดข้อมูลหน้าจอ: ถ้า query ใด query หนึ่งพัง ต้องไม่ขวางการกลับเข้าแอป
      // (ไม่งั้นผู้ใช้ที่ session ยังอยู่จะค้างที่ onboarding)
      try {
        if (isAdmin) {
          await _loadMockData();
        } else {
          await _reloadAfterLogin();
        }
      } catch (e) {
        debugPrint('⚠️ restore: โหลดข้อมูลไม่ครบ แต่จะเข้าแอปต่อ: $e');
      }
      if (!mounted) return;
      _navigateTo(target);
    } catch (e) {
      debugPrint('❌ restore session error: $e');
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  /// จำหน้าล่าสุดไว้กู้คืน / ล้างค่าเมื่อกลับหน้าเข้าสู่ระบบ
  Future<void> _persistScreen(AppScreen screen) async {
    if (_restoring) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_userRestorable.contains(screen) ||
          _adminRestorable.contains(screen)) {
        await prefs.setString(_lastScreenKey, screen.name);
      } else if (screen == AppScreen.onboarding ||
          screen == AppScreen.selectUser ||
          screen == AppScreen.signIn) {
        await prefs.remove(_lastScreenKey);
      }
    } catch (_) {}
  }

  /// ออกจากระบบจริง (เดิมแค่เปลี่ยนหน้า ทำให้ session ยังค้างอยู่)
  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('❌ sign out error: $e');
    }
    _navigateTo(AppScreen.selectUser);
  }

  @override
  void dispose() {
    _announcementChannel?.unsubscribe();
    _chatBadgeChannel?.unsubscribe();
    super.dispose();
  }

  /// เช็ค badge ทั้งสองฝั่ง (ผู้เช่า = แชท, แอดมิน = แจ้งซ่อม)
  Future<void> _refreshChatBadge() async {
    if (_isAdmin) {
      // ฝั่งแอดมิน → เช็คงานซ่อม/ข้อความจากผู้เช่า
      if (mounted && _hasChatBadge) setState(() => _hasChatBadge = false);
      final has = await ChatService().hasUnreadForAdmin();
      if (mounted) setState(() => _hasRepairBadge = has);
    } else {
      // ฝั่งผู้เช่า → เช็คข้อความจากแอดมิน
      if (mounted && _hasRepairBadge) setState(() => _hasRepairBadge = false);
      final has = await ChatService().hasUnreadFromAdmin();
      if (mounted) setState(() => _hasChatBadge = has);
    }
  }

  /// ฟัง chat_messages + repairs แบบ realtime → เด้ง badge ทันที
  void _subscribeChatBadge() {
    final client = Supabase.instance.client;
    _chatBadgeChannel = client.channel('realtime:chat_badge');
    _chatBadgeChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final role = payload.newRecord['sender_role']?.toString() ?? '';
            if (_isAdmin) {
              // แอดมิน → ข้อความใหม่จากผู้เช่า + ไม่อยู่หน้าแชทแอดมิน
              final fromTenant = role == 'tenant' || role == 'roommate';
              final onChat = _currentScreen == AppScreen.chatAdmin;
              if (fromTenant && !onChat && mounted) {
                setState(() => _hasRepairBadge = true);
              }
            } else {
              // ผู้เช่า → ข้อความใหม่จากแอดมิน/บอท + ไม่อยู่หน้าแชท
              final fromAdmin = role == 'admin' || role == 'bot';
              final onChat = _currentScreen == AppScreen.chat;
              if (fromAdmin && !onChat && mounted) {
                setState(() => _hasChatBadge = true);
              }
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'repairs',
          callback: (payload) {
            // งานซ่อมใหม่ → เด้ง badge ฝั่งแอดมิน (ถ้าไม่อยู่หน้าแจ้งซ่อม)
            final onRepair = _currentScreen == AppScreen.reportRepair;
            if (_isAdmin && !onRepair && mounted) {
              setState(() => _hasRepairBadge = true);
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadMockData() async {
    // โหลด dormitoryId ของ admin ก่อน (กรณี login ใหม่หรือ hot reload)
    if (_dormitoryId == null) {
      _dormitoryId = await mockService.getAdminDormitoryId();
    }

    final results = await Future.wait([
      mockService.getCurrentBill(),
      mockService.getDashboardStats(dormitoryId: _dormitoryId),
      mockService.getTenantRoom(),
      mockService.getRepairRequests(dormitoryId: _dormitoryId),
      mockService.getTenantList(dormitoryId: _dormitoryId),
      mockService.getAnnouncements(dormitoryId: _dormitoryId),
      mockService.getBills(dormitoryId: _dormitoryId),
      mockService.getBillStats(dormitoryId: _dormitoryId),
    ]);
    if (!mounted) return;
    setState(() {
      _currentBill = results[0] as Map<String, dynamic>;
      _dashboardStats = results[1] as Map<String, int>;
      _tenantRoom = results[2] as Map<String, dynamic>;
      _repairRequests = results[3] as List<Map<String, String>>;
      _tenantList = results[4] as List<Map<String, String>>;
      _announcements = results[5] as List<Map<String, String>>;
      _bills = results[6] as List<Map<String, dynamic>>;
      _billStats = results[7] as Map<String, int>;
    });
  }

  void _subscribeAnnouncements() {
    final client = Supabase.instance.client;
    _announcementChannel = client
        .channel('realtime:announcements')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          callback: (payload) async {
            await _reloadAnnouncements();
          },
        )
        .subscribe();
  }

  Future<void> _reloadAnnouncements() async {
    try {
      final list = await mockService.getAnnouncements(dormitoryId: _dormitoryId);
      if (!mounted) return;
      setState(() {
        _announcements = list;
      });
    } catch (_) {}
  }

  // เรียกหลัง login เพื่อโหลดข้อมูล user + bill ใหม่
  Future<void> _reloadAfterLogin() async {
    final user = await mockService.getCurrentUser();
    final room = await mockService.getTenantRoom();
    final bill = await mockService.getCurrentBill(
      roomNumber: room['room_number']?.toString(),
      roomId: room['room_id']?.toString(),
    );
    final isRoommate = await mockService.isCurrentUserRoommate();

    // โหลดประกาศจากหอพักของผู้ใช้ (ผู้เช่าและ Roommate)
    final dormId = room['dormitory_id']?.toString();
    final announcements = <Map<String, String>>[];
    if (dormId != null && dormId.isNotEmpty) {
      final list = await mockService.getAnnouncements(dormitoryId: dormId);
      announcements.addAll(list);
    }

    // โหลดค่าเช่ารายคนในห้อง (สำหรับ Roommate และผู้เช่าหลัก)
    await _loadRentBreakdown();

    if (!mounted) return;
    setState(() {
      if (_userName.isEmpty) _userName = user['full_name'] ?? '';
      if (_userPhoneNumber == '099-9999999')
        _userPhoneNumber = user['phone'] ?? '';
      _tenantRoom = room;
      _currentBill = bill;
      _isRoommate = isRoommate;
      _announcements = announcements;
    });
    // โหลด rental info (ห้อง/อาคาร/ชั้น) หลัง login
    await _loadRentalInfo();
    await _loadUserAvatar();
    await _refreshChatBadge();
  }

  Future<void> _saveDormitoryAndRooms(Map<String, dynamic> data) async {
    final totalRooms = (data['totalRooms'] as int?) ?? 0;
    final roomArrangement = (data['roomArrangement'] as String?) ?? 'empty';

    // ── ตั้งค่า stats ทันทีจากข้อมูลที่กรอก (ไม่รอ Supabase) ──
    setState(() {
      _dashboardStats = {
        'total_tenants': 0,
        'total_rooms': totalRooms,
        'vacant_rooms': roomArrangement == 'empty' ? totalRooms : 0,
        'repair_requests': 0,
      };
    });

    // ── บันทึกลง Supabase ────────────────────────────────────
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;

    try {
      // 1. Insert dormitory
      final dormitoryRes = await db
          .from('dormitories')
          .insert({
            'dorm_code': data['dorm_code'],
            'name': data['name'],
            'dorm_name': data['name'],
            'address': data['address'],
            'phone': data['phone']?.toString() ?? '',
            'floor_count': data['floorCount'],
            'total_rooms': data['totalRooms'],
            'room_format': data['roomNumberFormat'],
            'max_tenants': data['maxTenants'],
            'room_arrangement': data['roomArrangement'] ?? 'empty',
            'electricity_rate': data['electricRate'],
            'water_rate': data['waterRate'],
            'created_by': uid,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final dormitoryId = dormitoryRes['id'];
      _dormitoryId = dormitoryId;

      // 2. Generate and insert rooms
      final floorCount = data['floorCount'] as int;
      final roomNumberFormat = data['roomNumberFormat'] as String;
      final maxTenants = data['maxTenants'] as int;

      final roomsToInsert = <Map<String, dynamic>>[];

      // ตรวจว่า format เป็นแบบ range "A101-A110,A201-A210" หรือเปล่า
      final isRangeFormat = RegExp(r'\w+-\w+').hasMatch(roomNumberFormat);

      if (isRangeFormat) {
        // --- แบบ range: แยก segment ด้วย comma แล้ว expand แต่ละ range ---
        final segments = roomNumberFormat.split(',');
        int floorNum = 1;
        for (final seg in segments) {
          final parts = seg.trim().split('-');
          if (parts.length == 2) {
            final fromStr = parts[0].trim();
            final toStr = parts[1].trim();
            final prefixMatch = RegExp(r'^(.*?)(\d+)$').firstMatch(fromStr);
            final prefix = prefixMatch?.group(1) ?? '';
            final from = int.tryParse(prefixMatch?.group(2) ?? '') ?? 1;
            final toNum =
                int.tryParse(
                  RegExp(r'(\d+)$').firstMatch(toStr)?.group(1) ?? '',
                ) ??
                from;
            for (int num = from; num <= toNum; num++) {
              roomsToInsert.add({
                'id': _generateUuid(),
                'dormitory_id': dormitoryId,
                'room_number': '$prefix$num',
                'floor': floorNum,
                'building': prefix.isNotEmpty ? prefix : 'A',
                'max_tenants': maxTenants,
                'status': roomArrangement == 'empty' ? 'vacant' : 'occupied',
                'created_at': DateTime.now().toIso8601String(),
              });
            }
          }
          floorNum++;
        }
      } else {
        // --- แบบ auto-generate: {floor}/{room} หรือ A101 หรือ นับเรื่อยๆ ---
        final roomsPerFloor = (totalRooms / floorCount).ceil();

        for (int floor = 1; floor <= floorCount; floor++) {
          for (int i = 1; i <= roomsPerFloor; i++) {
            final roomIndex = (floor - 1) * roomsPerFloor + i;
            if (roomIndex > totalRooms) break;

            String roomNumber;
            final format = roomNumberFormat.trim();
            if (format.contains('{floor}') || format.contains('{room}')) {
              roomNumber = format
                  .replaceAll('{floor}', floor.toString())
                  .replaceAll('{room}', i.toString().padLeft(2, '0'));
            } else {
              final floorAwareMatch = RegExp(
                r'^(.*?)([1-9])(\d{2,})$',
              ).firstMatch(format);
              final prefixStr = floorAwareMatch?.group(1) ?? '';
              final floorDigitVal = int.tryParse(
                floorAwareMatch?.group(2) ?? '',
              );
              final roomSuffix = floorAwareMatch?.group(3);

              if (floorAwareMatch != null &&
                  floorDigitVal == 1 &&
                  floorCount > 1) {
                final roomPad = roomSuffix!.length;
                roomNumber =
                    '$prefixStr$floor${i.toString().padLeft(roomPad, '0')}';
              } else {
                final simpleMatch = RegExp(r'(\d+)\s*$').firstMatch(format);
                if (simpleMatch == null) {
                  roomNumber = '$format$roomIndex';
                } else {
                  final digits = simpleMatch.group(1) ?? '';
                  final start = int.tryParse(digits) ?? 1;
                  final seq = start + roomIndex - 1;
                  roomNumber =
                      '${format.substring(0, simpleMatch.start)}${seq.toString().padLeft(digits.length, '0')}';
                }
              }
            }

            roomsToInsert.add({
              'id': _generateUuid(),
              'dormitory_id': dormitoryId,
              'room_number': roomNumber,
              'floor': floor,
              'building': roomNumberFormat.isNotEmpty
                  ? roomNumberFormat[0]
                  : 'A',
              'max_tenants': maxTenants,
              'status': roomArrangement == 'empty' ? 'vacant' : 'occupied',
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
      }

      if (roomsToInsert.isNotEmpty) {
        await db.from('rooms').insert(roomsToInsert);
      }

      // Refresh stats จาก DB จริงหลัง save สำเร็จ
      await _loadMockData();
    } catch (e) {
      print('⚠️ Supabase save error (stats แสดงจาก local data แทน): $e');
    }
  }

  void _navigateTo(AppScreen screen) {
    _persistScreen(screen);
    setState(() {
      // capture ก่อน update เพื่อใช้ตรวจ admin context
      final previousScreen = _currentScreen;
      _currentScreen = screen;
      // หน้าที่ใช้ร่วมกันทั้ง admin/user (profile, request, notification,
      // reportRepair ฯลฯ) ให้คงค่า _isAdmin เดิมไว้ ไม่คำนวณใหม่
      const sharedScreens = {
        AppScreen.profile,
        AppScreen.request,
        AppScreen.notification,
        AppScreen.dormitoryRequest,
        AppScreen.reportRepair,
        AppScreen.chatAdmin,
        AppScreen.announceAdmin,
        AppScreen.announceDetails,
        AppScreen.changeNumber,
        AppScreen.changePassword,
        AppScreen.confirmChangeNumber,
        AppScreen.confirmChangePassword,
        AppScreen.otp,
        AppScreen.privacyPolicy,
        AppScreen.termsOfUse,
        AppScreen.dara,
        // เมนูในโปรไฟล์ที่แอดมินก็เข้าได้ → ต้องคง _isAdmin ไว้ ไม่งั้นย้อนกลับ
        // แล้วโปรไฟล์กลายเป็นของผู้เช่า
        AppScreen.closeAccount,
        AppScreen.deletionFailed,
      };

      if (!sharedScreens.contains(screen)) {
        // หน้าแอดมิน-only ทุกหน้าต้องอยู่ในนี้เพื่อ set _isAdmin = true
        _isAdmin =
            screen == AppScreen.dashboard ||
            screen == AppScreen.tenant ||
            screen == AppScreen.masterTenant ||
            screen == AppScreen.editeTenant ||
            screen == AppScreen.tenantBill ||
            screen == AppScreen.billDetails ||
            screen == AppScreen.buildNewDormitory ||
            screen == AppScreen.selectDormitory ||
            screen == AppScreen.dormitorySettings;
        if (screen == AppScreen.selectUser || screen == AppScreen.signIn) {
          _isAdmin = false;
        }
      } else if (screen == AppScreen.profile) {
        // กำหนด/คง admin mode เมื่อ navigate มาที่ profile
        // ใช้ previousScreen (ก่อน update) เพราะ _currentScreen ถูก set แล้ว
        const adminScreens = {
          AppScreen.dashboard,
          AppScreen.tenant,
          AppScreen.masterTenant,
          AppScreen.editeTenant,
          AppScreen.tenantBill,
          AppScreen.billDetails,
          AppScreen.reportRepair,
          AppScreen.announceAdmin,
          AppScreen.dormitorySettings,
          AppScreen.buildNewDormitory,
        };
        if (adminScreens.contains(previousScreen)) {
          _isAdmin = true;
        }
      }
      if (screen == AppScreen.onboarding) {
        _onboardingPage = 0;
      }
    });

    // เข้าหน้าแชทผู้เช่า → เคลียร์ badge แชท
    if (screen == AppScreen.chat && _hasChatBadge) {
      _hasChatBadge = false;
    }
    // แอดมินเข้าหน้าแจ้งซ่อม → เคลียร์ badge แจ้งซ่อม
    if (screen == AppScreen.reportRepair && _hasRepairBadge) {
      _hasRepairBadge = false;
    }

    if (screen == AppScreen.homeUser) {
      setState(() => _homeReloadSeq++);
      // การ์ดค่าเช่า/สถานะบิลแสดงตามห้อง → โหลดใหม่ทุกครั้งที่เข้าหน้า
      _loadRentBreakdown();
      _reloadCurrentBill();
    }
    if (screen == AppScreen.request) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestKey.currentState?.refresh();
      });
    }
    if (screen == AppScreen.dormitoryRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dormitoryRequestKey.currentState?.refresh();
      });
    }
    if (screen == AppScreen.tenantBill) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tenantBillKey.currentState?.reload();
      });
    }
    if (screen == AppScreen.dashboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dashboardKey.currentState?.reload();
      });
    }
    if (screen == AppScreen.reportRepair) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reportRepairKey.currentState?.reload();
      });
    }
    if (screen == AppScreen.billHistory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _paymentHistoryKey.currentState?.reload();
      });
    }
    // หน้าผู้เช่าแสดงทั้งผู้เช่าหลักและ Roommate → โหลดใหม่ทุกครั้งที่เข้าหน้า
    // (เช่น หลังอนุมัติคำขอ Roommate ใหม่)
    if (screen == AppScreen.tenant) {
      _loadTenantList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tenantKey.currentState?.refresh();
      });
    }
    // การ์ดค่าเช่า/สถานะบิลแสดงตามห้อง → โหลดใหม่ทุกครั้งที่เข้าหน้า
    if (screen == AppScreen.rentalFee) {
      _loadRentBreakdown();
      _reloadCurrentBill();
    }
    // โหลดบิลใหม่เมื่อเข้าหน้าบิลแอดมิน
    if (screen == AppScreen.tenantBill) {
      () async {
        try {
          final bills = await mockService.getBills(dormitoryId: _dormitoryId);
          final stats = await mockService.getBillStats(dormitoryId: _dormitoryId);
          if (!mounted) return;
          setState(() {
            _bills = bills;
            _billStats = stats;
          });
        } catch (e) {
          print('❌ reload tenant bills error: $e');
        }
      }();
    }
    // หน้าแก้ไขข้อมูลผู้เช่า → โหลดข้อมูลเดิมใหม่ (ชื่อ/เบอร์/ค่าเช่าล่าสุด)
    if (screen == AppScreen.editeTenant) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editeTenantKey.currentState?.refresh();
      });
    }
  }

  Future<void> _handleTenantSignUpDone() async {
    // เก็บ uid ของผู้เช่าที่สมัครผ่าน Google ไว้ให้ SendRequestScreen poll
    // แล้วเข้าหน้ารอผลเหมือนผู้สมัครผ่าน OTP (ไม่ใช้หน้ารอแยกอีกชุด)
    _tenantUserId = supabase.auth.currentUser?.id;
    _sendRequestSeq++;
    setState(() {
      _isAdmin = false;
      _currentScreen = AppScreen.sendRequest;
    });
  }

  /// เปิดแชทห้องพัก (คุยทั่วไป) — ไม่ใช่ flow แจ้งซ่อม
  void _openRoomChat() {
    setState(() {
      _chatRepairId = null;
      _chatIsRepairFlow = false;
    });
    _navigateTo(AppScreen.chat);
  }

  /// เปิดแชทเพื่อ "แจ้งซ่อมใหม่" (บอท) — repairId = null
  void _openNewRepairChat() {
    setState(() {
      _chatRepairId = null;
      _chatIsRepairFlow = true;
    });
    _navigateTo(AppScreen.chat);
  }

  /// เปิดห้องแชทของงานซ่อมเดิม (ฝั่งผู้เช่า)
  void _openRepairChat(String repairId) {
    setState(() {
      _chatRepairId = repairId;
      _chatIsRepairFlow = false;
    });
    _navigateTo(AppScreen.chat);
  }

  /// เปิดห้องแชทของงานซ่อม (ฝั่งแอดมิน) พร้อมข้อมูลหัวการ์ด
  void _openAdminChat(String repairId, Map<String, dynamic> info) {
    setState(() {
      _chatRepairId = repairId;
      _chatRepairInfo = info;
    });
    _navigateTo(AppScreen.chatAdmin);
  }

  void _navigateToVerify(Map<String, dynamic> data) {
    // บันทึก uid ผู้เช่าไว้ตอนนี้ เพราะ session ปัจจุบันคือผู้เช่าที่เพิ่งสมัคร
    _tenantUserId = supabase.auth.currentUser?.id;
    _sendRequestSeq++;
    setState(() {
      _currentScreen = AppScreen.verifyNumber;
      _verifyPhoneNumber = data['phone']?.toString() ?? '';
      // เก็บรหัสหอพัก/เลขห้อง/รหัสคำเชิญไว้ส่งต่อให้หน้า add_profile
      // เพื่อสร้างคำขอเข้าหอพัก (dormitory_members) ให้แอดมินอนุมัติ
      _verifyDormCode = data['dormCode']?.toString() ?? '';
      _verifyRoomNumber = data['roomNumber']?.toString() ?? '';
      _verifyInviteCode = data['inviteCode']?.toString() ?? '';
      _userName = data['name']?.toString() ?? '';
      _isRoommate = data['isRoommate'] == true;
      _isAdmin = data['isAdmin'] == true;
    });
  }

  void _nextOnboardingPage() {
    if (_onboardingPage < 2) {
      setState(() => _onboardingPage++);
    } else {
      _navigateTo(AppScreen.selectUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ระหว่างตรวจ session ตอนเปิดแอป แสดง loading แทนที่จะวูบไปหน้า onboarding
    if (_restoring) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4F8FDB)),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentScreen.index,
        children: [
          OnboardingScreen(
            currentPage: _onboardingPage,
            onNextPage: _nextOnboardingPage,
          ),
          SelectUserScreen(
            onSelectTenant: () => _navigateTo(AppScreen.signUp),
            onSelectAdmin: () => _navigateTo(AppScreen.signUpAdmin),
            onSignIn: () => _navigateTo(AppScreen.signIn),
          ),
          SignUpUserScreen(
            onBack: () => _navigateTo(AppScreen.selectUser),
            onNavigateToSignIn: () => _navigateTo(AppScreen.signIn),
            onNavigateToVerify: _navigateToVerify,
            onInviteCodeChanged: (hasCode) =>
                setState(() => _isRoommate = hasCode),
            onUserDataChanged: (name, phone) => setState(() {
              _userName = name;
              _userPhoneNumber = phone;
            }),
          ),
          VerifyNumberScreen(
            onBack: () {
              if (_isAdmin) {
                _navigateTo(AppScreen.signUpAdmin);
              } else {
                _navigateTo(AppScreen.signUp);
              }
            },
            onVerified: () {
              if (_isAdmin) {
                _navigateTo(AppScreen.selectDormitory);
              } else {
                _navigateTo(AppScreen.sendRequest);
              }
            },
            phoneNumber: _verifyPhoneNumber,
            userData: {
              'name': _userName,
              'isRoommate': _isRoommate,
              'isAdmin': _isAdmin,
              'dormCode': _verifyDormCode,
              'roomNumber': _verifyRoomNumber,
              'inviteCode': _verifyInviteCode,
            },
          ),
          SendRequestScreen(
            key: ValueKey('sendRequest_$_sendRequestSeq'),
            userId: _tenantUserId,
            onApproved: () async {
              await _reloadAfterLogin();
              _navigateTo(AppScreen.homeUser);
            },
            onRejected: () => _navigateTo(AppScreen.signUp),
          ),
          AlreadyApprovedScreen(
            onPressed: () => _navigateTo(AppScreen.homeUser),
          ),
          HomeUserScreen(
            key: ValueKey('home_$_isRoommate'),
            onNavigateToRentalFee: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToBill: () {
              setState(() {
                _previousScreen = AppScreen.homeUser;
                _currentScreen = AppScreen.bill;
              });
              _reloadCurrentBill();
            },
            onNavigateToPayment: () {
              setState(() {
                _previousScreen = AppScreen.homeUser;
                _currentScreen = AppScreen.payment;
              });
            },
            onNavigateToChat: () => _navigateTo(AppScreen.userReportRepair),
            onNavigateToAnnounce: () => _navigateTo(AppScreen.announce),
            onNavigateToRepairDetail: _openNewRepairChat,
            onOpenRepairChat: _openRepairChat,
            reloadSeq: _homeReloadSeq,
            onNavigateToAnnounceDetails: (imagePath) {
              setState(() => _selectedAnnouncementImage = imagePath);
              _navigateTo(AppScreen.announceDetails);
            },
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            isRoommate: _isRoommate,
            hasRoom: (_tenantRoom['room_number']?.toString() ?? '').isNotEmpty,
            userName: _userName,
            userPhone: _userPhoneNumber,
            avatarUrl: _avatarUrl,
            roomNumber: _tenantRoom['room_number']?.toString() ?? '',
            currentBill: _currentBill,
            rentBreakdown: _rentBreakdown,
            announcements: _announcements,
            showChatBadge: _hasChatBadge,
          ),
          SignInScreen(
            onBack: () => _navigateTo(AppScreen.selectUser),
            onSignIn: (name, phone) {
              setState(() {
                _userName = name;
                _userPhoneNumber = phone;
              });
              _reloadAfterLogin();
              _navigateTo(AppScreen.homeUser);
            },
            onSignInAsAdmin: (name, phone) {
              setState(() {
                _userName = name;
                _userPhoneNumber = phone;
              });
              _reloadAfterLogin();
              _navigateTo(AppScreen.dashboard);
            },
            onForgotPassword: () {
              _forgotPasswordBackTo = AppScreen.signIn;
              _navigateTo(AppScreen.forgotPassword);
            },
          ),
          RentalFeeScreen(
            onNavigateToHome: () => _navigateTo(AppScreen.homeUser),
            onNavigateToRentalFee: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToBill: () {
              setState(() {
                _previousScreen = AppScreen.rentalFee;
                _currentScreen = AppScreen.bill;
              });
              _reloadCurrentBill();
            },
            onNavigateToPayment: () {
              setState(() {
                _previousScreen = AppScreen.rentalFee;
                _currentScreen = AppScreen.payment;
              });
            },
            onNavigateToPaymentHistory: () =>
                _navigateTo(AppScreen.paymentHistory),
            onNavigateToChat: () => _navigateTo(AppScreen.userReportRepair),
            onNavigateToAnnounce: () => _navigateTo(AppScreen.announce),
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            currentBill: _currentBill,
            hasRoom: (_tenantRoom['room_number']?.toString() ?? '').isNotEmpty,
            rentBreakdown: _rentBreakdown,
            showChatBadge: _hasChatBadge,
          ),
          Builder(
            builder: (_) => BillScreen(
              // ปุ่มย้อนกลับ → กลับไปหน้าก่อนหน้า
              onBack: () {
                final target = _previousScreen == AppScreen.bill
                    ? AppScreen.rentalFee
                    : _previousScreen;
                _navigateTo(target);
              },
              onNavigateToPayment: () {
                setState(() {
                  _previousScreen = AppScreen.bill;
                  _currentScreen = AppScreen.payment;
                });
              },
              currentBill: _selectedBill.isNotEmpty ? _selectedBill : _currentBill,
              userName: _selectedBillTenant.isNotEmpty ? _selectedBillTenant : _userName,
              roomNumber: _selectedBillRoom.isNotEmpty ? _selectedBillRoom : (_tenantRoom['room_number']?.toString() ?? ''),
              showProofFull: _previousScreen == AppScreen.paymentHistory,
              isRoommate: _isRoommate,
            ),
          ),
          Builder(
            builder: (_) => BillDetailsScreen(
              onBack: () => _navigateTo(AppScreen.tenantBill),
              onEdit: () {},
              bill: _selectedBill,
              tenantName: _selectedBillTenant.isEmpty
                  ? 'พัชราวรรณ  ศรีบุญ'
                  : _selectedBillTenant,
              room: _selectedBillRoom.isEmpty ? 'A101' : _selectedBillRoom,
            ),
          ),
          Builder(
            builder: (_) => PaymentScreen(
              onBack: () => _navigateTo(_previousScreen),
              onSubmit: () async {
                final bid = _currentBill['id']?.toString();
                if (bid == null || bid.isEmpty) return;
                // รีโหลดบิลจาก Supabase
                final bills = await mockService.getBills(
                  dormitoryId: _dormitoryId,
                );
                final stats = await mockService.getBillStats(
                  dormitoryId: _dormitoryId,
                );
                final current = await mockService.getCurrentBill();
                if (!mounted) return;
                setState(() {
                  _bills = bills;
                  _billStats = stats;
                  _currentBill = current;
                });
                _navigateTo(AppScreen.bill);
              },
              tenantName: _userName.isEmpty
                  ? 'คุณพัชราวรรณ ศรีบุญ'
                  : 'คุณ$_userName',
              roomNumber: _tenantRoom['room_number']?.toString() ?? 'A101',
              currentBill: _currentBill,
            ),
          ),
          PaymentHistoryScreen(
            key: _paymentHistoryKey,
            onBack: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToHome: () => _navigateTo(AppScreen.homeUser),
            onNavigateToRentalFee: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToBill: (bill) {
              setState(() {
                _selectedBill = bill;
                _selectedBillTenant = bill['tenant_name']?.toString() ?? '';
                _selectedBillRoom = bill['room']?.toString() ?? '';
                _previousScreen = AppScreen.paymentHistory;
                _currentScreen = AppScreen.bill;
              });
            },
            onNavigateToBillHistory: () => _navigateTo(AppScreen.billHistory),
            onNavigateToChat: () => _navigateTo(AppScreen.userReportRepair),
            onNavigateToAnnounce: () => _navigateTo(AppScreen.announce),
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            showChatBadge: _hasChatBadge,
          ),
          BillHistoryScreen(
            onBack: () => _navigateTo(AppScreen.paymentHistory),
            onNavigateToHome: () => _navigateTo(AppScreen.homeUser),
            onNavigateToRentalFee: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToChat: () => _navigateTo(AppScreen.userReportRepair),
            onNavigateToAnnounce: () => _navigateTo(AppScreen.announce),
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
          ),
          ChatScreen(
            key: ValueKey('chat_${_chatRepairId ?? 'new'}_${_chatIsRepairFlow ? 'repair' : 'room'}'),
            onBack: () => _navigateTo(AppScreen.userReportRepair),
            repairId: _chatRepairId,
            isRepairFlow: _chatIsRepairFlow,
            senderRole: _isRoommate ? 'roommate' : 'tenant',
          ),
          AnnounceScreen(
            key: ValueKey('announce_$_announceReloadSeq'),
            onNavigateToHome: () => _navigateTo(AppScreen.homeUser),
            onNavigateToRentalFee: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToChat: () => _navigateTo(AppScreen.userReportRepair),
            onNavigateToDetails: (item) {
              setState(() {
                _selectedAnnouncement = item;
                _selectedAnnouncementImage = item['image'] ?? '';
                _isAdminAnnounceDetails = false;
              });
              _navigateTo(AppScreen.announceDetails);
            },
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            announcements: _announcements,
            hasRoom: (_tenantRoom['room_number']?.toString() ?? '').isNotEmpty,
            // admin → repair badge (index 3), user → chat badge (index 2)
            showChatBadge: _isAdmin ? _hasRepairBadge : _hasChatBadge,
          ),
          Builder(
            builder: (_) => AnnounceDetailsScreen(
              onBack: () {
                if (_isAdminAnnounceDetails) {
                  setState(() => _isAdminAnnounceDetails = false);
                  _navigateTo(AppScreen.announceAdmin);
                } else {
                  _navigateTo(AppScreen.announce);
                }
              },
              imagePath: _selectedAnnouncement['image'],
              title: _selectedAnnouncement['title'] ?? '',
              detail: _selectedAnnouncement['content'] ?? '',
              date: _selectedAnnouncement['date'] ?? '',
              endDate: _selectedAnnouncement['end_date'] ?? '',
              isAdmin: _isAdminAnnounceDetails,
              announcementId: _selectedAnnouncement['id'] ?? '',
              onEdit: ({announcementId, initialData}) {
                setState(() {
                  _editingAnnouncementId = announcementId;
                  _editingInitialData = initialData;
                  _editAnnounceSeq++;
                });
                _navigateTo(AppScreen.editeAnnounce);
              },
              onDelete: () {
                // Reload announcements after delete
                setState(() => _announceReloadSeq++);
                // Navigate back
                if (_isAdminAnnounceDetails) {
                  _navigateTo(AppScreen.announceAdmin);
                } else {
                  _navigateTo(AppScreen.announce);
                }
              },
            ),
          ),
          UserReportARepairScreen(
            key: ValueKey('userReport_${_currentScreen == AppScreen.userReportRepair}'),
            onNewRepair: _openNewRepairChat,
            onOpenRepairChat: (_) => _openRoomChat(),
            onNavigateToHome: () => _navigateTo(AppScreen.homeUser),
            onNavigateToBill: () {
              setState(() {
                _previousScreen = AppScreen.userReportRepair;
                _currentScreen = AppScreen.bill;
              });
            },
            onNavigateToRentalFee: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToChat: () => _navigateTo(AppScreen.chat),
            onNavigateToAnnounce: () => _navigateTo(AppScreen.announce),
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            showChatBadge: _hasChatBadge,
          ),
          ProfileScreen(
            showSavedToast: _justSavedProfile,
            onToastShown: () => _justSavedProfile = false,
            onNavigateToDashboard: () => _navigateTo(AppScreen.dashboard),
            onNavigateToTenant: () => _navigateTo(AppScreen.tenant),
            onNavigateToAdminBill: () => _navigateTo(AppScreen.tenantBill),
            onNavigateToReportRepair: () => _navigateTo(AppScreen.reportRepair),
            onNavigateToNotification: () => _navigateTo(AppScreen.request),
            onNavigateToAdminAnnounce: () => _navigateTo(AppScreen.announceAdmin),
            onNavigateToHome: () => _navigateTo(AppScreen.homeUser),
            onNavigateToRentalFee: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToChat: () => _navigateTo(AppScreen.userReportRepair),
            onNavigateToAnnounce: () => _navigateTo(AppScreen.announce),
            onLogout: _logout,
            onNavigateToPrivacyPolicy: () =>
                _navigateTo(AppScreen.privacyPolicy),
            onNavigateToChangePassword: () =>
                _navigateTo(AppScreen.changePassword),
            onNavigateToDormitory: () {
              // หน้านี้อยู่ใน IndexedStack → ต้องโหลดข้อมูลใหม่เอง
              // ไม่งั้นจะค้างข้อมูลเก่าจากตอนแอปเริ่มทำงาน
              _dormitorySettingsKey.currentState?.reload();
              _navigateTo(AppScreen.dormitorySettings);
            },
            onNavigateToRentalInfo: () =>
                _navigateTo(AppScreen.rentalInformation),
            onNavigateToTermsOfUse: () => _navigateTo(AppScreen.termsOfUse),
            onNavigateToDara: () => _navigateTo(AppScreen.dara),
            onNavigateToRoomMembers: () {
              // หน้านี้อยู่ใน IndexedStack → ต้องโหลดข้อมูลสมาชิกใหม่เอง
              _roomMembersKey.currentState?.reload();
              _navigateTo(AppScreen.roomMembers);
            },
            onNavigateToCloseAccount: () => _navigateTo(AppScreen.closeAccount),
            onLeaveRoom: () => _navigateTo(AppScreen.leaveTheRoom),
            onNavigateToParticipate: () => _navigateTo(AppScreen.participate),
            onUpgradeToTenant: () {
              setState(() {
                _previousScreen = AppScreen.profile;
                _currentScreen = AppScreen.applicationProcess;
              });
            },
            onAvatarChanged: (url) {
              setState(() {
                _avatarUrl = url;
              });
            },
            phoneNumber: _userPhoneNumber,
            isRoommate: _isRoommate,
            isAdmin: _isAdmin,
            hasRoom: (_tenantRoom['room_number']?.toString() ?? '').isNotEmpty,
            userName: _userName,
            avatarUrl: _avatarUrl,
            roomNumber: _tenantRoom['room_number']?.toString() ?? '',
            // admin → repair badge (index 3), user → chat badge (index 2)
            showChatBadge: _isAdmin ? _hasRepairBadge : _hasChatBadge,
          ),
          ChangeNumberScreen(
            key: ValueKey('change_$_changeNumberFlowKey'),
            onBack: () => _navigateTo(AppScreen.profile),
            onCancel: () => _navigateTo(AppScreen.profile),
            onNavigateToOtp: () => _navigateTo(AppScreen.otp),
          ),
          OtpScreen(
            key: ValueKey('otp_$_changeNumberFlowKey'),
            onBack: () => _navigateTo(AppScreen.changeNumber),
            onConfirm: () {
              if (_forgotPasswordFlow) {
                setState(() => _forgotPasswordFlow = false);
                _navigateTo(AppScreen.confirmChangePassword);
              } else {
                _navigateTo(AppScreen.confirmChangeNumber);
              }
            },
          ),
          ConfirmChangeNumberScreen(
            key: ValueKey('confirm_$_changeNumberFlowKey'),
            onBack: () => _navigateTo(AppScreen.otp),
            onSave: (newPhone) {
              setState(() {
                _userPhoneNumber = newPhone;
                _changeNumberFlowKey++;
                _justSavedProfile = true;
              });
              _navigateTo(AppScreen.profile);
            },
          ),
          PrivacyPolicyScreen(onBack: () => _navigateTo(AppScreen.profile)),
          ChangePasswordScreen(
            key: ValueKey('changepw_$_changePasswordFlowKey'),
            onBack: () => _navigateTo(AppScreen.profile),
            onContinue: (oldPassword) {
              _oldPasswordForChange = oldPassword;
              _navigateTo(AppScreen.confirmChangePassword);
            },
            onForgotPassword: () {
              _forgotPasswordBackTo = AppScreen.changePassword;
              _navigateTo(AppScreen.forgotPassword);
            },
          ),
          ConfirmChangePasswordScreen(
            key: ValueKey('confirmpw_$_changePasswordFlowKey'),
            onBack: () => _navigateTo(AppScreen.changePassword),
            onSave: (newPassword) async {
              final phone = _userPhoneNumber.replaceAll(RegExp(r'\D'), '');
              // คืน null = สำเร็จ, มีข้อความ = error จริง
              final error = await AuthService().changePassword(
                phone: phone,
                oldPassword: _oldPasswordForChange,
                newPassword: newPassword,
              );
              if (!mounted) return;
              if (error == null) {
                setState(() {
                  _changePasswordFlowKey++;
                  _justSavedProfile = true;
                  _oldPasswordForChange = '';
                });
                _navigateTo(AppScreen.profile);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error,
                      style: const TextStyle(fontFamily: 'Noto Sans Thai'),
                    ),
                    backgroundColor: const Color(0xFFE53935),
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
          ),
          RentalInformationScreen(
            key: ValueKey('rentalinfo_$_rentalInfoKey'),
            onBack: () => _navigateTo(AppScreen.profile),
            onEdit: () async {
              await _loadRentalInfo();
              _navigateTo(AppScreen.editeRentalInformation);
            },
            userName: _userName,
            userPhone: _userPhoneNumber,
            avatarUrl: _avatarUrl,
            onAvatarChanged: (url) {
              setState(() {
                _avatarUrl = url;
              });
            },
            rentalInfo: _rentalInfo,
            showSavedToast: _justSavedRental,
            onToastShown: () => _justSavedRental = false,
          ),
          EditeRentalInformationScreen(
            key: ValueKey('edite_$_rentalInfoKey'),
            rentalInfo: _rentalInfo,
            onBack: () => _navigateTo(AppScreen.rentalInformation),
            onSave: (data) async {
              // Save to Supabase
              await TenantAuthService().saveTenantPersonalInfo(
                idCard: data['idCard'] ?? '',
                birthdate: data['birthdate'] ?? '',
                gender: data['gender'] ?? '',
                address: data['address'] ?? '',
                emergencyContact: data['emergencyContact'] ?? '',
                emergencyPhone: data['emergencyPhone'] ?? '',
                name: data['name'],
                phone: data['phone'],
                documents: data['documents'],
              );

              setState(() {
                // รวมข้อมูลที่แก้ไขเข้ากับข้อมูลเดิม (ไม่ทับข้อมูลห้อง/ค่าเช่าที่แอดมินกรอกไว้)
                _rentalInfo = {...?_rentalInfo, ...data};
                _rentalInfoKey++;
                _justSavedRental = true;
                if ((data['name'] ?? '').isNotEmpty) {
                  _userName = data['name']!;
                }
                if ((data['phone'] ?? '').isNotEmpty) {
                  _userPhoneNumber = data['phone']!;
                }
              });
              _navigateTo(AppScreen.rentalInformation);
            },
            onNavigateToMap: () => _navigateTo(AppScreen.map),
            userName: _userName,
            userPhone: _userPhoneNumber,
            avatarUrl: _avatarUrl,
            onAvatarChanged: (url) {
              setState(() {
                _avatarUrl = url;
              });
            },
          ),
          TermsOfUseScreen(onBack: () => _navigateTo(AppScreen.profile)),
          MapScreen(
            onBack: () => _navigateTo(AppScreen.editeRentalInformation),
            onSelectAddress: (address) {
              setState(() {
                _rentalInfo = {..._rentalInfo, 'address': address};
                _rentalInfoKey++;
              });
              _navigateTo(AppScreen.editeRentalInformation);
            },
          ),
          ContactUsScreen(onBack: () => _navigateTo(AppScreen.profile)),
          RoomMembersScreen(
            key: _roomMembersKey,
            isRoommate: _isRoommate,
            onBack: () => _navigateTo(AppScreen.profile),
            onNavigateToInvitationCode: () {
              // หน้ารหัสเชิญอยู่ใน IndexedStack → ต้องสั่งโหลดใหม่เอง
              // ไม่งั้นจะค้างสถานะจากตอนแอปเริ่มทำงาน
              _invitationCodeKey.currentState?.reload();
              _navigateTo(AppScreen.invitationCode);
            },
          ),
          InvitationCodeScreen(
            key: _invitationCodeKey,
            onBack: () => _navigateTo(AppScreen.roomMembers),
          ),
          LeaveTheRoomScreen(
            isRoommate: _isRoommate,
            onBack: () => _navigateTo(AppScreen.profile),
            onConfirmLeave: () {
              // Roommate ออกจากหอพัก (ออกทันที) → clear state ตรงๆ
              setState(() {
                _isRoommate = false;
                _tenantRoom = {};
                _rentalInfo = {};
              });
              _navigateTo(AppScreen.profile);
            },
            onRequestLeave: () {
              // ผู้เช่าหลักส่งคำขอออกจากหอพัก → ไปหน้ารอแอดมินอนุมัติ
              setState(() {
                _pendingRequestType = PendingRequestType.leave;
                _pendingTransferSeq++;
              });
              _navigateTo(AppScreen.pendingRoomTransfer);
            },
          ),
          ParticipateScreen(
            onBack: () => _navigateTo(AppScreen.profile),
            onJoinWithCode: () => _navigateTo(AppScreen.joinTheRoom),
            onRegisterAsTenant: () {
              setState(() {
                _previousScreen = AppScreen.participate;
                _currentScreen = AppScreen.applicationProcess;
              });
            },
          ),
          JoinTheRoomScreen(
            onBack: () => _navigateTo(AppScreen.participate),
            onJoined: () {
              // ส่งคำขอเข้าร่วมห้องสำเร็จ → ไปหน้ารอแอดมินอนุมัติ
              setState(() {
                _pendingRequestType = PendingRequestType.roommateJoin;
                _pendingTransferSeq++;
              });
              _navigateTo(AppScreen.pendingRoomTransfer);
            },
            userName: _userName,
            userPhone: _userPhoneNumber,
          ),
          CloseAccountScreen(
            onBack: () => _navigateTo(AppScreen.profile),
            onCloseAccount: () async {
              if ((_tenantRoom['room_number']?.toString() ?? '').isNotEmpty) {
                _navigateTo(AppScreen.deletionFailed);
                return;
              }
              final uid = supabase.auth.currentUser?.id;
              if (uid != null) {
                await supabase.from('tenants').delete().eq('id', uid);
              }
              await supabase.auth.signOut();
              setState(() {
                _isRoommate = false;
                _tenantRoom = {};
                _rentalInfo = {};
                _userName = '';
                _userPhoneNumber = '099-9999999';
              });
              _navigateTo(AppScreen.selectUser);
            },
          ),
          Builder(
            builder: (_) => ApplicationProcessScreen(
              onBack: () async {
                await _loadRentalInfo();
                _navigateTo(AppScreen.profile);
              },
              onSubmit: () {
                // bump key ก่อน เพื่อให้ PendingRoomTransferScreen สร้างใหม่
                // (initState รันใหม่ → เริ่ม poll สถานะใหม่ ไม่ค้างค่าเก่า)
                setState(() {
                  _pendingRequestType = PendingRequestType.upgrade;
                  _pendingTransferSeq++;
                });
                _navigateTo(AppScreen.pendingRoomTransfer);
              },
              userName: _userName,
              userPhone: _userPhoneNumber,
            ),
          ),
          PendingRoomTransferScreen(
            key: ValueKey('pendingTransfer_$_pendingTransferSeq'),
            requestType: _pendingRequestType,
            onBack: () => _navigateTo(AppScreen.applicationProcess),
            onApproved: () async {
              await _reloadAfterLogin();
              if (_pendingRequestType == PendingRequestType.leave) {
                // อนุมัติคำขอออกจากหอพักแล้ว → clear state และกลับหน้าโปรไฟล์
                setState(() {
                  _isRoommate = false;
                  _tenantRoom = {};
                  _rentalInfo = {};
                });
                _navigateTo(AppScreen.profile);
              } else {
                _navigateTo(AppScreen.homeUser);
              }
            },
            onRejected: () => _navigateTo(AppScreen.profile),
          ),
          DeletionFailedScreen(
            onBack: () => _navigateTo(AppScreen.closeAccount),
            onContactAdmin: () => _navigateTo(AppScreen.dara),
            onBackToSettings: () => _navigateTo(AppScreen.profile),
          ),
          SignUpUserScreen(
            onBack: () => _navigateTo(AppScreen.selectUser),
            onNavigateToSignIn: () => _navigateTo(AppScreen.signIn),
            isAdmin: true,
            onNavigateToVerify: _navigateToVerify,
            onUserDataChanged: (name, phone) => setState(() {
              _userName = name;
              _userPhoneNumber = phone;
            }),
          ),
          SelectDormitoryScreen(
            onBack: () => _navigateTo(AppScreen.signUpAdmin),
            onCreateDormitory: () => _navigateTo(AppScreen.buildNewDormitory),
            onJoinDormitory: () => _navigateTo(AppScreen.homeUser),
          ),
          DormitorySettingsScreen(
            key: _dormitorySettingsKey,
            onBack: () => _navigateTo(AppScreen.profile),
          ),
          BuildNewDormitoryScreen(
            onBack: () => _navigateTo(AppScreen.selectDormitory),
            onCancel: () => _navigateTo(AppScreen.selectDormitory),
            onSubmit: (data) async {
              await _saveDormitoryAndRooms(data);
              _navigateTo(AppScreen.dashboard);
            },
          ),
          DashboardScreen(
            key: _dashboardKey,
            adminName: _userName.isEmpty ? 'พัชราวรรณ  ศรีบุญ' : _userName,
            avatarUrl: _avatarUrl,
            showRepairBadge: _hasRepairBadge,
            onNavigateToTenant: () => _navigateTo(AppScreen.tenant),
            onNavigateToBill: () => _navigateTo(AppScreen.tenantBill),
            onNavigateToNotification: () => _navigateTo(AppScreen.request),
            onNavigateToAnnounce: () => _navigateTo(AppScreen.announceAdmin),
            onNavigateToReportRepair: () => _navigateTo(AppScreen.reportRepair),
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            stats: _dashboardStats,
            repairRequests: _repairRequests,
          ),
          TenantScreen(
            key: _tenantKey,
            onNavigateToDashboard: () => _navigateTo(AppScreen.dashboard),
            onNavigateToMasterTenant: () {
              // ข้อมูลผู้เช่าที่เลือกถูก set ไว้ใน onTenantSelected แล้ว
              _navigateTo(AppScreen.masterTenant);
            },
            onNavigateToEditeTenant: () => _navigateTo(AppScreen.editeTenant),
            onNavigateToReportRepair: () => _navigateTo(AppScreen.reportRepair),
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            onNavigateToBill: () => _navigateTo(AppScreen.tenantBill),
            onNavigateToAnnounce: () => _navigateTo(AppScreen.announceAdmin),
            tenants: _tenantList,
            onTenantSelected: (tenant, index) {
              _selectedTenantIndex = index;
              _selectedTenantData = tenant;
              _selectedMemberId = tenant['member_id'];
              _tenantStatuses[index] = tenant['status'] ?? 'กำลังเช่า';
            },
          ),
          MasterTenantScreen(
            key: _masterTenantKey,
            onBack: () => _navigateTo(AppScreen.tenant),
            onEdit: () => _navigateTo(AppScreen.editeTenant),
            onDelete: () => _navigateTo(AppScreen.tenant),
            tenantData: _selectedTenantData.isNotEmpty
                ? _selectedTenantData
                : null,
            memberId: _selectedMemberId,
            currentStatus: _tenantStatuses[_selectedTenantIndex] ?? 'กำลังเช่า',
            onRefresh: () {
              setState(() {});
            },
          ),
          EditeTenantScreen(
            key: _editeTenantKey,
            onBack: () => _navigateTo(AppScreen.masterTenant),
            onSave: () => _navigateTo(AppScreen.masterTenant),
            currentStatus: _tenantStatuses[_selectedTenantIndex] ?? 'กำลังเช่า',
            memberId: _selectedMemberId,
            onRentalSaved: () {
              setState(() {});
            },
            onStatusSaved: (status) {
              setState(() {
                _tenantStatuses[_selectedTenantIndex] = status;
                // อัปเดตรายการที่เลือกจริง (จับคู่ด้วย member_id ไม่ใช่ index
                // เพราะรายการหน้าผู้เช่ามีทั้งผู้เช่าหลักและ Roommate)
                final memberId = _selectedTenantData['member_id'];
                if (memberId != null && memberId.isNotEmpty) {
                  _tenantList = _tenantList
                      .map((t) => t['member_id'] == memberId
                          ? (Map<String, String>.from(t)..['status'] = status)
                          : t)
                      .toList();
                }
              });
            },
          ),
          NotificationScreen(
            onBack: () => _navigateTo(AppScreen.profile),
            isTenant: !_isAdmin,
          ),
          DormitoryRequestScreen(
            key: _dormitoryRequestKey,
            requestId: _selectedDormRequestId,
            onBack: () => _navigateTo(AppScreen.request),
            onApprove: () => _requestKey.currentState?.refresh(),
            onReject: () => _requestKey.currentState?.refresh(),
          ),
          ReportARepairScreen(
            key: _reportRepairKey,
            onNavigateToDashboard: () => _navigateTo(AppScreen.dashboard),
            onNavigateToTenant: () => _navigateTo(AppScreen.tenant),
            onOpenChat: _openAdminChat,
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            onNavigateToBill: () => _navigateTo(AppScreen.tenantBill),
            onNavigateToAnnounce: () => _navigateTo(AppScreen.announceAdmin),
          ),
          ChatAdminScreen(
            key: ValueKey('chatAdmin_${_chatRepairId ?? ''}'),
            onBack: () => _navigateTo(AppScreen.reportRepair),
            repairId: _chatRepairId,
            tenantName: _chatRepairInfo['tenantName']?.toString() ?? 'ผู้เช่า',
            roomNumber: _chatRepairInfo['roomNumber']?.toString() ?? '-',
            jobId: _chatRepairInfo['jobId']?.toString() ?? '',
            status: _chatRepairInfo['status']?.toString() ?? 'new',
          ),
          TenantBillScreen(
            key: _tenantBillKey,
            showRepairBadge: _hasRepairBadge,
            onBack: () => _navigateTo(AppScreen.dashboard),
            onNavigateToDashboard: () => _navigateTo(AppScreen.dashboard),
            onNavigateToTenant: () => _navigateTo(AppScreen.tenant),
            onNavigateToReportRepair: () => _navigateTo(AppScreen.reportRepair),
            onNavigateToAnnouncement: () =>
                _navigateTo(AppScreen.announceAdmin),
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            onCreateBill: () {
              setState(() {
                _selectedTenantData = {};
                _buildBillKey++; // ล้างฟอร์มสร้างบิล ทุกครั้งที่เริ่มใหม่
              });
              _navigateTo(AppScreen.buildTenantBill);
            },
            onTapBill: (bill) {
              setState(() {
                _selectedBill = bill;
                _selectedBillTenant = bill['tenantName'] ?? '';
                _selectedBillRoom = bill['room'] ?? '';
                _previousScreen = AppScreen.tenantBill;
                _currentScreen = AppScreen.billDetails;
              });
            },
            onApproveBill: (billId) async {
              final ok = await mockService.updateBillStatus(billId, 'paid');
              if (!mounted) return;
              if (ok) {
                final bills = await mockService.getBills(
                  dormitoryId: _dormitoryId,
                );
                final stats = await mockService.getBillStats(
                  dormitoryId: _dormitoryId,
                );
                final current = await mockService.getCurrentBill();
                setState(() {
                  _bills = bills;
                  _billStats = stats;
                  _currentBill = current;
                });
              }
            },
            tenants: _tenantList,
            currentBill: _currentBill,
            bills: _bills,
            billStats: _billStats,
          ),
          RequestScreen(
            key: _requestKey,
            onBack: () => _navigateTo(AppScreen.dashboard),
            onNavigateToDormitoryRequest: (requestId) {
              setState(() => _selectedDormRequestId = requestId);
              _navigateTo(AppScreen.dormitoryRequest);
            },
          ),
          // announceAdmin (index 51)
          AnnounceScreen(
            key: ValueKey('announceAdmin_$_announceReloadSeq'),
            onNavigateToHome: () => _navigateTo(AppScreen.dashboard),
            onNavigateToTenant: () => _navigateTo(AppScreen.tenant),
            onNavigateToRentalFee: () => _navigateTo(AppScreen.tenantBill),
            onNavigateToReportRepair: () => _navigateTo(AppScreen.reportRepair),
            onNavigateToChat: () => _navigateTo(AppScreen.reportRepair),
            onNavigateToDetails: (item) {
              setState(() {
                _selectedAnnouncement = item;
                _selectedAnnouncementImage = item['image'] ?? '';
                _isAdminAnnounceDetails = true;
              });
              _navigateTo(AppScreen.announceDetails);
            },
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            isAdmin: true,
            onAddAnnouncement: () {
              // เพิ่มประกาศใหม่ → ล้างข้อมูลแก้ไขเดิม
              setState(() {
                _editingAnnouncementId = null;
                _editingInitialData = null;
                _editAnnounceSeq++;
              });
              _navigateTo(AppScreen.editeAnnounce);
            },
          ),
          // editeAnnounce (index 52)
          EditeAnnounceScreen(
            key: ValueKey('editeAnnounce_${_announceReloadSeq}_$_editAnnounceSeq'),
            announcementId: _editingAnnouncementId,
            initialData: _editingInitialData,
            onBack: () => _navigateTo(AppScreen.announceDetails),
            onSave: () {
              setState(() => _announceReloadSeq++); // reload announce admin
              _navigateTo(AppScreen.announceAdmin);
            },
          ),
          // buildTenantBill
          BuildTenantBillScreen(
            key: ValueKey('build_bill_$_buildBillKey'),
            onBack: () => _navigateTo(AppScreen.tenantBill),
            onSave: () async {
              // รีโหลดบิลจริงหลังส่งบิลสำเร็จ แล้วกลับหน้ารายการบิล
              final bills = await mockService.getBills(
                dormitoryId: _dormitoryId,
              );
              final stats = await mockService.getBillStats(
                dormitoryId: _dormitoryId,
              );
              final current = await mockService.getCurrentBill();
              if (!mounted) return;
              setState(() {
                _bills = bills;
                _billStats = stats;
                _currentBill = current;
              });
              _navigateTo(AppScreen.tenantBill);
            },
            onApproveBill: (billId) async {
              final ok = await mockService.updateBillStatus(billId, 'paid');
              if (!mounted) return;
              if (ok) {
                final bills = await mockService.getBills(
                  dormitoryId: _dormitoryId,
                );
                final stats = await mockService.getBillStats(
                  dormitoryId: _dormitoryId,
                );
                final current = await mockService.getCurrentBill();
                setState(() {
                  _bills = bills;
                  _billStats = stats;
                  _currentBill = current;
                });
              }
            },
            initialData: _selectedTenantData.isNotEmpty
                ? _selectedTenantData
                : null,
            bills: _bills,
          ),
          // ── Tenant Google Sign Up (index 53) ──
          TenantGoogleSignupScreen(
            onBack: () => _navigateTo(AppScreen.selectUser),
            onRequestSent: _handleTenantSignUpDone,
            onNavigateToSignIn: () => _navigateTo(AppScreen.signIn),
          ),
          // ── Tenant Dashboard (index 53) ──
          TenantDashboardScreen(),
          // ── ลืมรหัสผ่าน (forgotPassword) ──
          ForgotPasswordScreen(
            onBack: () => _navigateTo(_forgotPasswordBackTo ?? AppScreen.signIn),
            onSuccess: () => _navigateTo(AppScreen.signIn),
          ),
        ],
      ),
    );
  }
}
