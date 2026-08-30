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
    <div className="auth-form-container">
      <form className="auth-form" onSubmit={submit}>
        <h2>{mode === 'signin' ? 'Sign in' : 'Create account'}</h2>
        <p className="subtitle">Use the same account as the mobile app.</p>

        <div className="auth-tabs" role="tablist">
          <button 
            className={`auth-tab-btn ${mode === 'signin' ? 'active' : ''}`}
            onClick={() => { setMode('signin'); setMessage(''); }} 
            type="button"
            role="tab"
            aria-selected={mode === 'signin'}
          >
            Sign in
          </button>
          <button 
            className={`auth-tab-btn ${mode === 'signup' ? 'active' : ''}`}
            onClick={() => { setMode('signup'); setMessage(''); }} 
            type="button"
            role="tab"
            aria-selected={mode === 'signup'}
          >
            Create account
          </button>
        </div>

        {mode === 'signup' && (
          <div className="form-group">
            <label className="form-label" htmlFor="name">Full name</label>
            <input 
              id="name"
              required 
              className="form-input"
              value={name} 
              onChange={(event) => setName(event.target.value)} 
              placeholder="Alex Rivera"
              type="text"
            />
          </div>
        )}

        <div className="form-group">
          <label className="form-label" htmlFor="email">Email</label>
          <input 
            id="email"
            required 
            type="email" 
            className="form-input"
            value={email} 
            onChange={(event) => setEmail(event.target.value)} 
            placeholder="you@example.com" 
          />
        </div>

        <div className="form-group">
          <label className="form-label" htmlFor="password">Password</label>
          <input 
            id="password"
            required 
            minLength={6} 
            type="password" 
            className="form-input"
            value={password} 
            onChange={(event) => setPassword(event.target.value)} 
            placeholder="At least 6 characters" 
          />
        </div>

        {message && (
          <div className={`form-message ${message.includes('failed') || message.includes('error') || message.includes('Error') ? 'error' : 'success'}`} role="status">
            {message}
          </div>
        )}

        <button 
          className="btn btn-primary" 
          disabled={busy} 
          type="submit"
        >
          {busy ? 'Working...' : mode === 'signin' ? 'Sign in' : 'Create account'}
        </button>
      </form>

      <div className="divider">or</div>

      <button 
        className="google-btn" 
        disabled={busy} 
        onClick={signInWithGoogle} 
        type="button"
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
          <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
          <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
          <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
          <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
        </svg>
        Continue with Google
      </button>
    </div>
  );
}
