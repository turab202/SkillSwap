import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_model.dart';
import '../models/event_model.dart';
import '../models/resource_model.dart';
import '../../../core/services/firestore_service.dart';

class CommunityRepository {
  // ── Communities ────────────────────────────────────────────────────────────
  Stream<List<CommunityModel>> watchCommunities() =>
      FirestoreService.communities
          .limit(30)
          .snapshots()
          .map((s) => s.docs.map(CommunityModel.fromFirestore).toList());

  Stream<List<CommunityModel>> watchUserCommunities(String userId) =>
      FirestoreService.communities
          .where('memberIds', arrayContains: userId)
          .snapshots()
          .map((s) => s.docs.map(CommunityModel.fromFirestore).toList());

  Future<void> joinCommunity(String communityId, String userId) =>
      FirestoreService.communities.doc(communityId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
      });

  Future<void> leaveCommunity(String communityId, String userId) =>
      FirestoreService.communities.doc(communityId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
      });

  Future<void> createCommunity(CommunityModel community) =>
      FirestoreService.communities.add(community.toMap());

  // ── Events ─────────────────────────────────────────────────────────────────
  Stream<List<EventModel>> watchUpcomingEvents() =>
      FirestoreService.events
          .limit(20)
          .snapshots()
          .map((s) => s.docs.map(EventModel.fromFirestore).toList());

  Future<void> attendEvent(String eventId, String userId) =>
      FirestoreService.events.doc(eventId).update({
        'attendeeIds': FieldValue.arrayUnion([userId]),
      });

  Future<void> unattendEvent(String eventId, String userId) =>
      FirestoreService.events.doc(eventId).update({
        'attendeeIds': FieldValue.arrayRemove([userId]),
      });

  Future<void> createEvent(EventModel event) =>
      FirestoreService.events.add(event.toMap());

  // ── Resources / Library ────────────────────────────────────────────────────
  Stream<List<ResourceModel>> watchResources({String? category}) {
    Query q = FirestoreService.resources.limit(30);
    if (category != null && category != 'All') {
      q = FirestoreService.resources
          .where('category', isEqualTo: category)
          .limit(30);
    }
    return q.snapshots().map((s) => s.docs.map(ResourceModel.fromFirestore).toList());
  }

  Future<void> saveResource(String resourceId, String userId) =>
      FirestoreService.resources.doc(resourceId).update({
        'savedByIds': FieldValue.arrayUnion([userId]),
      });

  Future<void> unsaveResource(String resourceId, String userId) =>
      FirestoreService.resources.doc(resourceId).update({
        'savedByIds': FieldValue.arrayRemove([userId]),
      });

  Future<void> createResource(ResourceModel resource) =>
      FirestoreService.resources.add(resource.toMap());

  // ── Volunteer posts (reuse posts collection with type=volunteer) ───────────
  Stream<QuerySnapshot> watchVolunteerPosts() =>
      FirestoreService.posts
          .where('type', isEqualTo: 'volunteer')
          .limit(20)
          .snapshots();

  // ── Mentorship posts (reuse posts collection with type=mentorship) ─────────
  Stream<QuerySnapshot> watchMentorshipPosts() =>
      FirestoreService.posts
          .where('type', isEqualTo: 'mentorship')
          .limit(20)
          .snapshots();

  // ── Community projects (reuse posts collection) ────────────────────────────
  Stream<QuerySnapshot> watchCommunityProjects() =>
      FirestoreService.posts
          .where('type', isEqualTo: 'community_project')
          .limit(20)
          .snapshots();
}
