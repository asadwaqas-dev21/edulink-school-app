import "package:supabase_flutter/supabase_flutter.dart";
import "package:edulink/core/config/supabase_config.dart";
import "package:edulink/domain/entities/institute.dart";

class InstituteRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<Institute?> getById(String id) async {
    final data = await _client
        .from(SupabaseConfig.tInstitutes)
        .select()
        .eq("id", id)
        .maybeSingle();
    return data == null ? null : Institute.fromMap(data);
  }

  Future<List<Institute>> list() async {
    final data = await _client
        .from(SupabaseConfig.tInstitutes)
        .select()
        .order("created_at");
    return (data as List).map((e) => Institute.fromMap(e)).toList();
  }

  Future<Institute> create(Institute institute) async {
    final data = await _client
        .from(SupabaseConfig.tInstitutes)
        .insert(institute.toMap())
        .select()
        .single();
    return Institute.fromMap(data);
  }

  Future<Institute> update(String id, Institute institute) async {
    final data = await _client
        .from(SupabaseConfig.tInstitutes)
        .update(institute.toMap())
        .eq("id", id)
        .select()
        .single();
    return Institute.fromMap(data);
  }

  Future<void> delete(String id) async {
    await _client.from(SupabaseConfig.tInstitutes).delete().eq("id", id);
  }
}
