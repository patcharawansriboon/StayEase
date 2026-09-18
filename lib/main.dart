import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'services/mock_service.dart';
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
import 'user/apply_tenant.dart';
import 'user/application_process.dart';
import 'sign_up_admin.dart';
import 'select_dormitory.dart';
import 'build_new_dormitory.dart';
import 'Dashboard.dart';
import 'tenant_bill.dart';
import 'tenant.dart';
import 'master_tenant.dart';
import 'edite_tenant.dart';
import 'notification.dart';
import 'request.dart' as request;
import 'dormitory_request.dart';
import 'roommate_request.dart';
import 'request_change_tenant.dart';
import 'report_a_repair.dart';
import 'chat_admin.dart';

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
  applyTenant,
  applicationProcess,
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
  roommateRequest,
  requestChangeTenant,
   reportRepair,
chatAdmin,
    tenantBill,
    request,
    announceAdmin,
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
  AppScreen _previousScreen = AppScreen.homeUser; // หน้าก่อนหน้าสำหรับ back
  String _selectedAnnouncementImage = 'assets/images/announcement_1.png';
  bool _isAdminAnnounceDetails = false; // true = เปิด details จากฝั่ง admin
  String? _dormitoryId; // admin's dormitory id

  // ── Mock/Supabase data ────────────────────────────────────
  Map<String, dynamic> _currentBill = {};
  Map<String, int> _dashboardStats = {};
  List<Map<String, String>> _tenantList = [];
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
    final results = await Future.wait([
      mockService.getCurrentBill(),
      mockService.getDashboardStats(dormitoryId: _dormitoryId),
      mockService.getTenantRoom(),
      mockService.getRepairRequests(dormitoryId: _dormitoryId),
      mockService.getTenantList(dormitoryId: _dormitoryId),
      mockService.getAnnouncements(dormitoryId: _dormitoryId),
    ]);
    if (!mounted) return;
    setState(() {
      _currentBill     = results[0] as Map<String, dynamic>;
      _dashboardStats  = results[1] as Map<String, int>;
      _tenantRoom      = results[2] as Map<String, dynamic>;
      _repairRequests  = results[3] as List<Map<String, String>>;
      _tenantList      = results[4] as List<Map<String, String>>;
      _announcements   = results[5] as List<Map<String, String>>;
    });
  }

  // เรียกหลัง login เพื่อโหลดข้อมูล user + bill ใหม่
  Future<void> _reloadAfterLogin() async {
    final user = await mockService.getCurrentUser();
    final room = await mockService.getTenantRoom();
    final bill = await mockService.getCurrentBill();
    if (!mounted) return;
    setState(() {
      if (_userName.isEmpty) _userName = user['full_name'] ?? '';
      if (_userPhoneNumber == '099-9999999') _userPhoneNumber = user['phone'] ?? '';
      _tenantRoom  = room;
      _currentBill = bill;
    });
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
        'name':       data['name'],
        'address':    data['address'],
        'phone':      data['phone'],
        'owner_id':   uid,
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      final dormitoryId = dormitoryRes['id'];
      _dormitoryId = dormitoryId;

      // 2. Generate and insert rooms
      final floorCount       = data['floorCount'] as int;
      final roomNumberFormat = data['roomNumberFormat'] as String;
      final maxTenants       = data['maxTenants'] as int;

      final roomsPerFloor  = (totalRooms / floorCount).ceil();
      final roomsToInsert  = <Map<String, dynamic>>[];

      for (int floor = 1; floor <= floorCount; floor++) {
        for (int i = 1; i <= roomsPerFloor; i++) {
          final roomIndex = (floor - 1) * roomsPerFloor + i;
          if (roomIndex > totalRooms) break;

          String roomNumber;
          try {
            roomNumber = roomNumberFormat
                .replaceAll('{floor}', floor.toString())
                .replaceAll('{room}',  i.toString().padLeft(2, '0'));
          } catch (_) {
            roomNumber = '$floor${i.toString().padLeft(2, '0')}';
          }

          roomsToInsert.add({
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
      if (screen == AppScreen.dashboard ||
          screen == AppScreen.tenantBill ||
          screen == AppScreen.billDetails ||
          screen == AppScreen.buildNewDormitory ||
          screen == AppScreen.selectDormitory) {
        _isAdmin = true;
      } else if (screen == AppScreen.selectUser || screen == AppScreen.signIn) {
        _isAdmin = false;
      }
      if (screen == AppScreen.onboarding) {
        _onboardingPage = 0;
      }
    });
  }

  void _navigateToVerify(String phoneNumber) {
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
            onTap: () => _navigateTo(AppScreen.alreadyApproved),
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
            userName: _userName,
            userPhone: _userPhoneNumber,
            roomNumber: _tenantRoom['room_number'] ?? 'A303',
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
            onNavigateToHome: () => _navigateTo(AppScreen.homeUser),
            onNavigateToRentalFee: () => _navigateTo(AppScreen.rentalFee),
            onNavigateToChat: () => _navigateTo(AppScreen.chat),
            onNavigateToDetails: (imagePath) {
              setState(() {
                _selectedAnnouncementImage = imagePath;
                _isAdminAnnounceDetails = false;
              });
              _navigateTo(AppScreen.announceDetails);
            },
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            announcements: _announcements,
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
              imagePath: _selectedAnnouncementImage,
              isAdmin: _isAdminAnnounceDetails,
              onEdit: () {},
              onDelete: () {},
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
            onNavigateToRoomMembers: () => _navigateTo(AppScreen.roomMembers),
            onNavigateToCloseAccount: () => _navigateTo(AppScreen.closeAccount),
            onLeaveRoom: () => _navigateTo(AppScreen.leaveTheRoom),
            onUpgradeToTenant: () {
              setState(() {
                _previousScreen = AppScreen.profile;
                _currentScreen = AppScreen.applicationProcess;
              });
            },
            phoneNumber: _userPhoneNumber,
            isRoommate: _isRoommate,
            isAdmin: _isAdmin,
            userName: _userName,
            onNavigateToTenant: () => _navigateTo(AppScreen.tenant),
            onNavigateToReportRepair: () => _navigateTo(AppScreen.reportRepair),
            onNavigateToNotification: () => _navigateTo(AppScreen.notification),
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
            onEdit: () => _navigateTo(AppScreen.editeRentalInformation),
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
            onSave: (data) {
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
            onBack: () => _navigateTo(AppScreen.profile),
            onNavigateToInvitationCode: () =>
                _navigateTo(AppScreen.invitationCode),
          ),
          InvitationCodeScreen(
            onBack: () => _navigateTo(AppScreen.roomMembers),
          ),
          LeaveTheRoomScreen(
            onBack: () => _navigateTo(AppScreen.profile),
            onConfirmLeave: () => _navigateTo(AppScreen.participate),
          ),
          ParticipateScreen(
            onJoinWithCode: () => _navigateTo(AppScreen.joinTheRoom),
            onRegisterAsTenant: () => _navigateTo(AppScreen.applyTenant),
          ),
          JoinTheRoomScreen(
            onBack: () => _navigateTo(AppScreen.participate),
            onJoin: () => _navigateTo(AppScreen.homeUser),
          ),
          CloseAccountScreen(
            onBack: () => _navigateTo(AppScreen.profile),
            onCloseAccount: () => _navigateTo(AppScreen.deletionFailed),
          ),
          ApplyTenantScreen(
            onBack: () => _navigateTo(AppScreen.participate),
            onApply: () {
              setState(() {
                _previousScreen = AppScreen.applyTenant;
                _currentScreen = AppScreen.applicationProcess;
              });
            },
          ),
          Builder(
            builder: (_) => ApplicationProcessScreen(
              onBack: () => _navigateTo(AppScreen.profile),
              onSubmit: () => _navigateTo(AppScreen.homeUser),
              userName: _userName,
              userPhone: _userPhoneNumber,
            ),
          ),
          DeletionFailedScreen(
            onBack: () => _navigateTo(AppScreen.closeAccount),
            onContactAdmin: () => _navigateTo(AppScreen.dara),
            onBackToSettings: () => _navigateTo(AppScreen.profile),
          ),
          SignUpAdminScreen(
            onBack: () => _navigateTo(AppScreen.selectUser),
            onNavigateToSignIn: () => _navigateTo(AppScreen.signIn),
            onSignUp: (name, phone) {
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
            onNavigateToNotification: () => _navigateTo(AppScreen.announceAdmin),
            onNavigateToReportRepair: () => _navigateTo(AppScreen.reportRepair),
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            stats: _dashboardStats,
            repairRequests: _repairRequests,
          ),
          TenantScreen(
            onNavigateToDashboard: () => _navigateTo(AppScreen.dashboard),
            onNavigateToMasterTenant: () => _navigateTo(AppScreen.masterTenant),
            onNavigateToEditeTenant: () => _navigateTo(AppScreen.editeTenant),
            onNavigateToReportRepair: () => _navigateTo(AppScreen.reportRepair),
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            tenants: _tenantList,
          ),
          MasterTenantScreen(
            onBack: () => _navigateTo(AppScreen.tenant),
            onEdit: () => _navigateTo(AppScreen.editeTenant),
            onDelete: () => _navigateTo(AppScreen.tenant),
          ),
          EditeTenantScreen(
            onBack: () => _navigateTo(AppScreen.masterTenant),
            onSave: () => _navigateTo(AppScreen.masterTenant),
          ),
          NotificationScreen(
            onBack: () => _navigateTo(AppScreen.profile),
            isTenant: !_isAdmin,
          ),
          DormitoryRequestScreen(
            onBack: () => _navigateTo(AppScreen.request),
            onApprove: () => _navigateTo(AppScreen.request),
            onReject: () => _navigateTo(AppScreen.request),
          ),
          RoommateRequestScreen(
            onBack: () => _navigateTo(AppScreen.request),
            onApprove: () => _navigateTo(AppScreen.request),
            onReject: () => _navigateTo(AppScreen.request),
          ),
          RequestChangeTenantScreen(
            onBack: () => _navigateTo(AppScreen.request),
            onApprove: () => _navigateTo(AppScreen.request),
            onReject: () => _navigateTo(AppScreen.request),
          ),
          ReportARepairScreen(
            onNavigateToDashboard: () => _navigateTo(AppScreen.dashboard),
            onNavigateToTenant: () => _navigateTo(AppScreen.tenant),
            onNavigateToChatAdmin: () => _navigateTo(AppScreen.chatAdmin),
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
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
          ),
          request.NotificationScreen(
            onBack: () => _navigateTo(AppScreen.dashboard),
            onNavigateToDormitoryRequest:
                () => _navigateTo(AppScreen.dormitoryRequest),
            onNavigateToRoommateRequest:
                () => _navigateTo(AppScreen.roommateRequest),
            onNavigateToRequestChangeTenant:
                () => _navigateTo(AppScreen.requestChangeTenant),
          ),
          AnnounceScreen(
            onNavigateToHome: () => _navigateTo(AppScreen.dashboard),
            onNavigateToRentalFee: () => _navigateTo(AppScreen.tenantBill),
            onNavigateToChat: () => _navigateTo(AppScreen.chatAdmin),
            onNavigateToDetails: (imagePath) {
              setState(() {
                _selectedAnnouncementImage = imagePath;
                _isAdminAnnounceDetails = true;
              });
              _navigateTo(AppScreen.announceDetails);
            },
            onNavigateToProfile: () => _navigateTo(AppScreen.profile),
            announcements: _announcements,
            isAdmin: true,
          ),
        ],
      ),
    );
  }
}
