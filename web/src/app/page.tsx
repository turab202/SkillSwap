 'use client';

import { useEffect, useState } from 'react';
import { onAuthStateChanged, type User } from 'firebase/auth';
import { auth } from '@/lib/firebase';
import { AuthForm } from '@/components/auth-form';
import { DiscoverShell } from '@/components/discover-shell';

export default function HomePage() {
  const [user, setUser] = useState<User | null>(null);
  const [checkingAuth, setCheckingAuth] = useState(true);

  useEffect(() => onAuthStateChanged(auth, (nextUser) => {
    setUser(nextUser);
    setCheckingAuth(false);
  }), []);

  if (checkingAuth) return <main className="auth-loading">Loading SkillSwap...</main>;
  if (user) return <DiscoverShell currentUid={user.uid} />;

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
