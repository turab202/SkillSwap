'use client';

import { useEffect, useState } from 'react';
import { doc, getDoc } from 'firebase/firestore';
import { signOut } from 'firebase/auth';
import { auth, db } from '@/lib/firebase';
import type { UserModel } from '@/lib/models';

interface DashboardProps {
  currentUid: string;
  onNavigate: (section: 'dashboard' | 'discover' | 'profile' | 'collaborations') => void;
  currentSection: string;
}

export function Dashboard({ currentUid, onNavigate, currentSection }: DashboardProps) {
  const [user, setUser] = useState<UserModel | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadUser() {
      try {
        const snapshot = await getDoc(doc(db, 'users', currentUid));
        const data = snapshot.data();
        if (data) {
          setUser({
            uid: snapshot.id,
            email: String(data.email ?? ''),
            displayName: String(data.displayName ?? 'SkillSwap member'),
            photoUrl: typeof data.photoUrl === 'string' ? data.photoUrl : null,
            location: typeof data.location === 'string' ? data.location : null,
            skillsOffered: Array.isArray(data.skillsOffered) ? data.skillsOffered.map(String) : [],
            skillsWanted: Array.isArray(data.skillsWanted) ? data.skillsWanted.map(String) : [],
            experienceLevel: String(data.experienceLevel ?? 'Novice'),
            availability: String(data.availability ?? ''),
            bio: String(data.bio ?? ''),
            profileComplete: Boolean(data.profileComplete),
            createdAt: data.createdAt,
            peopleHelped: Number(data.peopleHelped ?? 0),
            skillsShared: Number(data.skillsShared ?? 0),
            projectsJoined: Number(data.projectsJoined ?? 0),
            mentorshipSessions: Number(data.mentorshipSessions ?? 0),
            volunteerActivities: Number(data.volunteerActivities ?? 0),
          });
        }
      } catch (error) {
        console.error('Failed to load user:', error);
      } finally {
        setLoading(false);
      }
    }
    void loadUser();
  }, [currentUid]);

  const firstName = user?.displayName.split(' ')[0] ?? 'there';

  return (
    <main className="workspace-page">
      <aside className="workspace-sidebar">
        <div className="brand-mark"><span>SS</span><strong>SkillSwap</strong></div>
        <nav aria-label="Primary navigation">
          <button className={`nav-link nav-button ${currentSection === 'dashboard' ? 'active' : ''}`} onClick={() => onNavigate('dashboard')} type="button">Home</button>
          <button className={`nav-link nav-button ${currentSection === 'discover' ? 'active' : ''}`} onClick={() => onNavigate('discover')} type="button">Discover</button>
          <button className={`nav-link nav-button ${currentSection === 'collaborations' ? 'active' : ''}`} onClick={() => onNavigate('collaborations')} type="button">Collaborations</button>
          <button className={`nav-link nav-button ${currentSection === 'profile' ? 'active' : ''}`} onClick={() => onNavigate('profile')} type="button">My profile</button>
        </nav>
        <button className="sign-out" type="button" onClick={() => signOut(auth)}>Sign out</button>
      </aside>

      <section className="discover-content" id="dashboard">
        <header className="workspace-header">
          <div>
            <p className="eyebrow">WELCOME BACK</p>
            <h1>Ready to grow your skills, {firstName}?</h1>
            <p>See your progress and continue where you left off.</p>
          </div>
          <div className="user-avatar">{user?.displayName?.slice(0, 1).toUpperCase() ?? 'U'}</div>
        </header>

        {loading ? (
          <p className="state-message">Loading your profile...</p>
        ) : !user?.profileComplete ? (
          <div className="alert-box">
            <p><strong>Complete your profile</strong> so others can find you.</p>
            <button className="primary-button" onClick={() => onNavigate('profile')} type="button">Edit profile</button>
          </div>
        ) : null}

        <div className="impact-grid">
          <div className="impact-tile">
            <div className="impact-icon">🤝</div>
            <div className="impact-stat">{user?.peopleHelped ?? 0}</div>
            <div className="impact-label">People Helped</div>
          </div>
          <div className="impact-tile">
            <div className="impact-icon">📚</div>
            <div className="impact-stat">{user?.skillsShared ?? 0}</div>
            <div className="impact-label">Skills Shared</div>
          </div>
          <div className="impact-tile">
            <div className="impact-icon">🎯</div>
            <div className="impact-stat">{user?.projectsJoined ?? 0}</div>
            <div className="impact-label">Projects Joined</div>
          </div>
          <div className="impact-tile">
            <div className="impact-icon">💡</div>
            <div className="impact-stat">{user?.mentorshipSessions ?? 0}</div>
            <div className="impact-label">Mentorship Sessions</div>
          </div>
        </div>

        <div className="quick-actions">
          <button className="action-card" onClick={() => onNavigate('discover')} type="button">
            <span className="action-icon">🔍</span>
            <span className="action-title">Discover</span>
            <span className="action-desc">Find people who can teach you</span>
          </button>
          <button className="action-card" onClick={() => onNavigate('profile')} type="button">
            <span className="action-icon">✏️</span>
            <span className="action-title">Edit profile</span>
            <span className="action-desc">Update your skills and bio</span>
          </button>
          <button className="action-card" onClick={() => onNavigate('collaborations')} type="button">
            <span className="action-icon">🤲</span>
            <span className="action-title">Collaborations</span>
            <span className="action-desc">View your skill swaps</span>
          </button>
        </div>

        {user?.skillsOffered && user.skillsOffered.length > 0 && (
          <div className="skills-section">
            <h3>Your Skills</h3>
            <div className="skill-tags">
              {user.skillsOffered.map((skill) => <span key={skill}>{skill}</span>)}
            </div>
          </div>
        )}
      </section>
    </main>
  );
}
