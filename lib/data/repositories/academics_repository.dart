import "package:get/get.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:edulink/core/config/supabase_config.dart";
import "package:edulink/core/enums/user_role.dart";
import "package:edulink/data/repositories/auth_repository.dart";
import "package:edulink/domain/entities/enrollment.dart";
import "package:edulink/domain/entities/parent_link.dart";
import "package:edulink/domain/entities/profile.dart";
import "package:edulink/domain/entities/school_class.dart";
import "package:edulink/domain/entities/subject.dart";

/// Classes, subjects, enrollments, people and parent-child links.
class AcademicsRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  // ── Classes ──
  Future<List<SchoolClass>> classes(String instituteId) async {
    final data = await _client
        .from(SupabaseConfig.tClasses)
        .select()
        .eq("institute_id", instituteId)
        .order("name");
    return (data as List).map((e) => SchoolClass.fromMap(e)).toList();
  }

  Future<List<SchoolClass>> classesForTeacher(String teacherId) async {
    final data = await _client
        .from(SupabaseConfig.tClasses)
        .select()
        .eq("class_teacher_id", teacherId)
        .order("name");
    return (data as List).map((e) => SchoolClass.fromMap(e)).toList();
  }

  Future<SchoolClass> createClass(SchoolClass c) async {
    final data = await _client
        .from(SupabaseConfig.tClasses)
        .insert(c.toMap())
        .select()
        .single();
    return SchoolClass.fromMap(data);
  }

  Future<void> updateClass(String id, SchoolClass c) async {
    await _client.from(SupabaseConfig.tClasses).update(c.toMap()).eq("id", id);
  }

  Future<void> deleteClass(String id) async {
    await _client.from(SupabaseConfig.tClasses).delete().eq("id", id);
  }

  // ── Subjects ──
  Future<List<Subject>> subjects(String classId) async {
    final data = await _client
        .from(SupabaseConfig.tSubjects)
        .select("*, teacher:teacher_id(full_name)")
        .eq("class_id", classId)
        .order("name");
    return (data as List).map((e) => Subject.fromMap(e)).toList();
  }

  Future<List<Subject>> subjectsForTeacher(String teacherId) async {
    final data = await _client
        .from(SupabaseConfig.tSubjects)
        .select("*, teacher:teacher_id(full_name)")
        .eq("teacher_id", teacherId)
        .order("name");
    return (data as List).map((e) => Subject.fromMap(e)).toList();
  }

  Future<Subject> createSubject(Subject s) async {
    final data = await _client
        .from(SupabaseConfig.tSubjects)
        .insert(s.toMap())
        .select("*, teacher:teacher_id(full_name)")
        .single();
    return Subject.fromMap(data);
  }

  Future<void> deleteSubject(String id) async {
    await _client.from(SupabaseConfig.tSubjects).delete().eq("id", id);
  }

  // ── Enrollments ──
  Future<List<Enrollment>> enrollments(String classId) async {
    final data = await _client
        .from(SupabaseConfig.tEnrollments)
        .select("*, student:student_id(full_name,email), class:class_id(name)")
        .eq("class_id", classId)
        .order("roll_no");
    return (data as List).map((e) => Enrollment.fromMap(e)).toList();
  }

  Future<List<Enrollment>> enrollmentsForStudent(String studentId) async {
    final data = await _client
        .from(SupabaseConfig.tEnrollments)
        .select("*, class:class_id(name)")
        .eq("student_id", studentId);
    return (data as List).map((e) => Enrollment.fromMap(e)).toList();
  }

  Future<Enrollment> enroll(Enrollment e) async {
    final data = await _client
        .from(SupabaseConfig.tEnrollments)
        .insert(e.toMap())
        .select("*, student:student_id(full_name,email), class:class_id(name)")
        .single();
    return Enrollment.fromMap(data);
  }

  Future<void> unenroll(String id) async {
    await _client.from(SupabaseConfig.tEnrollments).delete().eq("id", id);
  }

  // ── People (profiles) ──
  Future<List<Profile>> peopleByRole(String instituteId, String roleKey) async {
    final data = await _client
        .from(SupabaseConfig.tProfiles)
        .select()
        .eq("institute_id", instituteId)
        .eq("role", roleKey)
        .order("full_name");
    return (data as List).map((e) => Profile.fromMap(e)).toList();
  }

  Future<List<Profile>> searchPeople(String instituteId, String query) async {
    if (instituteId.isEmpty || query.trim().isEmpty) return [];
    final data = await _client
        .from(SupabaseConfig.tProfiles)
        .select()
        .eq("institute_id", instituteId)
        .ilike("full_name", "%${query.trim()}%")
        .order("full_name")
        .limit(20);
    return (data as List).map((e) => Profile.fromMap(e)).toList();
  }

  Future<List<SchoolClass>> searchClasses(String instituteId, String query) async {
    if (instituteId.isEmpty || query.trim().isEmpty) return [];
    final data = await _client
        .from(SupabaseConfig.tClasses)
        .select()
        .eq("institute_id", instituteId)
        .ilike("name", "%${query.trim()}%")
        .order("name")
        .limit(20);
    return (data as List).map((e) => SchoolClass.fromMap(e)).toList();
  }

  Future<void> assignInstitute(String userId, String instituteId) async {
    await _client
        .from(SupabaseConfig.tProfiles)
        .update({"institute_id": instituteId}).eq("id", userId);
  }

  Future<Profile?> findByEmail(String email) async {
    final data = await _client
        .from(SupabaseConfig.tProfiles)
        .select()
        .eq("email", email.trim().toLowerCase())
        .maybeSingle();
    return data == null ? null : Profile.fromMap(data);
  }

  Future<Profile?> findById(String id) async {
    final data = await _client
        .from(SupabaseConfig.tProfiles)
        .select()
        .eq("id", id)
        .maybeSingle();
    return data == null ? null : Profile.fromMap(data);
  }

  /// Sets a member's institute, role, name and phone. The profile row is
  /// created by a DB trigger right after signup, so we retry briefly in case
  /// it has not materialised yet.
  Future<void> updateMemberProfile({
    required String userId,
    required String instituteId,
    required UserRole role,
    required String fullName,
    String? phone,
  }) async {
    for (var attempt = 0; attempt < 6; attempt++) {
      final row = await _client
          .from(SupabaseConfig.tProfiles)
          .select("id")
          .eq("id", userId)
          .maybeSingle();
      if (row != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    await _client.from(SupabaseConfig.tProfiles).update({
      "institute_id": instituteId,
      "role": role.key,
      "full_name": fullName.trim(),
      if (phone != null && phone.trim().isNotEmpty) "phone": phone.trim(),
    }).eq("id", userId);
  }

  Future<void> assignClassTeacher(String classId, String teacherId) async {
    await _client
        .from(SupabaseConfig.tClasses)
        .update({"class_teacher_id": teacherId}).eq("id", classId);
  }

  /// Creates a member account and wires up their role-specific details in one
  /// call: students can be enrolled into a class (with a roll number), teachers
  /// can be set as the class teacher of a class, and parents can be linked to a
  /// child. Returns the freshly-created [Profile].
  Future<Profile> createMember({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    required String instituteId,
    String? phone,
    String? enrollClassId,
    String? rollNo,
    String? classTeacherOfId,
    String? childStudentId,
    String? relation,
  }) async {
    final auth = Get.find<AuthRepository>();
    final userId = await auth.createMemberAccount(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
    );

    await updateMemberProfile(
      userId: userId,
      instituteId: instituteId,
      role: role,
      fullName: fullName,
      phone: phone,
    );

    if (role.isStudent && enrollClassId != null && enrollClassId.isNotEmpty) {
      await enroll(Enrollment(
        id: "",
        classId: enrollClassId,
        studentId: userId,
        rollNo: (rollNo == null || rollNo.trim().isEmpty) ? null : rollNo.trim(),
      ));
    }

    if (role.isTeacher &&
        classTeacherOfId != null &&
        classTeacherOfId.isNotEmpty) {
      await assignClassTeacher(classTeacherOfId, userId);
    }

    if (role.isParent && childStudentId != null && childStudentId.isNotEmpty) {
      await linkParent(ParentLink(
        id: "",
        parentId: userId,
        studentId: childStudentId,
        relation:
            (relation == null || relation.trim().isEmpty) ? null : relation.trim(),
      ));
    }

    return await findById(userId) ??
        Profile(
          id: userId,
          email: email.trim().toLowerCase(),
          fullName: fullName.trim(),
          role: role,
          instituteId: instituteId,
          phone: phone,
        );
  }

  // ── Parent links ──
  Future<List<ParentLink>> childrenOfParent(String parentId) async {
    final data = await _client
        .from(SupabaseConfig.tParentLinks)
        .select("*, student:student_id(full_name)")
        .eq("parent_id", parentId);
    return (data as List).map((e) => ParentLink.fromMap(e)).toList();
  }

  Future<ParentLink> linkParent(ParentLink link) async {
    final data = await _client
        .from(SupabaseConfig.tParentLinks)
        .insert(link.toMap())
        .select("*, parent:parent_id(full_name), student:student_id(full_name)")
        .single();
    return ParentLink.fromMap(data);
  }

  Future<void> unlinkParent(String id) async {
    await _client.from(SupabaseConfig.tParentLinks).delete().eq("id", id);
  }
}
