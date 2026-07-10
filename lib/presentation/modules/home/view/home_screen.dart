import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/presentation/global_widgets/app_avatar.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";
import "package:edulink/presentation/global_widgets/stat_card.dart";
import "package:edulink/presentation/modules/academics/view/classes_screen.dart";
import "package:edulink/presentation/modules/academics/view/people_screen.dart";
import "package:edulink/presentation/modules/communication/view/announcements_screen.dart";
import "package:edulink/presentation/modules/communication/view/messages_screen.dart";
import "package:edulink/presentation/modules/finance/view/fees_screen.dart";
import "package:edulink/presentation/modules/finance/view/finance_management_screen.dart";
import "package:edulink/presentation/modules/home/controller/home_controller.dart";
import "package:edulink/presentation/modules/parent/view/children_screen.dart";
import "package:edulink/presentation/modules/reports/view/reports_screen.dart";
import "package:edulink/presentation/modules/settings/view/settings_screen.dart";
import "package:edulink/presentation/modules/student/view/student_assignments_screen.dart";
import "package:edulink/presentation/modules/student/view/student_courses_screen.dart";

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final profile = session.profile;
    final role = session.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.setting_2),
            onPressed: () => Get.to(() => const SettingsScreen()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const LoadingWidget();
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _greeting(context, profile?.fullName, role.label),
                  const SizedBox(height: 20),
                  ..._roleBody(context, session),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _greeting(BuildContext context, String? name, String roleLabel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          AppAvatar(name: name, radius: 26, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome back,",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                Text(name ?? "User",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(roleLabel,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _roleBody(BuildContext context, SessionController session) {
    final role = session.role;
    if (role.isPrincipal) return _principalBody(context, session);
    if (role.isTeacher) return _teacherBody(context);
    if (role.isStudent) return _studentBody(context);
    return _parentBody(context);
  }

  // ── Principal ──
  List<Widget> _principalBody(BuildContext context, SessionController session) {
    if (session.instituteId == null) {
      return [
        Card(
          color: AppColors.warning.withValues(alpha: 0.1),
          child: ListTile(
            leading: const Icon(Iconsax.buildings, color: AppColors.warning),
            title: const Text("Set up your institute"),
            subtitle: const Text("Create your school/college to get started."),
            trailing: const Icon(Iconsax.arrow_right_3),
            onTap: () => Get.to(() => const SettingsScreen()),
          ),
        ),
      ];
    }
    final o = controller.overview;
    final f = controller.finance;
    return [
      _statGrid(context, [
        StatCard(
            icon: Iconsax.book_1,
            label: "Students",
            value: "${o["students"] ?? 0}",
            color: AppColors.roleStudent),
        StatCard(
            icon: Iconsax.teacher,
            label: "Teachers",
            value: "${o["teachers"] ?? 0}",
            color: AppColors.roleTeacher),
        StatCard(
            icon: Iconsax.buildings,
            label: "Classes",
            value: "${o["classes"] ?? 0}",
            color: AppColors.rolePrincipal),
        StatCard(
            icon: Iconsax.money_recive,
            label: "Outstanding",
            value: Formatters.money(f["outstanding"] ?? 0),
            color: AppColors.error),
      ]),
      const SizedBox(height: 20),
      _quickLinks(context, [
        _Link(Iconsax.people, "People", () => Get.to(() => const PeopleScreen())),
        _Link(Iconsax.book_1, "Classes", () => Get.to(() => const ClassesScreen())),
        _Link(Iconsax.receipt_1, "Fees", () => Get.to(() => const FeesScreen())),
        _Link(Iconsax.wallet_3, "Finance",
            () => Get.to(() => const FinanceManagementScreen())),
        _Link(Iconsax.chart_2, "Reports", () => Get.to(() => const ReportsScreen())),
        _Link(Iconsax.notification, "Announce",
            () => Get.to(() => const AnnouncementsScreen())),
      ]),
    ];
  }

  // ── Teacher ──
  List<Widget> _teacherBody(BuildContext context) {
    return [
      _statGrid(context, [
        StatCard(
            icon: Iconsax.book_1,
            label: "My Classes",
            value: "${controller.myClasses.length}",
            color: AppColors.roleTeacher),
        StatCard(
            icon: Iconsax.teacher,
            label: "My Subjects",
            value: "${controller.mySubjects.length}",
            color: AppColors.primary),
      ]),
      const SizedBox(height: 20),
      _quickLinks(context, [
        _Link(Iconsax.book_1, "Classes", () => Get.to(() => const ClassesScreen())),
        _Link(Iconsax.notification, "Announce",
            () => Get.to(() => const AnnouncementsScreen())),
        _Link(Iconsax.messages_1, "Messages",
            () => Get.to(() => const MessagesScreen())),
      ]),
    ];
  }

  // ── Student ──
  List<Widget> _studentBody(BuildContext context) {
    return [
      _statGrid(context, [
        StatCard(
            icon: Iconsax.task_square,
            label: "Attendance",
            value: "${controller.attendanceRate.value.toStringAsFixed(0)}%",
            color: AppColors.accent),
        StatCard(
            icon: Iconsax.receipt_1,
            label: "Fees Due",
            value: Formatters.money(controller.outstandingForStudent),
            color: AppColors.error),
      ]),
      const SizedBox(height: 20),
      _quickLinks(context, [
        _Link(Iconsax.book_1, "Courses",
            () => Get.to(() => const StudentCoursesScreen())),
        _Link(Iconsax.task_square, "Assignments",
            () => Get.to(() => const StudentAssignmentsScreen())),
        _Link(Iconsax.receipt_1, "Fees", () => Get.to(() => const FeesScreen())),
        _Link(Iconsax.notification, "News",
            () => Get.to(() => const AnnouncementsScreen())),
      ]),
    ];
  }

  // ── Parent ──
  List<Widget> _parentBody(BuildContext context) {
    return [
      _statGrid(context, [
        StatCard(
            icon: Iconsax.people,
            label: "Children",
            value: "${controller.children.length}",
            color: AppColors.roleParent),
        StatCard(
            icon: Iconsax.receipt_1,
            label: "Fees Due",
            value: Formatters.money(controller.outstandingForChildren),
            color: AppColors.error),
      ]),
      const SizedBox(height: 20),
      _quickLinks(context, [
        _Link(Iconsax.people, "Children",
            () => Get.to(() => const ChildrenScreen())),
        _Link(Iconsax.receipt_1, "Fees", () => Get.to(() => const FeesScreen())),
        _Link(Iconsax.notification, "News",
            () => Get.to(() => const AnnouncementsScreen())),
        _Link(Iconsax.messages_1, "Messages",
            () => Get.to(() => const MessagesScreen())),
      ]),
    ];
  }

  Widget _statGrid(BuildContext context, List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        var cols = w >= 900 ? 4 : (w >= 600 ? 3 : 2);
        if (cols > cards.length) cols = cards.length;
        if (cols < 1) cols = 1;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: w >= 900 ? 1.35 : 1.5,
          children: cards,
        );
      },
    );
  }

  Widget _quickLinks(BuildContext context, List<_Link> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick actions",
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: links
              .map((l) => SizedBox(
                    width: 100,
                    child: InkWell(
                      onTap: l.onTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Icon(l.icon, color: AppColors.primary, size: 26),
                              const SizedBox(height: 8),
                              Text(l.label,
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _Link {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _Link(this.icon, this.label, this.onTap);
}
