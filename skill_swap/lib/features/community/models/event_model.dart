import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime eventDate;
  final List<String> attendeeIds;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final String category;
  final bool isVirtual;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.eventDate,
    required this.attendeeIds,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.category,
    required this.isVirtual,
  });

  int get attendeeCount => attendeeIds.length;
  bool isAttending(String uid) => attendeeIds.contains(uid);

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      location: d['location'] ?? '',
      eventDate: (d['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attendeeIds: List<String>.from(d['attendeeIds'] ?? []),
      createdBy: d['createdBy'] ?? '',
      createdByName: d['createdByName'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: d['category'] ?? '',
      isVirtual: d['isVirtual'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'location': location,
        'eventDate': Timestamp.fromDate(eventDate),
        'attendeeIds': attendeeIds,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': Timestamp.fromDate(createdAt),
        'category': category,
        'isVirtual': isVirtual,
      };
}
