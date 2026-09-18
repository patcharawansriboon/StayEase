import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToRentalFee;
  final VoidCallback? onNavigateToChat;
  final VoidCallback? onNavigateToAnnounce;
  final VoidCallback? onLogout;
  final VoidCallback? onNavigateToChangeNumber;
  final VoidCallback? onNavigateToPrivacyPolicy;
  final VoidCallback? onNavigateToChangePassword;
  final VoidCallback? onNavigateToRentalInfo;
  final VoidCallback? onNavigateToTermsOfUse;
  final VoidCallback? onNavigateToDara;
  final VoidCallback? onNavigateToRoomMembers;
  final VoidCallback? onNavigateToCloseAccount;
  final VoidCallback? onLeaveRoom;
  final VoidCallback? onUpgradeToTenant;
  // admin bottom nav
  final VoidCallback? onNavigateToTenant;
  final VoidCallback? onNavigateToReportRepair;
  final VoidCallback? onNavigateToNotification;
  final String phoneNumber;
  final bool isRoommate;
  final bool isAdmin;
  final String userName;
  final bool showSavedToast;
  final VoidCallback? onToastShown;

  const ProfileScreen({
    super.key,
    this.isRoommate = false,
    this.isAdmin = false,
    this.showSavedToast = false,
    this.onToastShown,
    this.onLeaveRoom,
    this.onUpgradeToTenant,
    this.onNavigateToTenant,
    this.onNavigateToReportRepair,
    this.onNavigateToNotification,
    this.userName = 'พัชราวรรณ  ศรีบุญ',
    this.onNavigateToHome,
    this.onNavigateToDashboard,
    this.onNavigateToRentalFee,
    this.onNavigateToChat,
    this.onNavigateToAnnounce,
    this.onLogout,
    this.onNavigateToChangeNumber,
    this.onNavigateToPrivacyPolicy,
    this.onNavigateToChangePassword,
    this.onNavigateToRentalInfo,
    this.onNavigateToTermsOfUse,
    this.onNavigateToDara,
    this.onNavigateToRoomMembers,
    this.onNavigateToCloseAccount,
    this.phoneNumber = '099-9999999',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late int _selectedIndex;
  bool _notificationEnabled = true;
  late String _phoneNumber;
  File? _profileImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  @override
  void initState() {
    super.initState();
    _phoneNumber = widget.phoneNumber;
    _selectedIndex = widget.isAdmin ? 5 : 4;
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phoneNumber != widget.phoneNumber) {
      setState(() => _phoneNumber = widget.phoneNumber);
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: const Row(
          children: [
            Expanded(
              child: Text(
                'บันทึกเรียบร้อย',
                style: TextStyle(
                  fontFamily: 'Prompt',
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
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
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
                        label: 'เปลี่ยนเบอร์มือถือ',
                        showArrow: true,
                        onTap: widget.onNavigateToChangeNumber,
                      ),
                      _MenuItem(
                        icon: null,
                        label: 'เปลี่ยนรหัสผ่าน',
                        showArrow: true,
                        onTap: widget.onNavigateToChangePassword,
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
                                  label: 'ออกจากห้อง',
                                  showArrow: true,
                                  onTap: widget.onLeaveRoom,
                                ),
                              ]
                            : [
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
                                horizontal: 16, vertical: 12),
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
                                          fontFamily: 'Prompt',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF4181CB),
                                        ),
                                      ),
                                      Text(
                                        'เริ่มต้นการสมัครเพื่อเป็นผู้เช่าหลัก',
                                        style: TextStyle(
                                          fontFamily: 'Prompt',
                                          fontSize: 13,
                                          color: Color(0xFF888888),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    size: 22, color: Color(0xFF000000)),
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
                        showArrow: true,
                        onTap: widget.onNavigateToNotification,
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
                          fontFamily: 'Prompt',
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
                  child: _profileImage != null
                      ? Image.file(_profileImage!, fit: BoxFit.cover)
                      : const Icon(
                          Icons.person_outline,
                          size: 40,
                          color: Color(0xFF4F8FDB),
                        ),
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
          Text(
            widget.userName.isNotEmpty ? widget.userName : 'พัชราวรรณ  ศรีบุญ',
            style: const TextStyle(
              fontFamily: 'Prompt',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF000000),
            ),
          ),
          if (!widget.isAdmin) ...[
            const SizedBox(height: 2),
            const Text(
              'ห้อง A301',
              style: TextStyle(
                fontFamily: 'Prompt',
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
              fontFamily: 'Prompt',
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
                  onTap: item.onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD9D9D9),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
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
                          Icon(item.icon,
                              size: 24, color: const Color(0xFF4F8FDB)),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 15,
                              color: Color(0xFF000000),
                            ),
                          ),
                        ),
                        if (item.showArrow)
                          const Icon(Icons.chevron_right,
                              size: 22, color: Color(0xFF000000)),
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'คุณต้องการออกจากระบบใช่ไหม?',
                  style: TextStyle(
                    fontFamily: 'Prompt',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF000000),
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
                            fontFamily: 'Prompt',
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
                          backgroundColor: const Color(0xFF4F8FDB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ตกลง',
                          style: TextStyle(
                            fontFamily: 'Prompt',
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
    final slot = navWidth / itemCount;
    final indicatorLeft = slot * _selectedIndex + (slot - circleSize) / 2;

    final svgPaths = <int, String>{
      0: 'assets/images/icon_home.svg',
      1: 'assets/images/persons.svg',
      2: 'assets/images/icon_bill.svg',
      4: 'assets/images/icon_announcement.svg',
      5: 'assets/images/icon_user.svg',
    };
    final materialIcons = <int, IconData>{
      3: Icons.build_outlined,
    };

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
                final isActive = i == _selectedIndex;
                final color = isActive ? const Color(0xFF4F8FDB) : Colors.white;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    if (i == 0 && widget.onNavigateToDashboard != null) {
                      widget.onNavigateToDashboard!();
                    } else if (i == 1 && widget.onNavigateToTenant != null) {
                      widget.onNavigateToTenant!();
                    } else if (i == 3 && widget.onNavigateToReportRepair != null) {
                      widget.onNavigateToReportRepair!();
                    }
                  },
                  child: SizedBox(
                    width: slot,
                    height: 52,
                    child: Center(
                      child: svgPaths.containsKey(i)
                          ? SvgPicture.asset(
                              svgPaths[i]!,
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                            )
                          : Icon(materialIcons[i], size: 22, color: color),
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
            child: items[i] == null
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
      );
    });
  }
}

class _MenuItem {
  final IconData? icon;
  final String? svgIcon;
  final String label;
  final bool showArrow;
  final VoidCallback? onTap;

  _MenuItem({
    this.icon,
    this.svgIcon,
    required this.label,
    this.showArrow = false,
    this.onTap,
  });
}
