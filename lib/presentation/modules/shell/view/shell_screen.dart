import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/enums/user_role.dart";
import "package:edulink/presentation/modules/academics/view/classes_screen.dart";
import "package:edulink/presentation/modules/academics/view/people_screen.dart";
import "package:edulink/presentation/modules/communication/view/announcements_screen.dart";
import "package:edulink/presentation/modules/communication/view/messages_screen.dart";
import "package:edulink/presentation/modules/finance/view/fees_screen.dart";
import "package:edulink/presentation/modules/home/view/home_screen.dart";
import "package:edulink/presentation/modules/parent/view/children_screen.dart";
import "package:edulink/presentation/modules/reports/view/student_progress_screen.dart";
import "package:edulink/presentation/modules/shell/controller/shell_controller.dart";
import "package:edulink/presentation/modules/student/view/student_assignments_screen.dart";
import "package:edulink/presentation/modules/student/view/student_courses_screen.dart";
import "package:edulink/presentation/web/web_shell.dart";

class _Tab {
  final IconData icon;
  final String label;
  final Widget page;
  const _Tab(this.icon, this.label, this.page);
}

class ShellScreen extends GetView<ShellController> {
  const ShellScreen({super.key});

  List<_Tab> _tabsFor(UserRole role) {
    const home = _Tab(Iconsax.home, "Home", HomeScreen());
    switch (role) {
      case UserRole.principal:
        return const [
          home,
          _Tab(Iconsax.book_1, "Classes", ClassesScreen()),
          _Tab(Iconsax.people, "People", PeopleScreen()),
          _Tab(Iconsax.receipt_1, "Fees", FeesScreen()),
          _Tab(Iconsax.notification, "News", AnnouncementsScreen()),
        ];
      case UserRole.teacher:
        return const [
          home,
          _Tab(Iconsax.book_1, "Classes", ClassesScreen()),
          _Tab(Iconsax.notification, "News", AnnouncementsScreen()),
          _Tab(Iconsax.messages_1, "Chat", MessagesScreen()),
        ];
      case UserRole.student:
        final session = Get.find<SessionController>();
        return [
          home,
          const _Tab(Iconsax.book_1, "Courses", StudentCoursesScreen()),
          const _Tab(Iconsax.task_square, "Tasks", StudentAssignmentsScreen()),
          _Tab(Iconsax.chart_2, "Progress",
              StudentProgressScreen(studentId: session.userId ?? "")),
          const _Tab(Iconsax.receipt_1, "Fees", FeesScreen()),
        ];
      case UserRole.parent:
        return const [
          home,
          _Tab(Iconsax.people, "Children", ChildrenScreen()),
          _Tab(Iconsax.receipt_1, "Fees", FeesScreen()),
          _Tab(Iconsax.messages_1, "Chat", MessagesScreen()),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = Get.find<SessionController>().role;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    // Wide screens (web/desktop) use the dedicated professional dashboard.
    if (isWide) return const WebShell();

    // Mobile keeps its existing bottom-navigation shell, unchanged.
    final tabs = _tabsFor(role);
    return Obx(() {
      final index = controller.index.value.clamp(0, tabs.length - 1);
      return Scaffold(
        body: IndexedStack(
          index: index,
          children: tabs.map((t) => t.page).toList(),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: controller.setIndex,
          destinations: tabs
              .map((t) => NavigationDestination(
                    icon: Icon(t.icon),
                    label: t.label,
                  ))
              .toList(),
        ),
      );
    });
  }
}
