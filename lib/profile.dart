import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToRentalFee;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToAnnounce;
  final VoidCallback? onLogout;
  final VoidCallback? onNavigateToPrivacyPolicy;
    final VoidCallback? onNavigateToChangePassword;
    final VoidCallback? onNavigateToEditProfile;
    final VoidCallback? onNavigateToDormitory;
  final VoidCallback? onNavigateToRentalInfo;
  final VoidCallback? onNavigateToTermsOfUse;
  final VoidCallback? onNavigateToDara;
  final VoidCallback? onNavigateToRoomMembers;
  final VoidCallback? onNavigateToCloseAccount;
  final VoidCallback? onLeaveRoom;
  final VoidCallback? onUpgradeToTenant;
  final VoidCallback? onNavigateToParticipate;
  final ValueChanged<String>? onAvatarChanged;
  // admin bottom nav
  final VoidCallback? onNavigateToTenant;
  final VoidCallback? onNavigateToReportRepair;
  final VoidCallback? onNavigateToNotification;
  final VoidCallback? onNavigateToAdminBill;
  final VoidCallback? onNavigateToAdminAnnounce;
  final String phoneNumber;
  final bool isRoommate;
  final bool isAdmin;
  final bool hasRoom;
  final String userName;
  final String avatarUrl;
  final bool showSavedToast;
  final VoidCallback? onToastShown;
  final String roomNumber;
  final bool showChatBadge;

  const ProfileScreen({
    super.key,
    this.isRoommate = false,
    this.isAdmin = false,
    this.hasRoom = true,
    this.showSavedToast = false,
    this.onToastShown,
    this.onLeaveRoom,
    this.onUpgradeToTenant,
    this.onNavigateToParticipate,
    this.onAvatarChanged,
    this.onNavigateToTenant,
    this.onNavigateToReportRepair,
    this.onNavigateToNotification,
    this.userName = 'พัชราวรรณ  ศรีบุญ',
    this.avatarUrl = '',
    this.roomNumber = '',
    this.onNavigateToHome,
    this.onNavigateToDashboard,
    this.onNavigateToRentalFee,
    this.onNavigateToChat,
    this.onNavigateToAnnounce,
    this.onLogout,
    this.onNavigateToPrivacyPolicy,
    this.onNavigateToChangePassword,
    this.onNavigateToEditProfile,
    this.onNavigateToDormitory,
    this.onNavigateToRentalInfo,
    this.onNavigateToTermsOfUse,
    this.onNavigateToDara,
    this.onNavigateToRoomMembers,
    this.onNavigateToCloseAccount,
    this.onNavigateToAdminBill,
    this.onNavigateToAdminAnnounce,
    this.phoneNumber = '099-9999999',
    this.showChatBadge = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late int _selectedIndex;
  bool _notificationEnabled = true;
  late String _phoneNumber;
  Uint8List? _profileImageBytes;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
      });
      try {
        final db = Supabase.instance.client;
        final uid = db.auth.currentUser?.id;
        if (uid != null) {
          final ext = picked.path.split('.').last;
          final path =
              'avatars/${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
          await db.storage.from('dormitory-images').uploadBinary(
                path,
                bytes,
                fileOptions: const FileOptions(upsert: true),
              );
           final url = db.storage.from('dormitory-images').getPublicUrl(path);
           widget.onAvatarChanged?.call(url);
          final table = widget.isAdmin
              ? 'admins'
              : (widget.isRoommate ? 'roommate_invites' : 'tenants');
          await db.from(table).update({'avatar_url': url}).eq('id', uid);
        }
      } catch (e) {
        debugPrint('avatar upload error: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _phoneNumber = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    _selectedIndex = widget.isAdmin ? 5 : 4;
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phoneNumber != widget.phoneNumber) {
      setState(() => _phoneNumber = widget.phoneNumber.replaceAll(RegExp(r'\D'), ''));
    }
    // อัปเดต index ของ bottom nav เมื่อสลับระหว่าง admin/user
    if (oldWidget.isAdmin != widget.isAdmin) {
      setState(() => _selectedIndex = widget.isAdmin ? 5 : 4);
    }
    if (!oldWidget.showSavedToast && widget.showSavedToast) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showSavedToast();
        widget.onToastShown?.call();
      });
    }
  }

  void _showSavedToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF4F8FDB).withValues(alpha: 0.8),
        elevation: 2,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Row(
          children: [
            Expanded(
              child: Text(
                'บันทึกเรียบร้อย',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF000000),
                ),
              ),
            ),
            Icon(Icons.check, size: 22, color: Color(0xFF000000)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 16),
                    _buildMenuSection('ข้อมูลส่วนตัว', [
                      _MenuItem(
                        svgIcon: 'assets/images/icon_phone.svg',
                        label: _phoneNumber,
                        showArrow: false,
                      ),
                      _MenuItem(
                        icon: null,
                        label: 'เปลี่ยนรหัสผ่าน',
                        showArrow: true,
                        onTap: widget.onNavigateToChangePassword,
                      ),
                      if (widget.isAdmin)
                        _MenuItem(
                          svgIcon: 'assets/images/icon_house_user.svg',
                          label: 'หอพัก',
                          showArrow: true,
                          onTap: widget.onNavigateToDormitory,
                        ),
                    ]),
                    const SizedBox(height: 12),
                    // ห้องพัก (ซ่อนสำหรับแอดมิน)
                    if (!widget.isAdmin)
                      _buildMenuSection(
                        'ห้องพัก',
                        widget.isRoommate
                            ? [
                                _MenuItem(
                                  svgIcon: 'assets/images/icon_house_user.svg',
                                  label: 'สมาชิกในห้อง',
                                  showArrow: true,
                                  onTap: widget.onNavigateToRoomMembers,
                                ),
                                _MenuItem(
                                  icon: Icons.logout,
                                  label: 'ออกจากหอพัก',
                                  showArrow: true,
                                  onTap: widget.onLeaveRoom,
                                ),
                              ]
                            : widget.hasRoom
                            ? [
                                _MenuItem(
                                  svgIcon: 'assets/images/icon_note_done.svg',
                                  label: 'ข้อมูลการเช่า',
                                  showArrow: true,
                                  onTap: widget.onNavigateToRentalInfo,
                                ),
                                _MenuItem(
                                  svgIcon: 'assets/images/icon_house_user.svg',
                                  label: 'สมาชิกในห้อง',
                                  showArrow: true,
                                  onTap: widget.onNavigateToRoomMembers,
                                ),
                                _MenuItem(
                                  icon: Icons.logout,
                                  label: 'ออกจากหอพัก',
                                  showArrow: true,
                                  onTap: widget.onLeaveRoom,
                                ),
                              ]
                            : [
                                _MenuItem(
                                  icon: Icons.meeting_room_outlined,
                                  label: 'เข้าร่วมห้องพัก',
                                  showArrow: true,
                                  onTap: widget.onNavigateToParticipate,
                                ),
                              ],
                      ),
                    // การ์ดสมัครเป็นผู้เช่าหลัก (roommate เท่านั้น)
                    if (widget.isRoommate) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GestureDetector(
                          onTap: widget.onUpgradeToTenant,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBE5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFFD700),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/images/icon_crown.svg',
                                  width: 28,
                                  height: 28,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'สมัครเป็นผู้เช่าหลัก',
                                        style: TextStyle(
                                          fontFamily: 'Noto Sans Thai',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4181CB),
                                        ),
                                      ),
                                      Text(
                                        'เริ่มต้นการสมัครเพื่อเป็นผู้เช่าหลัก',
                                        style: TextStyle(
                                          fontFamily: 'Noto Sans Thai',
                                          fontSize: 13,
                                          color: Color(0xFF888888),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 22,
                                  color: Color(0xFF000000),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildMenuSection('การใช้งาน', [
                      _MenuItem(
                        svgIcon: 'assets/images/icon_user_2.svg',
                        label: 'ปัดบัญชีการใช้งาน',
                        showArrow: true,
                        onTap: widget.onNavigateToCloseAccount,
                      ),
                      _MenuItem(
                        svgIcon: 'assets/images/icon_bell.svg',
                        label: 'การแจ้งเตือน',
                        toggleValue: _notificationEnabled,
                        onToggle: (v) =>
                            setState(() => _notificationEnabled = v),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _buildMenuSection('อื่นๆ', [
                      _MenuItem(
                        icon: Icons.headset_mic_outlined,
                        label: 'ติดต่อเรา',
                        showArrow: true,
                        onTap: widget.onNavigateToDara,
                      ),
                      _MenuItem(
                        svgIcon: 'assets/images/icon_lock.svg',
                        label: 'นโยบายความเป็นส่วนตัว',
                        showArrow: true,
                        onTap: widget.onNavigateToPrivacyPolicy,
                      ),
                      _MenuItem(
                        svgIcon: 'assets/images/icon_note_done.svg',
                        label: 'ข้อกำหนดการใช้งาน',
                        showArrow: true,
                        onTap: widget.onNavigateToTermsOfUse,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    // ออกจากระบบ
                    GestureDetector(
                      onTap: () => _showLogoutDialog(),
                      child: const Text(
                        'ออกจากระบบ',
                        style: TextStyle(
                          fontFamily: 'Noto Sans Thai',
                          fontSize: 16,
                          color: Color(0xFFE05A5A),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFE05A5A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ---- Profile Header ----
  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 8),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFB7D6F5), width: 2),
                ),
                  child: ClipOval(
                    child: _profileImageBytes != null
                        ? Image.memory(_profileImageBytes!, fit: BoxFit.cover)
                        : (widget.avatarUrl.isNotEmpty
                           ? Image.network(
                               widget.avatarUrl,
                               fit: BoxFit.cover,
                               loadingBuilder: (context, child, progress) {
                                 if (progress == null) return child;
                                 return Container(
                                   color: const Color(0xFFB7D6F5),
                                   child: const Center(
                                     child: Icon(Icons.person,
                                         size: 40, color: Colors.white),
                                   ),
                                 );
                               },
                               errorBuilder: (_, __, ___) => Container(
                                 color: const Color(0xFFB7D6F5),
                                 child: const Center(
                                   child: Icon(Icons.person,
                                       size: 40, color: Colors.white),
                                 ),
                               ),
                             )
                           : Container(
                               color: const Color(0xFFB7D6F5),
                               child: const Center(
                                 child: Icon(Icons.person,
                                     size: 40, color: Colors.white),
                               ),
                             )),
                 ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F8FDB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.isAdmin) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 Text(
                   widget.userName.isNotEmpty ? widget.userName : 'พัชราวรรณ  ศรีบุญ',
                   style: const TextStyle(
                     fontFamily: 'Noto Sans Thai',
                     fontSize: 16,
                     fontWeight: FontWeight.w500,
                     color: Color(0xFF000000),
                   ),
                 ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4F8FDB).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F8FDB),
                ),
              ),
            ),
          ] else ...[
            Text(
              widget.userName.isNotEmpty ? widget.userName : 'พัชราวรรณ  ศรีบุญ',
              style: const TextStyle(
                fontFamily: 'Noto Sans Thai',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF000000),
              ),
            ),
          ],
          if (!widget.isAdmin) ...[
            const SizedBox(height: 2),
            if (!widget.isAdmin && widget.roomNumber.isNotEmpty)
              Text(
                'ห้อง ${widget.roomNumber}',
                style: const TextStyle(
                  fontFamily: 'Noto Sans Thai',
                  fontSize: 15,
                  color: Color(0xFF666666),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ---- Menu Section ----
  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Noto Sans Thai',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 6),
          Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  onTap: item.toggleValue != null
                      ? () => item.onToggle?.call(!item.toggleValue!)
                      : item.onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD9D9D9),
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                        16, item.toggleValue != null ? 8 : 14, 12,
                        item.toggleValue != null ? 8 : 14),
                    child: Row(
                      children: [
                        if (item.svgIcon != null) ...[
                          SvgPicture.asset(
                            item.svgIcon!,
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 10),
                        ] else if (item.icon != null) ...[
                          Icon(
                            item.icon,
                            size: 24,
                            color: const Color(0xFF4F8FDB),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(
                              fontFamily: 'Noto Sans Thai',
                              fontSize: 15,
                              color: Color(0xFF000000),
                            ),
                          ),
                        ),
                        if (item.toggleValue != null)
                          Transform.scale(
                            scale: 0.75,
                            child: Switch(
                            value: item.toggleValue!,
                            onChanged: item.onToggle,
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFF4F8FDB),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFD9D9D9),
                            trackOutlineColor:
                                WidgetStateProperty.all(Colors.transparent),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                        else if (item.showArrow)
                          const Icon(
                            Icons.chevron_right,
                            size: 22,
                            color: Color(0xFF000000),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ยืนยันการออกจากระบบ',
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'คุณต้องการออกจากระบบใช่ไหม?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Noto Sans Thai',
                    fontSize: 13,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF4F8FDB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 14,
                            color: Color(0xFF4F8FDB),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onLogout?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0303),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ออกจากระบบ',
                          style: TextStyle(
                            fontFamily: 'Noto Sans Thai',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- Bottom Navigation ----
  Widget _buildBottomNav() {
    if (widget.isAdmin) {
      return _buildAdminBottomNav();
    }
    return _buildUserBottomNav();
  }

  // แถบเมนูฝั่งแอดมิน (6 ไอคอน, width 320, activeIndex=5)
  Widget _buildAdminBottomNav() {
    const navWidth = 320.0;
    const itemCount = 6;
    const circleSize = 40.0;
    const adminActiveIndex = 5; // profile = index 5 เสมอ
    final slot = navWidth / itemCount;
    final indicatorLeft = slot * adminActiveIndex + (slot - circleSize) / 2;

    final svgPaths = <int, String>{
      0: 'assets/images/icon_home.svg',
      1: 'assets/images/persons.svg',
      2: 'assets/images/icon_bill.svg',
      4: 'assets/images/icon_announcement.svg',
      5: 'assets/images/icon_user.svg',
    };
    final materialIcons = <int, IconData>{3: Icons.build_outlined};

    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: navWidth,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF4F8FDB),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: indicatorLeft,
              top: 6,
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEFFAF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              children: List.generate(itemCount, (i) {
                const adminActiveIndex = 5; // profile = index 5 เสมอ
                final isActive = i == adminActiveIndex;
                final color = isActive ? const Color(0xFF4F8FDB) : Colors.white;
                return GestureDetector(
                  onTap: () {
                    if (i == 0 && widget.onNavigateToDashboard != null) {
                      widget.onNavigateToDashboard!();
                    } else if (i == 1 && widget.onNavigateToTenant != null) {
                      widget.onNavigateToTenant!();
                    } else if (i == 2 && widget.onNavigateToAdminBill != null) {
                      widget.onNavigateToAdminBill!();
                    } else if (i == 3 &&
                        widget.onNavigateToReportRepair != null) {
                      widget.onNavigateToReportRepair!();
                    } else if (i == 4 &&
                        widget.onNavigateToAdminAnnounce != null) {
                      widget.onNavigateToAdminAnnounce!();
                    }
                    // i == 5 คือหน้าปัจจุบัน (profile)
                  },
                  child: SizedBox(
                    width: slot,
                    height: 52,
                    child: Center(
                      child: _wrapRepairBadge(
                        i,
                        svgPaths.containsKey(i)
                            ? SvgPicture.asset(
                                svgPaths[i]!,
                                width: 24,
                                height: 24,
                                colorFilter: ColorFilter.mode(
                                  color,
                                  BlendMode.srcIn,
                                ),
                              )
                            : Icon(materialIcons[i], size: 22, color: color),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // แถบเมนูฝั่งผู้เช่า (5 ไอคอน, width 280, activeIndex=4)
  Widget _buildUserBottomNav() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        width: 280,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF4F8FDB),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: 11.67 + _selectedIndex * 53.17,
              top: 4,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEFFAF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _buildNavItems(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNavItems() {
    final items = <IconData?>[
      null, // index 0 icon_home.svg
      null, // index 1 icon_bill.svg
      null, // index 2 icon_message.svg
      null, // index 3 icon_announcement.svg
      null, // index 4 icon_user.svg
    ];

    final svgPaths = <int, String>{
      0: 'assets/images/icon_home.svg',
      1: 'assets/images/icon_bill.svg',
      2: 'assets/images/icon_message.svg',
      3: 'assets/images/icon_announcement.svg',
      4: 'assets/images/icon_user.svg',
    };

    return List.generate(items.length, (i) {
      final isActive = i == _selectedIndex;
      return GestureDetector(
        onTap: () {
          if (i == 0) {
            if (widget.isAdmin && widget.onNavigateToDashboard != null) {
              widget.onNavigateToDashboard!();
            } else if (widget.onNavigateToHome != null) {
              widget.onNavigateToHome!();
            }
          } else if (i == 1 && widget.onNavigateToRentalFee != null) {
            widget.onNavigateToRentalFee!();
          } else if (i == 2 && widget.onNavigateToChat != null) {
            widget.onNavigateToChat!();
          } else if (i == 3 && widget.onNavigateToAnnounce != null) {
            widget.onNavigateToAnnounce!();
          } else {
            setState(() => _selectedIndex = i);
          }
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: _wrapChatBadge(
              i,
              items[i] == null
                  ? SvgPicture.asset(
                      svgPaths[i]!,
                      width: 26,
                      height: 26,
                      colorFilter: ColorFilter.mode(
                        isActive ? const Color(0xFF4F8FDB) : Colors.white,
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(
                      items[i],
                      color: isActive ? const Color(0xFF4F8FDB) : Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ),
      );
    });
  }

  /// ห่อไอคอนแชท (index 2) ด้วยจุดแดงถ้า showChatBadge (เฉพาะฝั่งผู้เช่า)
  Widget _wrapChatBadge(int index, Widget icon) {
    if (index != 2 || !widget.showChatBadge || widget.isAdmin) return icon;
    return _redDot(icon);
  }

  /// ห่อไอคอนแจ้งซ่อม (index 3) ด้วยจุดแดง — ฝั่งแอดมิน
  Widget _wrapRepairBadge(int index, Widget icon) {
    if (index != 3 || !widget.showChatBadge || !widget.isAdmin) return icon;
    return _redDot(icon);
  }

  Widget _redDot(Widget icon) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4F8FDB), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData? icon;
  final String? svgIcon;
  final String label;
  final bool showArrow;
  final VoidCallback? onTap;

  // ถ้า toggleValue ไม่เป็น null จะแสดงสวิตช์เปิด/ปิดแทนลูกศร
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;

  _MenuItem({
    this.icon,
    this.svgIcon,
    required this.label,
    this.showArrow = false,
    this.onTap,
    this.toggleValue,
    this.onToggle,
  });
}
