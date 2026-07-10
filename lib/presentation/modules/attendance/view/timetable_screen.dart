import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/data/repositories/attendance_repository.dart";
import "package:edulink/domain/entities/school_class.dart";
import "package:edulink/domain/entities/subject.dart";
import "package:edulink/domain/entities/timetable_entry.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";

class TimetableScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const TimetableScreen({super.key, required this.schoolClass});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _repo = Get.find<AttendanceRepository>();
  final _academics = Get.find<AcademicsRepository>();
  final _session = Get.find<SessionController>();

  SchoolClass get _class => widget.schoolClass;
  bool get _canEdit => _session.role.canManageClasses || _session.role.canTeach;

  late Future<List<TimetableEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = _repo.timetable(_class.id);
  }

  void _reload() { setState(() { _entries = _repo.timetable(_class.id); }); }

  Future<void> _addEntry() async {
    final subjects = await _academics.subjects(_class.id);
    Subject? subject;
    int day = 1;
    TimeOfDay start = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 9, minute: 0);
    final roomCtrl = TextEditingController();

    String fmt(TimeOfDay t) =>
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

    if (!mounted) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Add Period",
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: day,
                  decoration: const InputDecoration(labelText: "Day"),
                  items: List.generate(
                      7,
                      (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(TimetableEntry.dayNames[i]))),
                  onChanged: (v) => setSheet(() => day = v ?? 1),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Subject>(
                  initialValue: subject,
                  decoration: const InputDecoration(labelText: "Subject"),
                  items: subjects
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setSheet(() => subject = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                              context: ctx, initialTime: start);
                          if (t != null) setSheet(() => start = t);
                        },
                        child: Text("Start ${fmt(start)}"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                              context: ctx, initialTime: end);
                          if (t != null) setSheet(() => end = t);
                        },
                        child: Text("End ${fmt(end)}"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomCtrl,
                  decoration:
                      const InputDecoration(labelText: "Room (optional)"),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Add"),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok == true) {
      try {
        await _repo.addEntry(TimetableEntry(
          id: "",
          classId: _class.id,
          subjectId: subject?.id,
          dayOfWeek: day,
          startTime: fmt(start),
          endTime: fmt(end),
          room: roomCtrl.text.trim().isEmpty ? null : roomCtrl.text.trim(),
        ));
        SnackbarUtils.showSuccess("Period added");
        _reload();
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Timetable • ${_class.displayName}")),
      floatingActionButton: _canEdit
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _addEntry,
              icon: const Icon(Iconsax.add),
              label: const Text("Period"),
            )
          : null,
      body: FutureBuilder<List<TimetableEntry>>(
        future: _entries,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }
          final entries = snap.data ?? [];
          if (entries.isEmpty) {
            return const EmptyState(
                icon: Iconsax.calendar_1, title: "No schedule yet");
          }
          final byDay = <int, List<TimetableEntry>>{};
          for (final e in entries) {
            byDay.putIfAbsent(e.dayOfWeek, () => []).add(e);
          }
          final days = byDay.keys.toList()..sort();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: days.map((d) {
              final items = byDay[d]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(TimetableEntry.dayNames[d - 1],
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  ...items.map((e) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.accent.withValues(alpha: 0.14),
                            child: const Icon(Iconsax.clock,
                                color: AppColors.accent, size: 20),
                          ),
                          title: Text(e.subjectName ?? "Period"),
                          subtitle: Text([
                            "${e.startTime} - ${e.endTime}",
                            if (e.room != null) "Room ${e.room}",
                          ].join("  •  ")),
                          trailing: _canEdit
                              ? IconButton(
                                  icon: const Icon(Iconsax.trash,
                                      color: AppColors.error, size: 20),
                                  onPressed: () async {
                                    await _repo.deleteEntry(e.id);
                                    _reload();
                                  },
                                )
                              : null,
                        ),
                      )),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
