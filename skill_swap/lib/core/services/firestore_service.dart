import 'package:cloud_firestore/cloud_firestore.dart';

/// Central Firestore service — single source of truth for all collection names
/// and reusable query helpers. Keeps collection names consistent across
/// Flutter and any future React web client.
class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── Collection references ──────────────────────────────────────────────────
  static CollectionReference get users => _db.collection('users');
  static CollectionReference get posts => _db.collection('posts');
  static CollectionReference get collaborations => _db.collection('collaborations');
  static CollectionReference get meetings => _db.collection('meetings');
  static CollectionReference get appreciations => _db.collection('appreciations');
  static CollectionReference get communities => _db.collection('communities');
  static CollectionReference get projects => _db.collection('projects');
  static CollectionReference get events => _db.collection('events');
  static CollectionReference get resources => _db.collection('resources');
  static CollectionReference get notifications => _db.collection('notifications');
  static CollectionReference get messages => _db.collection('messages');
  static CollectionReference get skills => _db.collection('skills');
  static CollectionReference get services => _db.collection('services');

  // ── Impact stats ───────────────────────────────────────────────────────────
  static Future<Map<String, int>> getDailyImpact() async {
    final results = await Future.wait([
      collaborations.where('status', isEqualTo: 'completed').count().get(),
      posts.where('type', isEqualTo: 'offer_skill').count().get(),
      collaborations.where('status', isEqualTo: 'in_progress').count().get(),
      projects.where('status', isEqualTo: 'active').count().get(),
    ]);

    return {
      'peopleHelped': results[0].count ?? 0,
      'skillsShared': results[1].count ?? 0,
      'activeCollaborations': results[2].count ?? 0,
      'communityProjects': results[3].count ?? 0,
    };
  }

  // ── Appreciation helpers ───────────────────────────────────────────────────
  static Future<Map<String, int>> getAppreciationCounts(String userId) async {
    final snap = await appreciations.where('toUserId', isEqualTo: userId).get();
    final counts = <String, int>{};
    for (final doc in snap.docs) {
      final badge = (doc.data() as Map<String, dynamic>)['badge'] as String? ?? '';
      counts[badge] = (counts[badge] ?? 0) + 1;
    }
    return counts;
  }

  static Future<void> sendAppreciation({
    required String fromUserId,
    required String toUserId,
    required String badge,
    String? note,
  }) =>
      appreciations.add({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'badge': badge,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
