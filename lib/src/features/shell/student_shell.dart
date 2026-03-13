import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_repository.dart';
import '../student/dashboard/student_dashboard_screen.dart';
import '../student/instructors/student_instructors_screen.dart';
import '../student/lessons/student_lessons_screen.dart';
import '../student/messages/student_messages_screen.dart';
import '../student/profile/student_profile_screen.dart';
import 'app_shell_scaffold.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  final List<Widget> _pages = const [
    StudentDashboardScreen(),
    StudentInstructorsScreen(),
    StudentLessonsScreen(),
    StudentMessagesScreen(),
    StudentProfileScreen(),
  ];

  List<AppShellDestination> get _destinations => [
        AppShellDestination(
          title: AppStrings.t('Student Dashboard'),
          label: AppStrings.t('Home'),
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        AppShellDestination(
          title: AppStrings.t('Instructors'),
          label: AppStrings.t('Instructors'),
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups_rounded,
        ),
        AppShellDestination(
          title: AppStrings.t('My Lessons'),
          label: AppStrings.t('Lessons'),
          icon: Icons.play_lesson_outlined,
          selectedIcon: Icons.play_lesson_rounded,
        ),
        AppShellDestination(
          title: AppStrings.t('Messages'),
          label: AppStrings.t('Messages'),
          icon: Icons.chat_bubble_outline_rounded,
          selectedIcon: Icons.chat_bubble_rounded,
        ),
        AppShellDestination(
          title: AppStrings.t('Profile'),
          label: AppStrings.t('Profile'),
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ];

  Future<void> _logout() async {
    try {
      await AuthRepository().logout();
    } catch (_) {}
    await SecureStorage.clearAll();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AppShellScaffold(
        currentIndex: _index,
        destinations: _destinations,
        pages: _pages,
        roleLabel: AppStrings.t('Student'),
        accentColor: AppColors.brand,
        onDestinationSelected: (value) => setState(() => _index = value),
        onLogout: _logout,
      ),
    );
  }
}
