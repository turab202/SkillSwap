'use client';

import React, { useState, useEffect } from 'react';
import { auth, db } from '@/lib/firebase';
import {
  collection,
  query,
  where,
  getDocs,
  doc,
  getDoc,
  addDoc,
  serverTimestamp,
} from 'firebase/firestore';
import type { UserModel, EndorsementModel, ReviewModel } from '@/lib/models';

interface UserProfileProps {
  userId: string;
  onClose?: () => void;
}

export function UserProfile({ userId, onClose }: UserProfileProps) {
  const [currentUserUid, setCurrentUserUid] = useState<string | null>(null);
  const [profile, setProfile] = useState<UserModel | null>(null);
  const [endorsements, setEndorsements] = useState<Record<string, number>>({});
  const [reviews, setReviews] = useState<ReviewModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'about' | 'reviews'>('about');
  const [endorsementOpen, setEndorsementOpen] = useState(false);
  const [endorsementBusy, setEndorsementBusy] = useState(false);
  const [endorsementMessage, setEndorsementMessage] = useState('');
  const [selectedBadge, setSelectedBadge] = useState('');

  useEffect(() => {
    // Get current user UID
    setCurrentUserUid(auth.currentUser?.uid || null);
  }, []);

  const isOwnProfile = currentUserUid === userId;

  useEffect(() => {
    const loadProfile = async () => {
      try {
        setLoading(true);

        // Load user profile
        const userDoc = await getDoc(doc(db, 'users', userId));
        if (userDoc.exists()) {
          setProfile(userDoc.data() as UserModel);
        }

        // Load endorsements
        const endorsementsSnap = await getDocs(
          query(collection(db, 'endorsements'), where('toUserId', '==', userId))
        );
        const counts: Record<string, number> = {};
        endorsementsSnap.docs.forEach((doc) => {
          const data = doc.data() as EndorsementModel;
          counts[data.badge] = (counts[data.badge] || 0) + 1;
        });
        setEndorsements(counts);

        // Load reviews
        const reviewsSnap = await getDocs(
          query(collection(db, 'reviews'), where('toUserId', '==', userId))
        );
        const reviewsList = reviewsSnap.docs.map((doc) => doc.data() as ReviewModel);
        setReviews(reviewsList);
      } catch (error) {
        console.error('Error loading profile:', error);
      } finally {
        setLoading(false);
      }
    };

    loadProfile();
  }, [userId]);

  const badgeIcons: Record<string, { emoji: string; color: string }> = {
    Helpful: { emoji: '🤝', color: '#16A34A' },
    Professional: { emoji: '⭐', color: '#0369A1' },
    Patient: { emoji: '🧘', color: '#7C3AED' },
    Creative: { emoji: '🎨', color: '#B45309' },
    Reliable: { emoji: '✅', color: '#0369A1' },
    'Excellent Teacher': { emoji: '📚', color: '#1B5E20' },
    Supportive: { emoji: '❤️', color: '#DC2626' },
  };

  const badgeOptions = [
    'Helpful',
    'Professional',
    'Patient',
    'Creative',
    'Reliable',
    'Excellent Teacher',
    'Supportive',
  ];

  async function submitEndorsement() {
    if (!selectedBadge.trim() || !auth.currentUser?.uid) {
      setEndorsementMessage('Please select a badge.');
      return;
    }

    setEndorsementBusy(true);
    setEndorsementMessage('');
    try {
      await addDoc(collection(db, 'endorsements'), {
        fromUserId: auth.currentUser.uid,
        fromUserName: auth.currentUser.displayName || 'SkillSwap member',
        toUserId: userId,
        badge: selectedBadge,
        createdAt: serverTimestamp(),
      });
      setEndorsementMessage('Endorsement sent! ✓');
      setTimeout(() => {
        setEndorsementOpen(false);
        setSelectedBadge('');
        // Reload endorsements
        loadEndorsements();
      }, 1000);
    } catch (error) {
      setEndorsementMessage(
        error instanceof Error ? error.message : 'Could not send endorsement.'
      );
    } finally {
      setEndorsementBusy(false);
    }
  }

  async function loadEndorsements() {
    try {
      const endorsementsSnap = await getDocs(
        query(collection(db, 'endorsements'), where('toUserId', '==', userId))
      );
      const counts: Record<string, number> = {};
      endorsementsSnap.docs.forEach((doc) => {
        const data = doc.data() as EndorsementModel;
        counts[data.badge] = (counts[data.badge] || 0) + 1;
      });
      setEndorsements(counts);
    } catch (error) {
      console.error('Error loading endorsements:', error);
    }
  }

  const avgRating =
    reviews.length > 0
      ? (reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length).toFixed(1)
      : null;

  if (loading) {
    return (
      <div className="user-profile">
        <div className="profile-spinner">Loading profile...</div>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="user-profile">
        <div className="profile-error">User profile not found</div>
      </div>
    );
  }

  return (
    <div className="user-profile">
      {/* Profile Header */}
      <div className="profile-header">
        <div className="profile-header-bg" />
        <div className="profile-header-content">
          {/* Close button for modal */}
          {onClose && (
            <button className="profile-close-btn" onClick={onClose}>
              ✕
            </button>
          )}

          <div className="profile-avatar-section">
            {profile.photoUrl ? (
              <img
                src={profile.photoUrl}
                alt={profile.displayName}
                className="profile-avatar"
              />
            ) : (
              <div className="profile-avatar-initial">
                {profile.displayName.charAt(0).toUpperCase()}
              </div>
            )}

            <div className="profile-basic-info">
              <h1 className="profile-name">{profile.displayName}</h1>
              {profile.location && (
                <div className="profile-location">
                  📍 {profile.location}
                </div>
              )}
              <div className="profile-level">
                {profile.experienceLevel}
              </div>
            </div>
          </div>

          {!isOwnProfile && (
            <div className="profile-actions">
              <button className="btn-primary btn-skill-swap">
                Start Skill Swap
              </button>
              <button 
                className="btn-secondary btn-message"
                onClick={() => setEndorsementOpen(true)}
              >
                Give Endorsement
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Community Impact Stats */}
      <div className="community-impact">
        <h2>Community Impact</h2>
        <div className="impact-stats">
          <div className="stat-card">
            <div className="stat-value">{profile.peopleHelped}</div>
            <div className="stat-label">People Helped</div>
          </div>
          <div className="stat-card">
            <div className="stat-value">{profile.skillsShared}</div>
            <div className="stat-label">Skills Shared</div>
          </div>
          <div className="stat-card">
            <div className="stat-value">{profile.projectsJoined}</div>
            <div className="stat-label">Projects Joined</div>
          </div>
          <div className="stat-card">
            <div className="stat-value">{profile.mentorshipSessions}</div>
            <div className="stat-label">Mentorship</div>
          </div>
          <div className="stat-card">
            <div className="stat-value">{profile.volunteerActivities}</div>
            <div className="stat-label">Volunteer</div>
          </div>
        </div>
      </div>

      {/* Endorsement Badges */}
      {Object.keys(endorsements).length > 0 && (
        <div className="endorsements-section">
          <h2>Appreciation Badges</h2>
          <div className="badges-grid">
            {Object.entries(endorsements).map(([badge, count]) => {
              const badgeInfo = badgeIcons[badge] || { emoji: '✨', color: '#1B5E20' };
              return (
                <div
                  key={badge}
                  className="badge-item"
                  style={{ borderColor: badgeInfo.color }}
                >
                  <span className="badge-emoji">{badgeInfo.emoji}</span>
                  <span className="badge-name">{badge}</span>
                  <span className="badge-count" style={{ backgroundColor: badgeInfo.color }}>
                    {count}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Skills and Bio */}
      {profile.bio && (
        <div className="about-section">
          <h2>About</h2>
          <p className="bio-text">{profile.bio}</p>
        </div>
      )}

      {profile.skillsOffered.length > 0 && (
        <div className="skills-section">
          <h3>Skills Offered</h3>
          <div className="skills-wrap">
            {profile.skillsOffered.map((skill) => (
              <span key={skill} className="skill-chip skill-offered">
                {skill}
              </span>
            ))}
          </div>
        </div>
      )}

      {profile.skillsWanted.length > 0 && (
        <div className="skills-section">
          <h3>Skills Wanted</h3>
          <div className="skills-wrap">
            {profile.skillsWanted.map((skill) => (
              <span key={skill} className="skill-chip skill-wanted">
                {skill}
              </span>
            ))}
          </div>
        </div>
      )}

      {/* Tabs for Reviews */}
      {reviews.length > 0 && (
        <div className="reviews-section">
          <h2>
            Reviews
            {avgRating && <span className="avg-rating">⭐ {avgRating}</span>}
          </h2>
          <div className="reviews-list">
            {reviews.map((review) => (
              <div key={review.id} className="review-card">
                <div className="review-header">
                  <div className="review-author">
                    {review.fromUserPhoto ? (
                      <img
                        src={review.fromUserPhoto}
                        alt={review.fromUserName}
                        className="review-avatar"
                      />
                    ) : (
                      <div className="review-avatar-initial">
                        {review.fromUserName.charAt(0).toUpperCase()}
                      </div>
                    )}
                    <div>
                      <div className="review-name">{review.fromUserName}</div>
                      <div className="review-rating">
                        {'⭐'.repeat(review.rating)}
                      </div>
                    </div>
                  </div>
                </div>
                <p className="review-text">{review.comment}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      {reviews.length === 0 && Object.keys(endorsements).length === 0 && (
        <div className="empty-state">
          <p>No reviews or endorsements yet</p>
        </div>
      )}

      {/* Endorsement Modal */}
      {endorsementOpen && (
        <div className="endorsement-backdrop" onClick={() => setEndorsementOpen(false)}>
          <div className="endorsement-modal" onClick={(e) => e.stopPropagation()}>
            <button 
              className="endorsement-close"
              onClick={() => setEndorsementOpen(false)}
            >
              ✕
            </button>
            <h2>Give Endorsement</h2>
            <p className="endorsement-subtitle">
              Recognize {profile.displayName}&apos;s qualities
            </p>
            
            <div className="badge-selection">
              {badgeOptions.map((badge) => (
                <button
                  key={badge}
                  className={`badge-option ${selectedBadge === badge ? 'selected' : ''}`}
                  onClick={() => setSelectedBadge(badge)}
                >
                  {badge}
                </button>
              ))}
            </div>

            {endorsementMessage && (
              <div className={`endorsement-message ${endorsementMessage.includes('✓') ? 'success' : 'error'}`}>
                {endorsementMessage}
              </div>
            )}

            <button
              className="btn-primary"
              onClick={submitEndorsement}
              disabled={endorsementBusy || !selectedBadge}
            >
              {endorsementBusy ? 'Sending...' : 'Send Endorsement'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
