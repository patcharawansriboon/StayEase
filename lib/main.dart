import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'services/auth_service.dart';
import 'services/mock_service.dart';
import 'services/tenant_auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user/onboarding_screen.dart';
import 'user/select_user.dart';
import 'user/sign_up_user.dart';
import 'user/verify_number.dart';
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
import 'profile.dart';
import 'user/change_number.dart';
import 'user/change_number_otp.dart';
import 'user/confirm_change_number.dart';
import 'user/privacy_policy.dart';
import 'user/change_password.dart';
import 'user/confirm_change_password.dart';
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
        textTheme: GoogleFonts.promptTextTheme(),
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
}

class AppScreenManager extends StatefulWidget {
  const AppScreenManager({super.key});

  @override
  State<AppScreenManager> createState() => _AppScreenManagerState();
}

class _AppScreenManagerState extends State<AppScreenManager> {
  AppScreen _currentScreen = AppScreen.onboarding;
  int _onboardingPage = 0;
  String _verifyPhoneNumber = '';
  String _userPhoneNumber = '099-9999999';
  String _userName = '';
  int _changeNumberFlowKey = 0; // increment เพื่อ reset flow
  int _changePasswordFlowKey = 0;
  int _rentalInfoKey = 0; // increment เมื่อ save ข้อมูลการเช่า
  bool _justSavedRental = false; // true หลังกดบันทึกข้อมูลการเช่า
  bool _justSavedProfile = false; // true หลังยืนยันเปลี่ยนเบอร์/รหัสผ่าน
  bool _forgotPasswordFlow = false; // true = มาจาก ลืมรหัสผ่าน
  bool _isRoommate = false; // true = สมัครด้วยรหัสคำเชิญ
  bool _isAdmin = false; // true = ผู้ดูแล
  Map<String, String> _rentalInfo = {}; // ข้อมูลการเช่าที่บันทึก

  Future<void> _loadRentalInfo() async {
    final info = await TenantAuthService().getTenantRentalInfo();
    if (info != null) {
      setState(() {
        _rentalInfo = info;
      });
    }
  }
  AppScreen _previousScreen = AppScreen.homeUser; // หน้าก่อนหน้าสำหรับ back
  String _selectedAnnouncementImage = 'assets/images/announcement_1.png';
  Map<String, String> _selectedAnnouncement = {}; // ประกาศที่เลือกดูรายละเอียด
  bool _isAdminAnnounceDetails = false; // true = เปิด details จากฝั่ง admin
  String? _dormitoryId; // admin's dormitory id
  final _requestKey = GlobalKey<RequestScreenState>();
  final _dormitoryRequestKey =
      GlobalKey<DormitoryRequestScreenState>();
  final _invitationCodeKey = GlobalKey<InvitationCodeScreenState>();
  final _roomMembersKey = GlobalKey<RoomMembersScreenState>();
  String? _selectedDormRequestId;
  String? _tenantUserId;
  int _announceReloadSeq = 0; // เพิ่มเพื่อ reload หน้า announce admin

  // ── Mock/Supabase data ────────────────────────────────────
  Map<String, dynamic> _currentBill = {};
  Map<String, int> _dashboardStats = {};
  List<Map<String, String>> _tenantList = [];
  List<Map<String, dynamic>> _bills = [];
  Map<String, int> _billStats = {};
  Map<int, String> _tenantStatuses = {};
  Map<String, String> _selectedTenantData = {};
  String? _selectedMemberId;

  /// เพิ่มทุกครั้งที่ผู้เช่าเข้าสู่ขั้นตอน "รอผลอนุมัติ" ใหม่
  /// ใช้เป็น key ของ SendRequestScreen เพราะทั้งหมดอยู่ใน IndexedStack
  /// (ถ้าไม่เปลี่ยน key หน้าจอจะเก็บสถานะเก่าไว้ เช่น rejected ค้างแม้สมัครใหม่)
  int _sendRequestSeq = 0;
  int _selectedTenantIndex = -1;
  List<Map<String, String>> _repairRequests = [];
  List<Map<String, String>> _announcements = [];
  Map<String, dynamic> _tenantRoom = {};
  Map<String, dynamic> _selectedBill = {};
  String _selectedBillTenant = '';
  String _selectedBillRoom = '';

  @override
  void initState() {
    super.initState();
    _loadMockData();
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
      _currentBill     = results[0] as Map<String, dynamic>;
      _dashboardStats  = results[1] as Map<String, int>;
      _tenantRoom      = results[2] as Map<String, dynamic>;
      _repairRequests  = results[3] as List<Map<String, String>>;
      _tenantList      = results[4] as List<Map<String, String>>;
      _announcements   = results[5] as List<Map<String, String>>;
      _bills           = results[6] as List<Map<String, dynamic>>;
      _billStats       = results[7] as Map<String, int>;
    });
  }

  // เรียกหลัง login เพื่อโหลดข้อมูล user + bill ใหม่
  Future<void> _reloadAfterLogin() async {
    final user = await mockService.getCurrentUser();
    final room = await mockService.getTenantRoom();
    final bill = await mockService.getCurrentBill();
    final isRoommate = await mockService.isCurrentUserRoommate();
    if (!mounted) return;
    setState(() {
      if (_userName.isEmpty) _userName = user['full_name'] ?? '';
      if (_userPhoneNumber == '099-9999999') _userPhoneNumber = user['phone'] ?? '';
      _tenantRoom  = room;
      _currentBill = bill;
      _isRoommate  = isRoommate;
    });
    // โหลด rental info (ห้อง/อาคาร/ชั้น) หลัง login
    await _loadRentalInfo();
  }

  Future<void> _saveDormitoryAndRooms(Map<String, dynamic> data) async {
    final totalRooms    = data['totalRooms'] as int;
    final roomArrangement = data['roomArrangement'] as String;

    // ── ตั้งค่า stats ทันทีจากข้อมูลที่กรอก (ไม่รอ Supabase) ──
    setState(() {
      _dashboardStats = {
        'total_tenants':   0,
        'total_rooms':     totalRooms,
        'vacant_rooms':    roomArrangement == 'empty' ? totalRooms : 0,
        'repair_requests': 0,
      };
    });

    // ── บันทึกลง Supabase ────────────────────────────────────
    final db  = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;

    try {
      // 1. Insert dormitory
      final dormitoryRes = await db.from('dormitories').insert({
        'dorm_code':        data['dorm_code'],
        'name':             data['name'],
        'dorm_name':        data['name'],
        'address':          data['address'],
        'phone':            int.tryParse(data['phone']?.toString() ?? ''),
        'floor_count':      data['floorCount'],
        'total_rooms':      data['totalRooms'],
        'room_format':      data['roomNumberFormat'],
        'max_tenants':      data['maxTenants'],
        'room_arrangement': data['roomArrangement'],
        'created_by':       uid,
        'created_at':       DateTime.now().toIso8601String(),
      }).select('id').single();

      final dormitoryId = dormitoryRes['id'];
      _dormitoryId = dormitoryId;

      // 2. Generate and insert rooms
      final floorCount       = data['floorCount'] as int;
      final roomNumberFormat = data['roomNumberFormat'] as String;
      final maxTenants       = data['maxTenants'] as int;

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
            final toStr   = parts[1].trim();
            final prefixMatch = RegExp(r'^(.*?)(\d+)$').firstMatch(fromStr);
            final prefix  = prefixMatch?.group(1) ?? '';
            final from    = int.tryParse(prefixMatch?.group(2) ?? '') ?? 1;
            final toNum   = int.tryParse(RegExp(r'(\d+)$').firstMatch(toStr)?.group(1) ?? '') ?? from;
            for (int num = from; num <= toNum; num++) {
              roomsToInsert.add({
                'id':           _generateUuid(),
                'dormitory_id': dormitoryId,
                'room_number':  '$prefix$num',
                'floor':        floorNum,
                'building':     prefix.isNotEmpty ? prefix : 'A',
                'max_tenants':  maxTenants,
                'status':       roomArrangement == 'empty' ? 'vacant' : 'occupied',
                'created_at':   DateTime.now().toIso8601String(),
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
              final floorAwareMatch =
                  RegExp(r'^(.*?)([1-9])(\d{2,})$').firstMatch(format);
              final prefixStr    = floorAwareMatch?.group(1) ?? '';
              final floorDigitVal = int.tryParse(floorAwareMatch?.group(2) ?? '');
              final roomSuffix   = floorAwareMatch?.group(3);

              if (floorAwareMatch != null && floorDigitVal == 1 && floorCount > 1) {
                final roomPad = roomSuffix!.length;
                roomNumber = '$prefixStr$floor${i.toString().padLeft(roomPad, '0')}';
              } else {
                final simpleMatch = RegExp(r'(\d+)\s*$').firstMatch(format);
                if (simpleMatch == null) {
                  roomNumber = '$format$roomIndex';
                } else {
                  final digits = simpleMatch.group(1) ?? '';
                  final start  = int.tryParse(digits) ?? 1;
                  final seq    = start + roomIndex - 1;
                  roomNumber =
                      '${format.substring(0, simpleMatch.start)}${seq.toString().padLeft(digits.length, '0')}';
                }
              }
            }

            roomsToInsert.add({
              'id':           _generateUuid(),
              'dormitory_id': dormitoryId,
              'room_number':  roomNumber,
              'floor':        floor,
              'building':     roomNumberFormat.isNotEmpty ? roomNumberFormat[0] : 'A',
              'max_tenants':  maxTenants,
              'status':       roomArrangement == 'empty' ? 'vacant' : 'occupied',
              'created_at':   DateTime.now().toIso8601String(),
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
    setState(() {
      _currentScreen = screen;
      // หน้าที่ใช้ร่วมกันทั้ง admin/user (profile, request, notification,
      // reportRepair ฯลฯ) ให้คงค่า _isAdmin เดิมไว้ ไม่คำนวณใหม่
      const sharedScreens = {
        AppScreen.profile,
        AppScreen.request,
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
      };

      if (!sharedScreens.contains(screen)) {
        _isAdmin = screen == AppScreen.dashboard ||
            screen == AppScreen.tenantBill ||
            screen == AppScreen.billDetails ||
            screen == AppScreen.buildNewDormitory ||
            screen == AppScreen.selectDormitory;
        if (screen == AppScreen.selectUser || screen == AppScreen.signIn) {
          _isAdmin = false;
        }
      }
      if (screen == AppScreen.onboarding) {
        _onboardingPage = 0;
      }
    });

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

  void _navigateToVerify(String phoneNumber) {
    // บันทึก uid ผู้เช่าไว้ตอนนี้ เพราะ session ปัจจุบันคือผู้เช่าที่เพิ่งสมัคร
    _tenantUserId = supabase.auth.currentUser?.id;
    _sendRequestSeq++;
    setState(() {
      _currentScreen = AppScreen.verifyNumber;
      _verifyPhoneNumber = phoneNumber;
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
            onBack: () => _navigateTo(AppScreen.signUp),
            onVerified: () => _navigateTo(AppScreen.sendRequest),
            phoneNumber: _verifyPhoneNumber,
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
            },
            onNavigateToPayment: () {
              setState(() {
                _previousScreen = AppScreen.homeUser;
                _currentScreen = AppScreen.payment;
              });
            },
            onNavigateToChat: () => _navigateTo(AppScreen.chat),
            onNavigateToAnnounce: () => _navigateTo(AppScreen.announce),
            onNavigateToRepairDetail: () => _navigateTo(AppScreen.chat),
            onNavigateToAnnounceDetails: (imagePath) {
              setState(() => _selectedAnnouncementImage = imagePath);
              _navigateTo(AppScreen.announceDetails);
            },
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            isRoommate: _isRoommate,
            hasRoom: (_tenantRoom['room_number']?.toString() ?? '').isNotEmpty,
            userName: _userName,
            userPhone: _userPhoneNumber,
            roomNumber: _tenantRoom['room_number']?.toString() ?? '',
            currentBill: _currentBill,
            announcements: _announcements,
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
          ),
          RentalFeeScreen(
            onNavigateToHome: () => _navigateTo(AppScreen.homeUser),
            onNavigateToRentalFee: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToBill: () {
              setState(() {
                _previousScreen = AppScreen.rentalFee;
                _currentScreen = AppScreen.bill;
              });
            },
            onNavigateToPayment: () {
              setState(() {
                _previousScreen = AppScreen.rentalFee;
                _currentScreen = AppScreen.payment;
              });
            },
            onNavigateToPaymentHistory: () =>
                _navigateTo(AppScreen.paymentHistory),
            onNavigateToChat: () => _navigateTo(AppScreen.chat),
            onNavigateToAnnounce: () => _navigateTo(AppScreen.announce),
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            currentBill: _currentBill,
            hasRoom: (_tenantRoom['room_number']?.toString() ?? '').isNotEmpty,
          ),
            Builder(
              builder: (_) => BillScreen(
                onBack: () => _navigateTo(_previousScreen),
                onNavigateToPayment: () {
                  setState(() {
                    _previousScreen = AppScreen.bill;
                    _currentScreen = AppScreen.payment;
                  });
                },
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
            builder: (_) =>
                PaymentScreen(onBack: () => _navigateTo(_previousScreen)),
          ),
          PaymentHistoryScreen(
            onBack: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToHome: () => _navigateTo(AppScreen.homeUser),
            onNavigateToRentalFee: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToBill: () => _navigateTo(AppScreen.bill),
            onNavigateToBillHistory: () => _navigateTo(AppScreen.billHistory),
          ),
          BillHistoryScreen(
            onBack: () => _navigateTo(AppScreen.paymentHistory),
            onNavigateToHome: () => _navigateTo(AppScreen.homeUser),
            onNavigateToRentalFee: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToChat: () => _navigateTo(AppScreen.chat),
            onNavigateToAnnounce: () => _navigateTo(AppScreen.announce),
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
          ),
          ChatScreen(onBack: () => _navigateTo(AppScreen.homeUser)),
          AnnounceScreen(
            key: ValueKey('announce_$_announceReloadSeq'),
            onNavigateToHome: () => _navigateTo(AppScreen.homeUser),
            onNavigateToRentalFee: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToChat: () => _navigateTo(AppScreen.chat),
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
              isAdmin: _isAdminAnnounceDetails,
              announcementId: _selectedAnnouncement['id'] ?? '',
              onEdit: () {
                // Reload announcements after edit
                setState(() => _announceReloadSeq++);
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
          ProfileScreen(
            showSavedToast: _justSavedProfile,
            onToastShown: () => _justSavedProfile = false,
            onNavigateToDashboard: () => _navigateTo(AppScreen.dashboard),
            onNavigateToHome: () => _navigateTo(AppScreen.homeUser),
            onNavigateToRentalFee: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToChat: () => _navigateTo(AppScreen.chat),
            onNavigateToAnnounce: () => _navigateTo(AppScreen.announce),
            onLogout: () => _navigateTo(AppScreen.selectUser),
            onNavigateToChangeNumber: () => _navigateTo(AppScreen.changeNumber),
            onNavigateToPrivacyPolicy: () =>
                _navigateTo(AppScreen.privacyPolicy),
            onNavigateToChangePassword: () =>
                _navigateTo(AppScreen.changePassword),
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
            phoneNumber: _userPhoneNumber,
            isRoommate: _isRoommate,
            isAdmin: _isAdmin,
            hasRoom: (_tenantRoom['room_number']?.toString() ?? '').isNotEmpty,
            userName: _userName,
            roomNumber: _tenantRoom['room_number']?.toString() ?? '',
            onNavigateToTenant: () => _navigateTo(AppScreen.tenant),
            onNavigateToReportRepair: () => _navigateTo(AppScreen.reportRepair),
            onNavigateToNotification: () => _navigateTo(AppScreen.request),
            onNavigateToAdminBill: () => _navigateTo(AppScreen.tenantBill),
            onNavigateToAdminAnnounce: () => _navigateTo(AppScreen.announceAdmin),
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
            onContinue: () => _navigateTo(AppScreen.confirmChangePassword),
            onForgotPassword: () {
              setState(() => _forgotPasswordFlow = true);
              _navigateTo(AppScreen.changeNumber);
            },
          ),
          ConfirmChangePasswordScreen(
            key: ValueKey('confirmpw_$_changePasswordFlowKey'),
            onBack: () => _navigateTo(AppScreen.changePassword),
            onSave: () {
              setState(() {
                _changePasswordFlowKey++;
                _justSavedProfile = true;
              });
              _navigateTo(AppScreen.profile);
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
                documents: data['documents'],
              );

              setState(() {
                _rentalInfo = data;
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
            onBack: () => _navigateTo(AppScreen.profile),
            onConfirmLeave: () {
              // leave แล้ว clear state ตรงๆ (ไม่ reload เพราะ record ถูกลบแล้ว)
              setState(() {
                _isRoommate = false;
                _tenantRoom = {};
                _rentalInfo = {};
              });
              _navigateTo(AppScreen.profile);
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
            onJoin: () => _navigateTo(AppScreen.homeUser),
          ),
          CloseAccountScreen(
            onBack: () => _navigateTo(AppScreen.profile),
            onCloseAccount: () => _navigateTo(AppScreen.deletionFailed),
          ),
Builder(
            builder: (_) => ApplicationProcessScreen(
            onBack: () async {
              await _loadRentalInfo();
              _navigateTo(AppScreen.profile);
            },
            onSubmit: () {
              _navigateTo(AppScreen.pendingRoomTransfer);
            },
            userName: _userName,
            userPhone: _userPhoneNumber,
            ),
          ),
          PendingRoomTransferScreen(
            onBack: () => _navigateTo(AppScreen.applicationProcess),
            onApproved: () async {
              await _reloadAfterLogin();
              _navigateTo(AppScreen.homeUser);
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
            onSignUpAdmin: (name, phone) {
              setState(() {
                _userName = name;
                _userPhoneNumber = phone;
              });
              _navigateTo(AppScreen.selectDormitory);
            },
          ),
          SelectDormitoryScreen(
            onBack: () => _navigateTo(AppScreen.signUpAdmin),
            onCreateDormitory: () => _navigateTo(AppScreen.buildNewDormitory),
            onJoinDormitory: () => _navigateTo(AppScreen.homeUser),
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
            adminName: _userName.isEmpty ? 'พัชราวรรณ  ศรีบุญ' : _userName,
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
        onNavigateToDashboard: () => _navigateTo(AppScreen.dashboard),
        onNavigateToMasterTenant: () {
          if (_selectedTenantIndex >= 0) {
            _selectedTenantData = _tenantList[_selectedTenantIndex];
          }
          _navigateTo(AppScreen.masterTenant);
        },
        onNavigateToEditeTenant: () => _navigateTo(AppScreen.editeTenant),
        onNavigateToReportRepair: () => _navigateTo(AppScreen.reportRepair),
        onNavigateToProfile: () => _navigateTo(AppScreen.profile),
        onNavigateToBill: () => _navigateTo(AppScreen.tenantBill),
        onNavigateToAnnounce: () => _navigateTo(AppScreen.announceAdmin),
        tenants: _tenantList,
        selectedTenantIndex: (index) {
          _selectedTenantIndex = index;
          if (index >= 0 && index < _tenantList.length) {
            _selectedTenantData = _tenantList[index];
            _selectedMemberId = _tenantList[index]['member_id'];
            _tenantStatuses[index] = _tenantList[index]['status'] ?? 'กำลังเช่า';
          }
        },
        onTenantSelected: () {},
          ),
          MasterTenantScreen(
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
                if (_selectedTenantIndex >= 0 && _selectedTenantIndex < _tenantList.length) {
                  _tenantList = List.from(_tenantList);
                  _tenantList[_selectedTenantIndex] = Map.from(_tenantList[_selectedTenantIndex])
                    ..['status'] = status;
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
            onNavigateToDashboard: () => _navigateTo(AppScreen.dashboard),
            onNavigateToTenant: () => _navigateTo(AppScreen.tenant),
            onNavigateToChatAdmin: () => _navigateTo(AppScreen.chatAdmin),
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            onNavigateToBill: () => _navigateTo(AppScreen.tenantBill),
            onNavigateToAnnounce: () => _navigateTo(AppScreen.announceAdmin),
          ),
          ChatAdminScreen(
            onBack: () => _navigateTo(AppScreen.reportRepair),
          ),
          TenantBillScreen(
            onBack: () => _navigateTo(AppScreen.dashboard),
            onNavigateToDashboard: () => _navigateTo(AppScreen.dashboard),
            onNavigateToTenant: () => _navigateTo(AppScreen.tenant),
            onNavigateToReportRepair: () => _navigateTo(AppScreen.reportRepair),
            onNavigateToAnnouncement: () => _navigateTo(AppScreen.announceAdmin),
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            onCreateBill: () => _navigateTo(AppScreen.buildTenantBill),
            onTapBill: (bill) {
              setState(() {
                _selectedBill = bill;
                _selectedBillTenant = bill['tenantName'] ?? '';
                _selectedBillRoom = bill['room'] ?? '';
                _previousScreen = AppScreen.tenantBill;
                _currentScreen = AppScreen.billDetails;
              });
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
            onNavigateToChat: () => _navigateTo(AppScreen.chatAdmin),
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
            onAddAnnouncement: () => _navigateTo(AppScreen.editeAnnounce),
          ),
          // editeAnnounce (index 52)
          EditeAnnounceScreen(
            onBack: () => _navigateTo(AppScreen.announceAdmin),
            onSave: () {
              setState(() => _announceReloadSeq++); // reload announce admin
              _navigateTo(AppScreen.announceAdmin);
            },
          ),
          // buildTenantBill
          BuildTenantBillScreen(
            onBack: () => _navigateTo(AppScreen.tenantBill),
            onSave: () async {
              // รีโหลดบิลจริงหลังส่งบิลสำเร็จ แล้วกลับหน้ารายการบิล
              final bills = await mockService.getBills(dormitoryId: _dormitoryId);
              final stats =
                  await mockService.getBillStats(dormitoryId: _dormitoryId);
              if (!mounted) return;
              setState(() {
                _bills = bills;
                _billStats = stats;
              });
              _navigateTo(AppScreen.tenantBill);
            },
            initialData: _selectedTenantData.isNotEmpty ? _selectedTenantData : null,
          ),
          // ── Tenant Google Sign Up (index 53) ──
          TenantGoogleSignupScreen(
            onBack: () => _navigateTo(AppScreen.selectUser),
            onRequestSent: _handleTenantSignUpDone,
            onNavigateToSignIn: () => _navigateTo(AppScreen.signIn),
          ),
          // ── Tenant Dashboard (index 53) ──
          TenantDashboardScreen(),
        ],
      ),
    );
  }
}