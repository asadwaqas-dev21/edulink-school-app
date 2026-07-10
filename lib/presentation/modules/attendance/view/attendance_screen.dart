import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/enums/status_enums.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/data/repositories/academics_repository.dart";
import "package:edulink/data/repositories/attendance_repository.dart";
import "package:edulink/domain/entities/attendance_record.dart";
import "package:edulink/domain/entities/enrollment.dart";
import "package:edulink/domain/entities/school_class.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";
import "package:edulink/presentation/global_widgets/primary_button.dart";

class AttendanceScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  const AttendanceScreen({super.key, required this.schoolClass});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _academics = Get.find<AcademicsRepository>();
  final _attendance = Get.find<AttendanceRepository>();
  final _session = Get.find<SessionController>();

  SchoolClass get _class => widget.schoolClass;

  DateTime _date = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  List<Enrollment> _students = [];
  final Map<String, AttendanceStatus> _statuses = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _students = await _academics.enrollments(_class.id);
      final existing = await _attendance.forClassOnDate(_class.id, _date);
      _statuses.clear();
      for (final s in _students) {
        _statuses[s.studentId] = AttendanceStatus.present;
      }
      for (final r in existing) {
        _statuses[r.studentId] = r.status;
      }
    } catch (e) {
      SnackbarUtils.showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _load();
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final records = _students
          .map((s) => AttendanceRecord(
                id: "",
                classId: _class.id,
                studentId: s.studentId,
                date: _date,
                status: _statuses[s.studentId] ?? AttendanceStatus.present,
                markedBy: _session.userId,
              ))
          .toList();
      await _attendance.saveBatch(records);
      SnackbarUtils.showSuccess("Attendance saved");
    } catch (e) {
      SnackbarUtils.showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.late:
        return AppColors.warning;
      case AttendanceStatus.excused:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Attendance • ${_class.displayName}"),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Iconsax.calendar_1, size: 18),
            label: Text(Formatters.date(_date)),
          ),
        ],
      ),
      bottomNavigationBar: _students.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PrimaryButton(
                  text: "Save Attendance",
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ),
            ),
      body: _loading
          ? const LoadingWidget()
          : _students.isEmpty
              ? const EmptyState(
                  icon: Iconsax.people,
                  title: "No students enrolled",
                  subtitle: "Enroll students before marking attendance.")
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = _students[i];
                    final current =
                        _statuses[s.studentId] ?? AttendanceStatus.present;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.studentName ?? "Student",
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: AttendanceStatus.values.map((st) {
                                final selected = st == current;
                                return ChoiceChip(
                                  selected: selected,
                                  label: Text(st.label),
                                  selectedColor: _statusColor(st),
                                  labelStyle: TextStyle(
                                    color: selected ? Colors.white : null,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onSelected: (_) => setState(
                                      () => _statuses[s.studentId] = st),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
