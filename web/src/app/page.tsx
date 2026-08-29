 'use client';

import { useEffect, useState } from 'react';
import { onAuthStateChanged, type User } from 'firebase/auth';
import { auth } from '@/lib/firebase';
import { AuthForm } from '@/components/auth-form';
import { Dashboard } from '@/components/dashboard';
import { DiscoverShell } from '@/components/discover-shell';
import { Collaborations } from '@/components/collaborations';
import { Posts } from '@/components/posts';
import { Messaging } from '@/components/messaging';
import { Notifications } from '@/components/notifications';

export default function HomePage() {
  const [user, setUser] = useState<User | null>(null);
  const [checkingAuth, setCheckingAuth] = useState(true);
  const [section, setSection] = useState<'dashboard' | 'discover' | 'profile' | 'collaborations' | 'posts' | 'messaging' | 'notifications'>('dashboard');

  useEffect(() => onAuthStateChanged(auth, (nextUser) => {
    setUser(nextUser);
    setCheckingAuth(false);
  }), []);

  if (checkingAuth) return <main className="auth-loading">Loading SkillSwap...</main>;
  if (user) {
    if (section === 'discover') return <DiscoverShell currentUid={user.uid} onNavigate={setSection} currentSection={section} />;
    if (section === 'posts') return <Posts currentUid={user.uid} onNavigate={setSection} currentSection={section} />;
    if (section === 'messaging') return <Messaging currentUid={user.uid} onNavigate={setSection} currentSection={section} />;
    if (section === 'notifications') return <Notifications currentUid={user.uid} onNavigate={setSection} currentSection={section} />;
    if (section === 'collaborations') return <Collaborations currentUid={user.uid} onNavigate={setSection} currentSection={section} />;
    return <Dashboard currentUid={user.uid} onNavigate={setSection} currentSection={section} />;
  }

  return (
    <main className="auth-page">
      <div className="auth-intro">
        <p className="eyebrow">SKILLSWAP WEB</p>
        <h1>Exchange what you know. Discover what is next.</h1>
        <p>Join a local network where practical knowledge moves between neighbors, makers, mentors, and curious people.</p>
      </div>
      <AuthForm />
    </main>
  );
}
