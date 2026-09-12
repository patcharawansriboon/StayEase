import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends StatelessWidget {
  final int currentPage;
  final VoidCallback onNextPage;

  const OnboardingScreen({
    super.key,
    required this.currentPage,
    required this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    final pages = [
      OnboardingData(
        title: 'จัดการหอพักง่าย\nครบทุกเรื่องในแอปเดียว',
        subtitle: 'สะดวก รวดเร็ว และปลอดภัย\nสำหรับผู้เช่าและแอดมิน',
      ),
      OnboardingData(
        title: 'แจ้งซ่อมผ่านแอป',
        subtitle: 'พูดคุยกับแอดมินได้ง่าย\nส่งรูป ติดตามสถานะการซ่อม\nแบบเรียลไทม์',
      ),
      OnboardingData(
        title: 'ชำระบิลสะดวก',
        subtitle: 'สแกน QR ชำระเงินได้ง่าย ปลอดภัย\nรับประกาศและการแจ้งเตือน\nไม่พลาดทุกข่าวสาร',
      ),
    ];

    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: _OnboardingIllustration(page: currentPage),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    pages[currentPage].title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF78A2D2),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    pages[currentPage].subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF000000),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            pages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index == currentPage ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: index == currentPage
                    ? const Color(0xFF78A2D2)
                    : const Color(0xFFD0D0D0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: onNextPage,
          child: Text(
            currentPage < pages.length - 1 ? 'ถัดไป' : 'เริ่มต้นใช้งาน',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF78A2D2),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  final int page;
  const _OnboardingIllustration({required this.page});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: page == 0
            ? AspectRatio(
                aspectRatio: 0.75,
                child: SvgPicture.asset('assets/images/Mobile-1.svg'),
              )
            : page == 1
                ? AspectRatio(
                    aspectRatio: 0.75,
                    child: SvgPicture.asset('assets/images/Mobile-2.svg'),
                  )
                : AspectRatio(
                    aspectRatio: 0.75,
                    child: SvgPicture.asset('assets/images/Mobile-3.svg'),
                  ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;

  OnboardingData({required this.title, required this.subtitle});
}
