import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/data/repositories/communication_repository.dart";
import "package:edulink/domain/entities/announcement.dart";
import "package:edulink/presentation/modules/communication/view/announcements_screen.dart";
import "package:edulink/presentation/modules/shell/widgets/global_search_delegate.dart";

/// Web/desktop header with global search + notifications.
class DesktopTopBar extends StatefulWidget {
  const DesktopTopBar({super.key});

  @override
  State<DesktopTopBar> createState() => _DesktopTopBarState();
}

class _DesktopTopBarState extends State<DesktopTopBar> {
  final _comm = Get.find<CommunicationRepository>();
  final _session = Get.find<SessionController>();

  List<Announcement> _items = [];
  bool _loading = true;
  bool _seen = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final inst = _session.instituteId ?? "";
    if (inst.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final list = await _comm.announcements(inst);
      if (mounted) setState(() => _items = list);
    } catch (_) {
      // Silent — notifications are non-critical.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _unseen {
    if (_seen) return 0;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _items
        .where((a) => a.createdAt != null && a.createdAt!.isAfter(cutoff))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Flexible(child: _searchBox(context)),
          const Spacer(),
          _notifications(context),
        ],
      ),
    );
  }

  Widget _searchBox(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () =>
              showSearch(context: context, delegate: GlobalSearchDelegate()),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Iconsax.search_normal_1,
                    size: 18, color: AppColors.textTertiaryLight),
                const SizedBox(width: 10),
                Text("Search people, classes…",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textTertiaryLight)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _notifications(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: "Notifications",
      position: PopupMenuPosition.under,
      onOpened: () {
        if (!_seen) setState(() => _seen = true);
      },
      onSelected: (_) => Get.to(() => const AnnouncementsScreen()),
      icon: Badge(
        isLabelVisible: _unseen > 0,
        label: Text("$_unseen"),
        child: const Icon(Iconsax.notification),
      ),
      itemBuilder: (context) {
        if (_items.isEmpty) {
          return [
            PopupMenuItem<int>(
              enabled: false,
              child: Text(_loading ? "Loading…" : "No notifications"),
            ),
          ];
        }
        final recent = _items.take(6).toList();
        return [
          const PopupMenuItem<int>(
            enabled: false,
            child: Text("Notifications",
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          for (int i = 0; i < recent.length; i++)
            PopupMenuItem<int>(
              value: i,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recent[i].title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.dateTime(recent[i].createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiaryLight),
                    ),
                  ],
                ),
              ),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem<int>(
            value: -1,
            child: Text("View all announcements",
                style: TextStyle(color: AppColors.primary)),
          ),
        ];
      },
    );
  }
}
