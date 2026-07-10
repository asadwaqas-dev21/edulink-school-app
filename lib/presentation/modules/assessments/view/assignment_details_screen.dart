import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:url_launcher/url_launcher.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/config/supabase_config.dart";
import "package:edulink/core/enums/status_enums.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/formatters.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/data/repositories/assessment_repository.dart";
import "package:edulink/data/repositories/course_repository.dart";
import "package:edulink/domain/entities/assignment.dart";
import "package:edulink/domain/entities/submission.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";

class AssignmentDetailsScreen extends StatefulWidget {
  final Assignment assignment;
  const AssignmentDetailsScreen({super.key, required this.assignment});

  @override
  State<AssignmentDetailsScreen> createState() =>
      _AssignmentDetailsScreenState();
}

class _AssignmentDetailsScreenState extends State<AssignmentDetailsScreen> {
  final _repo = Get.find<AssessmentRepository>();
  final _courseRepo = Get.find<CourseRepository>();
  final _session = Get.find<SessionController>();

  Assignment get _a => widget.assignment;
  bool get _isStudent => _session.role.isStudent;

  final RxBool _busy = false.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_a.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(context),
          const SizedBox(height: 20),
          if (_isStudent) _studentSection() else _teacherSection(),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text("${_a.maxPoints} points")),
                const SizedBox(width: 8),
                if (_a.dueDate != null)
                  Chip(
                    backgroundColor: _a.isOverdue
                        ? AppColors.error.withValues(alpha: 0.15)
                        : null,
                    label: Text("Due ${Formatters.date(_a.dueDate)}"),
                  ),
              ],
            ),
            if (_a.description != null) ...[
              const SizedBox(height: 12),
              Text(_a.description!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Student view ──
  Widget _studentSection() {
    return FutureBuilder<Submission?>(
      future: _repo.mySubmission(_a.id, _session.userId ?? ""),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
              padding: EdgeInsets.all(24), child: LoadingWidget());
        }
        final sub = snap.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your submission",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (sub != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Iconsax.tick_circle,
                              color: AppColors.success, size: 18),
                          const SizedBox(width: 6),
                          Text("Submitted ${Formatters.date(sub.submittedAt)}"),
                        ],
                      ),
                      if (sub.fileUrl != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Iconsax.document),
                          label: const Text("View submitted file"),
                          onPressed: () => _open(sub.fileUrl!),
                        ),
                      ],
                      if (sub.status == SubmissionStatus.graded) ...[
                        const Divider(height: 24),
                        Text("Grade: ${sub.grade}/${_a.maxPoints}",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppColors.primary)),
                        if (sub.feedback != null) ...[
                          const SizedBox(height: 6),
                          Text("Feedback: ${sub.feedback}"),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Obx(() => FilledButton.icon(
                  onPressed: _busy.value ? null : _submitWork,
                  icon: const Icon(Iconsax.document_upload),
                  label: Text(sub == null ? "Submit work" : "Resubmit"),
                )),
          ],
        );
      },
    );
  }

  Future<void> _submitWork() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      SnackbarUtils.showError("Could not read file");
      return;
    }
    _busy.value = true;
    try {
      final url = await _courseRepo.uploadFile(
        bucket: SupabaseConfig.bucketSubmissions,
        fileName: file.name,
        bytes: file.bytes!,
      );
      await _repo.submit(Submission(
        id: "",
        assignmentId: _a.id,
        studentId: _session.userId ?? "",
        fileUrl: url,
        status:
            _a.isOverdue ? SubmissionStatus.late : SubmissionStatus.submitted,
      ));
      SnackbarUtils.showSuccess("Submitted");
      setState(() {});
    } catch (e) {
      SnackbarUtils.showError(e.toString());
    } finally {
      _busy.value = false;
    }
  }

  // ── Teacher view ──
  Widget _teacherSection() {
    return FutureBuilder<List<Submission>>(
      future: _repo.submissions(_a.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
              padding: EdgeInsets.all(24), child: LoadingWidget());
        }
        final subs = snap.data ?? [];
        if (subs.isEmpty) {
          return const EmptyState(
              icon: Iconsax.document, title: "No submissions yet");
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Submissions (${subs.length})",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...subs.map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(s.studentName ?? "Student"),
                    subtitle: Text(s.status == SubmissionStatus.graded
                        ? "Graded: ${s.grade}/${_a.maxPoints}"
                        : s.status.label),
                    trailing: TextButton(
                      onPressed: () => _gradeDialog(s),
                      child: Text(s.status == SubmissionStatus.graded
                          ? "Edit"
                          : "Grade"),
                    ),
                    onTap: s.fileUrl != null ? () => _open(s.fileUrl!) : null,
                  ),
                )),
          ],
        );
      },
    );
  }

  Future<void> _gradeDialog(Submission s) async {
    final gradeCtrl = TextEditingController(text: s.grade?.toString() ?? "");
    final feedbackCtrl = TextEditingController(text: s.feedback ?? "");
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Grade ${s.studentName ?? ''}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: "Grade (out of ${_a.maxPoints})"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Feedback"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Save")),
        ],
      ),
    );
    if (ok == true) {
      final grade = num.tryParse(gradeCtrl.text.trim());
      if (grade == null) {
        SnackbarUtils.showError("Enter a valid grade");
        return;
      }
      try {
        await _repo.grade(s.id, grade,
            feedbackCtrl.text.trim().isEmpty ? null : feedbackCtrl.text.trim());
        SnackbarUtils.showSuccess("Graded");
        setState(() {});
      } catch (e) {
        SnackbarUtils.showError(e.toString());
      }
    }
  }
}
