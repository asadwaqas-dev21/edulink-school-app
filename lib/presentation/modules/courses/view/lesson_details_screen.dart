import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:get/get.dart";
import "package:iconsax/iconsax.dart";
import "package:url_launcher/url_launcher.dart";
import "package:edulink/app/session/session_controller.dart";
import "package:edulink/core/config/supabase_config.dart";
import "package:edulink/core/theme/app_colors.dart";
import "package:edulink/core/utils/snackbar_utils.dart";
import "package:edulink/data/repositories/course_repository.dart";
import "package:edulink/domain/entities/lesson.dart";
import "package:edulink/domain/entities/material_item.dart";
import "package:edulink/presentation/global_widgets/empty_state.dart";
import "package:edulink/presentation/global_widgets/loading_widget.dart";

class LessonDetailsScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonDetailsScreen({super.key, required this.lesson});

  @override
  State<LessonDetailsScreen> createState() => _LessonDetailsScreenState();
}

class _LessonDetailsScreenState extends State<LessonDetailsScreen> {
  final _repo = Get.find<CourseRepository>();
  final _session = Get.find<SessionController>();

  Lesson get _lesson => widget.lesson;
  bool get _canEdit => _session.role.canTeach;

  late Future<List<MaterialItem>> _materials;
  final RxBool _uploading = false.obs;

  @override
  void initState() {
    super.initState();
    _materials = _repo.materials(_lesson.id);
  }

  void _reload() {
    setState(() {
      _materials = _repo.materials(_lesson.id);
    });
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      SnackbarUtils.showError("Could not open link");
    }
  }

  Future<void> _uploadMaterial() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) {
      SnackbarUtils.showError("Could not read file data");
      return;
    }
    _uploading.value = true;
    try {
      final url = await _repo.uploadFile(
        bucket: SupabaseConfig.bucketMaterials,
        fileName: file.name,
        bytes: file.bytes!,
      );
      await _repo.createMaterial(MaterialItem(
        id: "",
        lessonId: _lesson.id,
        title: file.name,
        fileUrl: url,
        fileType: file.extension,
      ));
      SnackbarUtils.showSuccess("Material uploaded");
      _reload();
    } catch (e) {
      SnackbarUtils.showError(e.toString());
    } finally {
      _uploading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_lesson.title)),
      floatingActionButton: _canEdit
          ? Obx(() => FloatingActionButton.extended(
                heroTag: null,
                onPressed: _uploading.value ? null : _uploadMaterial,
                icon: _uploading.value
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Iconsax.document_upload),
                label: Text(_uploading.value ? "Uploading..." : "Upload"),
              ))
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_lesson.description != null) ...[
            Text("Overview", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(_lesson.description!,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
          ],
          if (_lesson.videoUrl != null)
            Card(
              child: ListTile(
                leading: const Icon(Iconsax.video, color: AppColors.error),
                title: const Text("Watch video"),
                subtitle: Text(_lesson.videoUrl!,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _open(_lesson.videoUrl!),
              ),
            ),
          const SizedBox(height: 20),
          Text("Materials", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          FutureBuilder<List<MaterialItem>>(
            future: _materials,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: LoadingWidget(),
                );
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Iconsax.folder_open,
                  title: "No materials",
                  subtitle: "Course files will appear here.",
                );
              }
              return Column(
                children: items
                    .map((m) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Icon(Iconsax.document,
                                color: AppColors.primary),
                            title: Text(m.title),
                            subtitle: m.fileType != null
                                ? Text(m.fileType!.toUpperCase())
                                : null,
                            trailing: _canEdit
                                ? IconButton(
                                    icon: const Icon(Iconsax.trash,
                                        color: AppColors.error, size: 20),
                                    onPressed: () async {
                                      await _repo.deleteMaterial(m.id);
                                      _reload();
                                    },
                                  )
                                : const Icon(Iconsax.export_1, size: 18),
                            onTap: () => _open(m.fileUrl),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
