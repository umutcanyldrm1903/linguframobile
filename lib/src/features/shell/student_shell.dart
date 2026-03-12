import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../student/dashboard/student_dashboard_screen.dart';
import '../student/instructors/student_instructors_screen.dart';
import '../student/lessons/student_lessons_screen.dart';
import '../student/messages/student_messages_screen.dart';
import '../student/profile/student_profile_screen.dart';

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

  final List<String> _titles = const [
    'Öðrenci Paneli',
    'Eðitmenler',
    'Derslerim',
    'Mesajlar',
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
        selectedItemColor: AppColors.brand,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Eðitmenler'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Dersler'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Mesaj'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
