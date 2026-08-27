import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? location;
  final List<String> skillsOffered;
  final List<String> skillsWanted;
  final String experienceLevel;
  final String availability;
  final String bio;
  final bool profileComplete;
  final DateTime createdAt;
  // Community impact
  final int peopleHelped;
  final int skillsShared;
  final int projectsJoined;
  final int mentorshipSessions;
  final int volunteerActivities;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.location,
    this.skillsOffered = const [],
    this.skillsWanted = const [],
    this.experienceLevel = 'Novice',
    this.availability = '',
    this.bio = '',
    this.profileComplete = false,
    required this.createdAt,
    this.peopleHelped = 0,
    this.skillsShared = 0,
    this.projectsJoined = 0,
    this.mentorshipSessions = 0,
    this.volunteerActivities = 0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      return UserModel(
        uid: doc.id,
        email: '',
        displayName: '',
        createdAt: DateTime.now(),
      );
    }
    final d = data as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: d['email'] ?? '',
      displayName: d['displayName'] ?? '',
      photoUrl: d['photoUrl'],
      location: d['location'],
      skillsOffered: List<String>.from(d['skillsOffered'] ?? []),
      skillsWanted: List<String>.from(d['skillsWanted'] ?? []),
      experienceLevel: d['experienceLevel'] ?? 'Novice',
      availability: d['availability'] ?? '',
      bio: d['bio'] ?? '',
      profileComplete: d['profileComplete'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      peopleHelped: d['peopleHelped'] ?? 0,
      skillsShared: d['skillsShared'] ?? 0,
      projectsJoined: d['projectsJoined'] ?? 0,
      mentorshipSessions: d['mentorshipSessions'] ?? 0,
      volunteerActivities: d['volunteerActivities'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'location': location,
        'skillsOffered': skillsOffered,
        'skillsWanted': skillsWanted,
        'experienceLevel': experienceLevel,
        'availability': availability,
        'bio': bio,
        'profileComplete': profileComplete,
        'createdAt': Timestamp.fromDate(createdAt),
        'peopleHelped': peopleHelped,
        'skillsShared': skillsShared,
        'projectsJoined': projectsJoined,
        'mentorshipSessions': mentorshipSessions,
        'volunteerActivities': volunteerActivities,
      };

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? location,
    List<String>? skillsOffered,
    List<String>? skillsWanted,
    String? experienceLevel,
    String? availability,
    String? bio,
    bool? profileComplete,
    int? peopleHelped,
    int? skillsShared,
    int? projectsJoined,
    int? mentorshipSessions,
    int? volunteerActivities,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        location: location ?? this.location,
        skillsOffered: skillsOffered ?? this.skillsOffered,
        skillsWanted: skillsWanted ?? this.skillsWanted,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        availability: availability ?? this.availability,
        bio: bio ?? this.bio,
        profileComplete: profileComplete ?? this.profileComplete,
        createdAt: createdAt,
        peopleHelped: peopleHelped ?? this.peopleHelped,
        skillsShared: skillsShared ?? this.skillsShared,
        projectsJoined: projectsJoined ?? this.projectsJoined,
        mentorshipSessions: mentorshipSessions ?? this.mentorshipSessions,
        volunteerActivities: volunteerActivities ?? this.volunteerActivities,
      );

  /// AI-generated reason why this user matches the current viewer
  String matchReason(UserModel viewer) {
    final sharedTeach = skillsOffered.where((s) => viewer.skillsWanted.contains(s)).toList();
    final sharedLearn = skillsWanted.where((s) => viewer.skillsOffered.contains(s)).toList();
    final parts = <String>[];
    if (sharedTeach.isNotEmpty) parts.add('teaches ${sharedTeach.take(2).join(" & ")} which you want to learn');
    if (sharedLearn.isNotEmpty) parts.add('wants to learn ${sharedLearn.take(2).join(" & ")} which you offer');
    if (location != null && viewer.location != null && location == viewer.location) parts.add('is in your area');
    if (availability.isNotEmpty && viewer.availability.isNotEmpty && availability == viewer.availability) parts.add('shares your availability');
    if (parts.isEmpty) return 'has complementary skills that match your profile.';
    return '${parts.join(", ")}.';
  }

  int matchScore(UserModel viewer) {
    int score = 0;
    score += skillsOffered.where((s) => viewer.skillsWanted.contains(s)).length * 25;
    score += skillsWanted.where((s) => viewer.skillsOffered.contains(s)).length * 25;
    if (location != null && viewer.location != null && location == viewer.location) score += 20;
    if (availability.isNotEmpty && availability == viewer.availability) score += 10;
    return score.clamp(0, 100);
  }
}
