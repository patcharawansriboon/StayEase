import 'package:flutter/material.dart';

class AnnounceDetailsScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final String? imagePath;
  final String title;
  final String detail;

  const AnnounceDetailsScreen({
    super.key,
    this.onBack,
    this.imagePath,
    this.title = 'แจ้งงดใช้น้ำชั่วคราว',
    this.detail =
        'เนื่องจากมีการซ่อมแซมระบบประปา จึงขอแจ้งงดใช้น้ำอาคาร A\nวันที่ 12 สิงหาคม 2569 ในช่วงเวลา 09:00 - 14:00 น.\n\nขออภัยในความไม่สะดวก',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image card
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          imagePath ?? 'assets/images/announcement_1.png',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: const Color(0xFFF5F5F5),
                            child: const Center(
                              child: Icon(Icons.image_outlined,
                                  size: 48, color: Color(0xFFCCCCCC)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // รายละเอียด label
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'รายละเอียด',
                        style: TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Detail text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        detail,
                        style: const TextStyle(
                          fontFamily: 'Prompt',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF000000),
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
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
        ],
      ),
    );
  }
}
