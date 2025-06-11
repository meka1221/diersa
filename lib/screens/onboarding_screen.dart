import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:dearsa/auth/auth_service.dart'; // Changed from translator_app
import 'package:dearsa/screens/auth/registration_screen.dart'; // Changed from translator_app
import 'package:dearsa/utils/app_colors.dart'; // Changed from translator_app

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pageDecoration = PageDecoration(
      titleTextStyle: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700, color: AppColors.textDark),
      bodyTextStyle: const TextStyle(fontSize: 19.0, color: AppColors.textLight),
      bodyPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: AppColors.background,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Добро пожаловать!",
          body: "Наше приложение поможет вам стереть языковые барьеры.",
          image: Lottie.asset('assets/animations/welcome.json'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Перевод на лету",
          body: "Просто введите текст, выберите языки и получите моментальный перевод.",
          image: Lottie.asset('assets/animations/translate_anim.json'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Всегда под рукой",
          body: "Создайте аккаунт, чтобы начать пользоваться переводчиком прямо сейчас.",
          image: Lottie.asset('assets/animations/loading.json'),
          decoration: pageDecoration,
        ),
      ],
      onDone: () async {
        await AuthService().setOnboardingSeen();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RegistrationScreen()),
        );
      },
      showSkipButton: true,
      skip: const Text('Пропустить', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
      next: const Icon(Icons.arrow_forward, color: AppColors.primary),
      done: const Text('Начать', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: AppColors.secondary,
        activeColor: AppColors.primary,
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}