import "package:supabase_flutter/supabase_flutter.dart";
import "package:edulink/core/config/supabase_config.dart";
import "package:edulink/domain/entities/announcement.dart";
import "package:edulink/domain/entities/message.dart";
import "package:edulink/domain/entities/profile.dart";

/// Announcements and direct messaging.
class CommunicationRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  // ── Announcements ──
  Future<List<Announcement>> announcements(String instituteId) async {
    final data = await _client
        .from(SupabaseConfig.tAnnouncements)
        .select("*, author:author_id(full_name)")
        .eq("institute_id", instituteId)
        .order("created_at", ascending: false);
    return (data as List).map((e) => Announcement.fromMap(e)).toList();
  }

  Future<Announcement> post(Announcement a) async {
    final data = await _client
        .from(SupabaseConfig.tAnnouncements)
        .insert(a.toMap())
        .select("*, author:author_id(full_name)")
        .single();
    return Announcement.fromMap(data);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _client.from(SupabaseConfig.tAnnouncements).delete().eq("id", id);
  }

  // ── Messages ──
  Future<List<Message>> conversation(String userId, String otherId) async {
    final data = await _client
        .from(SupabaseConfig.tMessages)
        .select("*, sender:sender_id(full_name)")
        .or("and(sender_id.eq.$userId,receiver_id.eq.$otherId),and(sender_id.eq.$otherId,receiver_id.eq.$userId)")
        .order("created_at", ascending: false);
    return (data as List).map((e) => Message.fromMap(e)).toList();
  }

  Future<Message> send(Message m) async {
    final data = await _client
        .from(SupabaseConfig.tMessages)
        .insert(m.toMap())
        .select("*, sender:sender_id(full_name)")
        .single();
    return Message.fromMap(data);
  }

  /// People the current user can message within their institute.
  Future<List<Profile>> contacts(String instituteId, String selfId) async {
    final data = await _client
        .from(SupabaseConfig.tProfiles)
        .select()
        .eq("institute_id", instituteId)
        .neq("id", selfId)
        .order("full_name");
    return (data as List).map((e) => Profile.fromMap(e)).toList();
  }
}
