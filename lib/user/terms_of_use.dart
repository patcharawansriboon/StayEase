import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TermsOfUseScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const TermsOfUseScreen({super.key, this.onBack});

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
                  children: [
                    // Hero card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFFAF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            'assets/images/memo_check_filled.svg',
                            width: 67,
                            height: 67,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'การใช้ StayEase',
                                  style: TextStyle(
                                    fontFamily: 'Prompt',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF000000),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'การใช้งานแอปหมายถึง คุณยอมรับและตกลงปฏิบัติตามข้อกำหนดการใช้งานต่อไปนี้',
                                  style: TextStyle(
                                    fontFamily: 'Prompt',
                                    fontSize: 12,
                                    color: Color(0xFF555555),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Terms list card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildTermItem(
                            number: 1,
                            title: 'การใช้งานบัญชี',
                            detail:
                                'ผู้ใช้ต้องให้ข้อมูลที่ถูกต้องและรับผิดชอบต่อบัญชีของตนเอง',
                          ),
                          const SizedBox(height: 20),
                          _buildTermItem(
                            number: 2,
                            title: 'การใช้งานแอป',
                            detail:
                                'ใช้ StayEase เพื่อจัดการเรื่องหอพัก การเช่า การชำระเงิน การแจ้งซ่อมและการติดต่อที่เกี่ยวข้องเท่านั้น',
                          ),
                          const SizedBox(height: 20),
                          _buildTermItem(
                            number: 3,
                            title: 'ข้อมูลและเนื้อหา',
                            detail:
                                'ผู้ใช้ต้องไม่ส่งข้อมูลหรือเนื้อหาที่เป็นเท็จ ผิดกฎหมาย หรือสร้างความเสียหายแก่ผู้อื่น',
                          ),
                          const SizedBox(height: 20),
                          _buildTermItem(
                            number: 4,
                            title: 'การใช้งานระหว่างผู้เช่าและหอพัก',
                            detail:
                                'ข้อมูลการเช่า บิล การแจ้งซ่อม และการติดต่อในแอปขึ้นอยู่กับข้อมูลและการดำเนินงานของหอพักนั้น ๆ',
                          ),
                          const SizedBox(height: 20),
                          _buildTermItem(
                            number: 5,
                            title: 'การระงับบัญชี',
                            detail:
                                'StayEase หรือผู้ดูแลหอพักอาจระงับการใช้งานบัญชีที่มีการใช้งานไม่เหมาะสมหรือฝ่าฝืนข้อกำหนด',
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

  Widget _buildTermItem({
    required int number,
    required String title,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: Color(0xFF78A2D2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                fontFamily: 'Prompt',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 12,
                  color: Color(0xFF555555),
                  height: 1.5,
                ),
              ),
            ],
          ),
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
                'ข้อกำหนดการใช้งาน',
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
