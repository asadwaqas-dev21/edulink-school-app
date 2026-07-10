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
  ];

  @override
  void initState() {
    super.initState();
    _c = Get.isRegistered<WebDashboardController>()
        ? Get.find<WebDashboardController>()
        : Get.put(WebDashboardController());
  }

  void _go(String pageId) {
    final idx = _labels.indexWhere((l) => l.toLowerCase() == pageId);
    if (idx != -1 && _canAccess(idx)) setState(() => _index = idx);
  }

  /// Role-based access for each page (index matches [_labels]).
  bool _canAccess(int i) {
    final r = _session.role;
    switch (i) {
      case 1: // People
        return r.canManagePeople;
      case 2: // Academics
        return r.isPrincipal || r.canTeach || r.isStudent;
      case 3: // Attendance
        return r.canMarkAttendance;
      case 5: // Finance
        return r.canManageFinance;
      case 7: // Reports
        return r.isPrincipal;
      case 8: // Settings
        return r.canManageInstitute;
      default: // Dashboard, Timetable, Communication
        return true;
    }
  }

  // Only build pages the current role can access; others stay lightweight
  // placeholders so their data fetches never run.
  List<Widget> _pages() =>
      [for (int i = 0; i < _labels.length; i++) _canAccess(i) ? _pageFor(i) : const SizedBox.shrink()];

  Widget _pageFor(int i) {
    switch (i) {
      case 0:
        return WebDashboardPage(onNavigate: _go);
      case 1:
        return const WebPeoplePage();
      case 2:
        return const WebAcademicsPage();
      case 3:
        return const WebAttendancePage();
      case 4:
        return const WebTimetablePage();
      case 5:
        return const WebFinancePage();
      case 6:
        return const WebCommunicationPage();
      case 7:
        return const WebReportsPage();
      case 8:
        return const WebSettingsPage();
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
                  child: const Icon(Iconsax.book_1, color: Colors.white, size: 22),
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
                      const TextSpan(text: "Edu"),
                      TextSpan(text: "link", style: TextStyle(color: t.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Obx(() => _instituteCard(t)),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _navSection(t, "Overview", [0, 1, 2]),
                  _navSection(t, "Operations", [3, 4, 5]),
                  _navSection(t, "Engagement", [6, 7, 8]),
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

  Widget _instituteCard(WebTokens t) {
    final name = _c.institute.value?.name ?? "Your Institute";
    final type = _c.institute.value?.type.label ?? "Institute";
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: t.panel2,
          border: Border.all(color: t.line),
          borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: t.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: Text(Formatters.initials(name),
                style: TextStyle(
                    color: t.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: t.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                Text(type, style: TextStyle(color: t.muted, fontSize: 11)),
              ],
            ),
          ),
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
        ...visible.map((i) => _navTile(t, _icons[i], _labels[i], i)),
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
                Icon(icon,
                    size: 19, color: active ? t.primary : t.muted),
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
                    final n = _c.pendingInvoices;
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
            decoration: BoxDecoration(
                color: t.primarySoft, shape: BoxShape.circle),
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
                Text("${_session.role.label} · Web",
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
                Text(_labels[_index],
                    style: TextStyle(
                        color: t.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text("Edulink / ${_crumbs[_index]}",
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
        onTap: () =>
            showSearch<void>(context: context, delegate: GlobalSearchDelegate()),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                      color: t.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
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
