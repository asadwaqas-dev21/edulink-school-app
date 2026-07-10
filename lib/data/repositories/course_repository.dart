import "dart:typed_data";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:uuid/uuid.dart";
import "package:edulink/core/config/supabase_config.dart";
import "package:edulink/domain/entities/lesson.dart";
import "package:edulink/domain/entities/material_item.dart";

class CourseRepository {
  SupabaseClient get _client => SupabaseConfig.client;
  final _uuid = const Uuid();

  // ── Lessons ──
  Future<List<Lesson>> lessons(String subjectId) async {
    final data = await _client
        .from(SupabaseConfig.tLessons)
        .select()
        .eq("subject_id", subjectId)
        .order("order_index");
    return (data as List).map((e) => Lesson.fromMap(e)).toList();
  }

  Future<Lesson> createLesson(Lesson lesson) async {
    final data = await _client
        .from(SupabaseConfig.tLessons)
        .insert(lesson.toMap())
        .select()
        .single();
    return Lesson.fromMap(data);
  }

  Future<void> updateLesson(String id, Lesson lesson) async {
    await _client.from(SupabaseConfig.tLessons).update(lesson.toMap()).eq("id", id);
  }

  Future<void> deleteLesson(String id) async {
    await _client.from(SupabaseConfig.tLessons).delete().eq("id", id);
  }

  // ── Materials ──
  Future<List<MaterialItem>> materials(String lessonId) async {
    final data = await _client
        .from(SupabaseConfig.tMaterials)
        .select()
        .eq("lesson_id", lessonId)
        .order("created_at");
    return (data as List).map((e) => MaterialItem.fromMap(e)).toList();
  }

  Future<MaterialItem> createMaterial(MaterialItem material) async {
    final data = await _client
        .from(SupabaseConfig.tMaterials)
        .insert(material.toMap())
        .select()
        .single();
    return MaterialItem.fromMap(data);
  }

  Future<void> deleteMaterial(String id) async {
    await _client.from(SupabaseConfig.tMaterials).delete().eq("id", id);
  }

  /// Uploads a file to a storage bucket and returns its public URL.
  Future<String> uploadFile({
    required String bucket,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final path = "${_uuid.v4()}_$fileName";
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}
