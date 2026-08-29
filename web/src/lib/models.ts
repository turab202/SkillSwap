import type { Timestamp } from 'firebase/firestore';

export type FirestoreDate = Timestamp | Date;

export interface UserModel {
  uid: string;
  email: string;
  displayName: string;
  photoUrl?: string | null;
  location?: string | null;
  skillsOffered: string[];
  skillsWanted: string[];
  experienceLevel: string;
  availability: string;
  bio: string;
  profileComplete: boolean;
  createdAt: FirestoreDate;
  peopleHelped: number;
  skillsShared: number;
  projectsJoined: number;
  mentorshipSessions: number;
  volunteerActivities: number;
}

export interface CommunityModel {
  id: string;
  name: string;
  description: string;
  category: string;
  memberIds: string[];
  createdBy: string;
  createdAt: FirestoreDate;
  imageUrl?: string | null;
}

export interface PostModel {
  id: string;
  title: string;
  description: string;
  category: string;
  type: string;
  userId: string;
  userName: string;
  userPhoto?: string | null;
  status: string;
  participantIds?: string[];
  createdAt: FirestoreDate;
  location?: string;
}

export interface CollaborationModel {
  id: string;
  requesterId: string;
  requesterName: string;
  requesterPhoto?: string | null;
  targetId: string;
  targetName: string;
  targetPhoto?: string | null;
  skillOffered: string;
  skillWanted: string;
  status: 'pending' | 'accepted' | 'inProgress' | 'completed' | 'cancelled';
  message?: string | null;
  createdAt: FirestoreDate;
  scheduledAt?: FirestoreDate | null;
  completedAt?: FirestoreDate | null;
}

export interface MessageModel {
  id: string;
  senderId: string;
  senderName: string;
  text: string;
  createdAt: FirestoreDate;
}

export interface ChatModel {
  id: string;
  participantIds: string[];
  participantNames: Record<string, string>;
  participantPhotos: Record<string, string | null>;
  lastMessage: string;
  lastAt: FirestoreDate;
  unreadCounts: Record<string, number>;
}
