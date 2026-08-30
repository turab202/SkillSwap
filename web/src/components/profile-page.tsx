'use client';

import React, { useEffect, useState } from 'react';
import { auth } from '@/lib/firebase';
import { UserProfile } from '@/components/user-profile';

export function ProfilePage({ userId }: { userId: string }) {
  const [profileUserId, setProfileUserId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // If userId is passed as prop, use it; otherwise use current user
    if (userId) {
      setProfileUserId(userId);
      setLoading(false);
    } else if (auth.currentUser) {
      setProfileUserId(auth.currentUser.uid);
      setLoading(false);
    } else {
      // Wait for auth to be ready
      const unsubscribe = auth.onAuthStateChanged((user) => {
        if (user) {
          setProfileUserId(user.uid);
        }
        setLoading(false);
      });
      return () => unsubscribe();
    }
  }, [userId]);

  if (loading || !profileUserId) {
    return (
      <div className="workspace-page">
        <div style={{ textAlign: 'center', padding: '40px' }}>Loading...</div>
      </div>
    );
  }

  return (
    <div className="workspace-page">
      <div style={{ maxWidth: '900px', margin: '0 auto', padding: '20px' }}>
        <UserProfile userId={profileUserId} />
      </div>
    </div>
  );
}
