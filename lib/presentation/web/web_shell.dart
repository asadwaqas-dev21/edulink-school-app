import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/theme_controller.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/presentation/modules/shell/controller/shell_controller.dart";
import "package:edulink/presentation/modules/shell/widgets/global_search_delegate.dart";
import "package:edulink/presentation/web/pages/web_engagement_pages.dart";
import "package:edulink/presentation/web/pages/web_ops_pages.dart";
import "package:edulink/presentation/web/pages/web_overview_pages.dart";
import "package:edulink/presentation/web/pages/web_parent_pages.dart";
import "package:edulink/presentation/web/pages/web_performance_pages.dart";
import "package:edulink/presentation/web/web_dashboard_controller.dart";
import "package:edulink/presentation/web/web_tokens.dart";

/// Professional web/desktop dashboard shell (sidebar + topbar + pages),
/// shown only on wide screens. Mobile keeps its existing bottom-nav shell.
class WebShell extends StatefulWidget {
  const WebShell({super.key});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  late final WebDashboardController _c;
  final _session = Get.find<SessionController>();
  int _index = 0;

  static const _labels = [
    "Dashboard",
    "People",
    "Academics",
    "Attendance",
    "Timetable",
    "Finance",
    "Communication",
    "Reports",
    "Settings",
    "Performance",
  ];
  static const _crumbs = [
    "Overview",
    "Institute members",
    "Classes & subjects",
    "Daily records",
    "Weekly schedule",
    "Income & expenses",
    "Announcements & messages",
    "Analytics",
    "Institute configuration",
    "Student reports",
  ];
  static const _icons = [
    Iconsax.home_2,
    Iconsax.people,
    Iconsax.teacher,
    Iconsax.task_square,
    Iconsax.calendar_1,
    Iconsax.wallet_3,
    Iconsax.messages_1,
    Iconsax.chart_2,
    Iconsax.setting_2,
    Iconsax.chart_success,
  ];

  @override
  void initState() {
    super.initState();
    _c = Get.isRegistered<WebDashboardController>()
        ? Get.find<WebDashboardController>()
        : Get.put(WebDashboardController());
  }

  void _go(String pageId) {
    final idx = List.generate(_labels.length, _labelFor)
        .indexWhere((l) => l.toLowerCase() == pageId);
    if (idx != -1 && _canAccess(idx)) setState(() => _index = idx);
  }

  /// Parents reuse the Academics slot for "Children" and the Finance slot for
  /// "Fees", so the label/icon/crumb adapt to their role.
  String _labelFor(int i) {
    if (_session.role.isParent) {
      if (i == 2) return "Children";
      if (i == 5) return "Fees";
    }
    return _labels[i];
  }

  String _crumbFor(int i) {
    if (_session.role.isParent) {
      if (i == 2) return "Subjects & performance";
      if (i == 5) return "Fee slips & payments";
    }
    return _crumbs[i];
  }

  IconData _iconFor(int i) {
    if (_session.role.isParent) {
      if (i == 2) return Iconsax.people;
      if (i == 5) return Iconsax.receipt_1;
    }
    return _icons[i];
  }

  /// Role-based access for each page (index matches [_labels]).
  bool _canAccess(int i) {
    final r = _session.role;
    switch (i) {
      case 1: // People
        return r.canManagePeople;
      case 2: // Academics / Children
        return r.isPrincipal || r.canTeach || r.isStudent || r.canViewChildren;
      case 3: // Attendance
        return r.canMarkAttendance;
      case 5: // Finance / Fees
        return r.canManageFinance || r.canPayFees;
      case 7: // Reports
        return r.isPrincipal;
      case 8: // Settings
        return r.canManageInstitute;
      case 9: // Performance
        return r.isPrincipal || r.canTeach;
      default: // Dashboard, Timetable, Communication
        return true;
    }
  }

  // Only build pages the current role can access; others stay lightweight
  // placeholders so their data fetches never run.
  List<Widget> _pages() => [
        for (int i = 0; i < _labels.length; i++)
          _canAccess(i) ? _pageFor(i) : const SizedBox.shrink()
      ];

  Widget _pageFor(int i) {
    final isParent = _session.role.isParent;
    switch (i) {
      case 0:
        return WebDashboardPage(onNavigate: _go);
      case 1:
        return const WebPeoplePage();
      case 2:
        return isParent ? const WebChildrenPage() : const WebAcademicsPage();
      case 3:
        return const WebAttendancePage();
      case 4:
        return const WebTimetablePage();
      case 5:
        return isParent ? const WebParentFeesPage() : const WebFinancePage();
      case 6:
        return const WebCommunicationPage();
      case 7:
        return const WebReportsPage();
      case 8:
        return const WebSettingsPage();
      case 9:
        return const WebPerformancePage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = WebTokens.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: Obx(() {
        // Only block the whole shell on the very first load; later reloads
        // keep the current content visible to preserve page state.
        if (_c.isLoading.value && _c.institute.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Row(
          children: [
            _sidebar(t),
            Expanded(
              child: Column(
                children: [
                  _topbar(t),
                  Expanded(
                    child: IndexedStack(index: _index, children: _pages()),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Sidebar ──
  Widget _sidebar(WebTokens t) {
    return Container(
      width: 258,
      padding: const EdgeInsets.fromLTRB(17, 24, 17, 18),
      decoration: BoxDecoration(
        color: t.panel,
        border: Border(right: BorderSide(color: t.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 0, 9, 19),
            child: Row(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                      gradient: t.brandGradient,
                      borderRadius: BorderRadius.circular(13)),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    "assets/images/applogo.jpg",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const Center(
                      child: Icon(Iconsax.book_1, size: 20, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                        color: t.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6),
                    children: [
                      const TextSpan(text: "Kurchu"),
                      TextSpan(text: "LMS", style: TextStyle(color: t.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _navSection(t, "Overview", [0, 1, 2]),
                  _navSection(t, "Operations", [3, 4, 5]),
                  _navSection(t, "Insights", [7, 9]),
                  _navSection(t, "Engagement", [6, 8]),
                ],
              ),
            ),
          ),
          Divider(color: t.line, height: 24),
          _profileMini(t),
        ],
      ),
    );
  }

  Widget _navSection(WebTokens t, String label, List<int> indices) {
    final visible = indices.where(_canAccess).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
          child: Text(label.toUpperCase(),
              style: TextStyle(
                  color: t.muted.withValues(alpha: 0.8),
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800)),
        ),
        ...visible.map((i) => _navTile(t, _iconFor(i), _labelFor(i), i)),
      ],
    );
  }

  Widget _navTile(WebTokens t, IconData icon, String label, int index,
      {VoidCallback? onTap}) {
    final active = index == _index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? t.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap ?? () => setState(() => _index = index),
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 19, color: active ? t.primary : t.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          color: active ? t.primary : t.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
                if (index == 5)
                  Obx(() {
                    final n = _session.role.isParent
                        ? _c.childrenUnpaidSlips
                        : _c.pendingInvoices;
                    if (n == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                          color: t.danger,
                          borderRadius: BorderRadius.circular(9)),
                      child: Text("$n",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800)),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileMini(WebTokens t) {
    final p = _session.profile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: t.primarySoft, shape: BoxShape.circle),
            child: Text(Formatters.initials(p?.fullName),
                style: TextStyle(
                    color: t.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p?.fullName ?? "User",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: t.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                Text(_session.role.label,
                    style: TextStyle(color: t.muted, fontSize: 10)),
              ],
            ),
          ),
          IconButton(
            tooltip: "Sign out",
            visualDensity: VisualDensity.compact,
            icon: Icon(Iconsax.logout, size: 18, color: t.muted),
            onPressed: () => Get.find<ShellController>().logout(),
          ),
        ],
      ),
    );
  }

  // ── Topbar ──
  Widget _topbar(WebTokens t) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_labelFor(_index),
                    style: TextStyle(
                        color: t.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text("Edulink / ${_crumbFor(_index)}",
                    style: TextStyle(color: t.muted, fontSize: 10)),
              ],
            ),
          ),
          const Spacer(),
          _searchBox(t),
          const SizedBox(width: 14),
          _roleChip(t),
          const SizedBox(width: 8),
          Obx(() => _iconBtn(
                t,
                Get.find<ThemeController>().isDarkMode
                    ? Iconsax.sun_1
                    : Iconsax.moon,
                onTap: () => Get.find<ThemeController>().toggleTheme(),
              )),
          const SizedBox(width: 8),
          _notifications(t),
        ],
      ),
    );
  }

  Widget _searchBox(WebTokens t) {
    return SizedBox(
      width: 360,
      child: InkWell(
        onTap: () => showSearch<void>(
            context: context, delegate: GlobalSearchDelegate()),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: t.panel,
            border: Border.all(color: t.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Iconsax.search_normal_1, size: 18, color: t.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text("Search students, teachers, classes…",
                    style: TextStyle(color: t.muted, fontSize: 12)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                    color: t.panel2,
                    border: Border.all(color: t.line),
                    borderRadius: BorderRadius.circular(6)),
                child: Text("Ctrl K",
                    style: TextStyle(color: t.muted, fontSize: 9)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(WebTokens t) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.panel,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(_session.role.label,
          style: TextStyle(
              color: t.ink, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _iconBtn(WebTokens t, IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: t.panel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: t.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: t.muted),
        ),
      ),
    );
  }

  Widget _notifications(WebTokens t) {
    return Obx(() {
      final items = _c.announcements.take(6).toList();
      return PopupMenuButton<void>(
        tooltip: "Notifications",
        offset: const Offset(0, 48),
        color: t.panel,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: t.line)),
        constraints: const BoxConstraints(minWidth: 300, maxWidth: 340),
        itemBuilder: (context) {
          if (items.isEmpty) {
            return [
              PopupMenuItem<void>(
                enabled: false,
                child: Text("No new announcements",
                    style: TextStyle(color: t.muted, fontSize: 12)),
              ),
            ];
          }
          return [
            PopupMenuItem<void>(
              enabled: false,
              child: Text("Announcements",
                  style: TextStyle(
                      color: t.ink, fontSize: 12, fontWeight: FontWeight.w800)),
            ),
            ...items.map((a) => PopupMenuItem<void>(
                  onTap: () => _go("communication"),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: t.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(Formatters.dateTime(a.createdAt),
                          style: TextStyle(color: t.muted, fontSize: 9.5)),
                    ],
                  ),
                )),
          ];
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _iconBtn(t, Iconsax.notification),
            if (items.isNotEmpty)
              Positioned(
                right: 7,
                top: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: t.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: t.panel, width: 2),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
