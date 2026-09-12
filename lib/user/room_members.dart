import 'package:flutter/material.dart';

class RoomMembersScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNavigateToInvitationCode;

  const RoomMembersScreen({
    super.key,
    this.onBack,
    this.onNavigateToInvitationCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.35, 0.6, 1.0],
            colors: [
              Color(0xFFEAF2FB),
              Color(0xFFBFD9F2),
              Color(0xFFCFE0F0),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE0B2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.home,
                              color: Color(0xFFFF8C00),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ห้อง 301',
                                  style: TextStyle(
                                    fontFamily: 'Prompt',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF000000),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'หอพัก StayEase • อาคาร A ชั้น 3',
                                  style: TextStyle(
                                    fontFamily: 'Prompt',
                                    fontSize: 12,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF4FB),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '2/3',
                              style: TextStyle(
                                fontFamily: 'Prompt',
                                fontSize: 13,
                                color: Color(0xFF78A2D2),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // รหัสเชิญ button
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: onNavigateToInvitationCode,
                        child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF78A2D2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_circle_outline,
                                size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'รหัสเชิญ',
                              style: TextStyle(
                                fontFamily: 'Prompt',
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Members card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ผู้เช่าหลัก
                          const Text(
                            'ผู้เช่าหลัก',
                            style: TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildMemberRow(
                            name: 'พัชราวรรณ  ศรีบุญ',
                            phone: '099-000000',
                            imageAsset: 'assets/images/user_avatar.png',
                          ),
                          const Divider(
                              height: 24, color: Color(0xFFF0F0F0)),

                          // Roommate
                          const Text(
                            'Roommate',
                            style: TextStyle(
                              fontFamily: 'Prompt',
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildMemberRow(
                            name: 'พัชราวรรณ  ศรีบุญ',
                            phone: '099-000000',
                            imageAsset: 'assets/images/user_avatar.png',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRow({
    required String name,
    required String phone,
    required String imageAsset,
  }) {
    return Row(
      children: [
        ClipOval(
          child: Image.asset(
            imageAsset,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 44,
              height: 44,
              color: const Color(0xFFD9D9D9),
              child: const Icon(Icons.person_outline,
                  size: 24, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'Prompt',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              phone,
              style: const TextStyle(
                fontFamily: 'Prompt',
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(
              Icons.chevron_left,
              size: 24,
              color: Color(0xFF000000),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'สมาชิกในห้อง',
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
}
