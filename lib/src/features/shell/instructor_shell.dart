import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_repository.dart';
import '../instructor/dashboard/instructor_dashboard_screen.dart';
import '../instructor/lessons/instructor_lessons_screen.dart';
import '../instructor/profile/instructor_profile_screen.dart';
import '../instructor/schedule/instructor_schedule_screen.dart';
import '../instructor/students/instructor_students_screen.dart';
import 'app_shell_scaffold.dart';

class InstructorShell extends StatefulWidget {
  const InstructorShell({super.key});

  @override
  State<InstructorShell> createState() => _InstructorShellState();
}

class _InstructorShellState extends State<InstructorShell> {
  int _index = 0;

  final List<Widget> _pages = const [
    InstructorDashboardScreen(),
    InstructorScheduleScreen(),
    InstructorLessonsScreen(),
    InstructorStudentsScreen(),
    InstructorProfileScreen(),
  ];

  List<AppShellDestination> get _destinations => [
        AppShellDestination(
          title: AppStrings.t('Instructor Dashboard'),
          label: AppStrings.t('Home'),
          icon: Icons.space_dashboard_outlined,
          selectedIcon: Icons.space_dashboard_rounded,
        ),
        AppShellDestination(
          title: AppStrings.t('Schedule'),
          label: AppStrings.t('Schedule'),
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month_rounded,
        ),
        AppShellDestination(
          title: AppStrings.t('Lessons'),
          label: AppStrings.t('Lessons'),
          icon: Icons.video_library_outlined,
          selectedIcon: Icons.video_library_rounded,
        ),
        AppShellDestination(
          title: AppStrings.t('Students'),
          label: AppStrings.t('Students'),
          icon: Icons.groups_2_outlined,
          selectedIcon: Icons.groups_2_rounded,
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
        roleLabel: AppStrings.t('Instructor'),
        accentColor: AppColors.brandDeep,
        onDestinationSelected: (value) => setState(() => _index = value),
        onLogout: _logout,
      ),
    );
  }
}
