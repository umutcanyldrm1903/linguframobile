import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../instructor/dashboard/instructor_dashboard_screen.dart';
import '../instructor/schedule/instructor_schedule_screen.dart';
import '../instructor/lessons/instructor_lessons_screen.dart';
import '../instructor/students/instructor_students_screen.dart';
import '../instructor/profile/instructor_profile_screen.dart';

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

  final List<String> _titles = const [
    'Eðitmen Paneli',
    'Takvim',
    'Dersler',
    'Öðrenciler',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
        selectedItemColor: AppColors.brandDeep,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Takvim'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle), label: 'Dersler'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Öðrenciler'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
