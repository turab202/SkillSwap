'use client';

import { useState } from 'react';
import {
  GoogleAuthProvider,
  browserLocalPersistence,
  createUserWithEmailAndPassword,
  setPersistence,
  signInWithEmailAndPassword,
  signInWithPopup,
  updateProfile,
} from 'firebase/auth';
import { auth, db } from '@/lib/firebase';
import { doc, serverTimestamp, setDoc } from 'firebase/firestore';

export function AuthForm() {
  const [mode, setMode] = useState<'signin' | 'signup'>('signin');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);

  async function saveUserDocument(uid: string, userEmail: string, displayName: string, photoUrl?: string | null) {
    await setDoc(doc(db, 'users', uid), {
      uid,
      email: userEmail,
      displayName,
      photoUrl: photoUrl ?? null,
      profileComplete: false,
      skillsOffered: [],
      skillsWanted: [],
      experienceLevel: 'Novice',
      availability: '',
      bio: '',
      createdAt: serverTimestamp(),
      peopleHelped: 0,
      skillsShared: 0,
      projectsJoined: 0,
      mentorshipSessions: 0,
      volunteerActivities: 0,
    }, { merge: true });
  }

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setBusy(true);
    setMessage('');
    try {
      await setPersistence(auth, browserLocalPersistence);
      if (mode === 'signup') {
        const result = await createUserWithEmailAndPassword(auth, email.trim(), password);
        await updateProfile(result.user, { displayName: name.trim() });
        await saveUserDocument(result.user.uid, email.trim(), name.trim());
        setMessage('Account created.');
      } else {
        await signInWithEmailAndPassword(auth, email.trim(), password);
        setMessage('Signed in.');
      }
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Authentication failed.');
    } finally {
      setBusy(false);
    }
  }

  async function signInWithGoogle() {
    setBusy(true);
    setMessage('');
    try {
      const result = await signInWithPopup(auth, new GoogleAuthProvider());
      await saveUserDocument(result.user.uid, result.user.email ?? '', result.user.displayName ?? 'User', result.user.photoURL);
      setMessage('Signed in with Google.');
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Google Sign-In failed.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="auth-panel">
      <div className="auth-heading">
        <p className="eyebrow">Welcome to SkillSwap</p>
        <h1>{mode === 'signin' ? 'Find your next skill exchange.' : 'Create your SkillSwap account.'}</h1>
        <p>Use the same account and community data as the mobile app.</p>
      </div>
      <div className="auth-tabs" role="tablist">
        <button className={mode === 'signin' ? 'active' : ''} onClick={() => setMode('signin')} type="button">Sign in</button>
        <button className={mode === 'signup' ? 'active' : ''} onClick={() => setMode('signup')} type="button">Create account</button>
      </div>
      <form onSubmit={submit}>
        {mode === 'signup' && <label>Full name<input required value={name} onChange={(event) => setName(event.target.value)} placeholder="Alex Rivera" /></label>}
        <label>Email<input required type="email" value={email} onChange={(event) => setEmail(event.target.value)} placeholder="you@example.com" /></label>
        <label>Password<input required minLength={6} type="password" value={password} onChange={(event) => setPassword(event.target.value)} placeholder="At least 6 characters" /></label>
        <button className="primary-button" disabled={busy} type="submit">{busy ? 'Working...' : mode === 'signin' ? 'Sign in' : 'Create account'}</button>
      </form>
      <div className="auth-divider"><span>or</span></div>
      <button className="google-button" disabled={busy} onClick={signInWithGoogle} type="button">Continue with Google</button>
      {message && <p className="auth-message" role="status">{message}</p>}
    </section>
  );
}
