'use client';

import { useEffect, useMemo, useState } from 'react';
import { collection, doc, getDoc, getDocs, limit, query, serverTimestamp, setDoc, where, addDoc } from 'firebase/firestore';
import { signOut } from 'firebase/auth';
import { auth, db } from '@/lib/firebase';
import type { UserModel } from '@/lib/models';

const skillFilters = ['All skills', 'Design', 'Development', 'Marketing', 'Languages', 'Music'];

function asUserModel(id: string, data: Record<string, unknown>): UserModel {
  return {
    uid: id,
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
    createdAt: data.createdAt as UserModel['createdAt'],
    peopleHelped: Number(data.peopleHelped ?? 0),
    skillsShared: Number(data.skillsShared ?? 0),
    projectsJoined: Number(data.projectsJoined ?? 0),
    mentorshipSessions: Number(data.mentorshipSessions ?? 0),
    volunteerActivities: Number(data.volunteerActivities ?? 0),
  };
}

export function DiscoverShell({ currentUid, onNavigate, currentSection }: { currentUid: string; onNavigate?: (section: 'dashboard' | 'discover' | 'profile' | 'collaborations') => void; currentSection?: string }) {
  const [people, setPeople] = useState<UserModel[]>([]);
  const [search, setSearch] = useState('');
  const [skill, setSkill] = useState('All skills');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedPerson, setSelectedPerson] = useState<UserModel | null>(null);
  const [profileOpen, setProfileOpen] = useState(false);
  const [profileBusy, setProfileBusy] = useState(false);
  const [profileMessage, setProfileMessage] = useState('');
  const [profile, setProfile] = useState({ name: '', location: '', offered: '', wanted: '', experience: 'Novice', availability: 'Flexible', bio: '' });
  const [requestOpen, setRequestOpen] = useState(false);
  const [requestBusy, setRequestBusy] = useState(false);
  const [requestMessage, setRequestMessage] = useState('');
  const [skillWanted, setSkillWanted] = useState('');
  const [skillOffered, setSkillOffered] = useState('');
  const [requestText, setRequestText] = useState('');

  useEffect(() => {
    let active = true;
    async function loadPeople() {
      setLoading(true);
      setError('');
      try {
        const peopleQuery = query(
          collection(db, 'users'),
          where('profileComplete', '==', true),
          limit(30),
        );
        const snapshot = await getDocs(peopleQuery);
        if (active) {
          setPeople(snapshot.docs.map((item) => asUserModel(item.id, item.data())));
        }
      } catch (loadError) {
        if (active) setError(loadError instanceof Error ? loadError.message : 'Could not load people.');
      } finally {
        if (active) setLoading(false);
      }
    }
    void loadPeople();
    return () => { active = false; };
  }, []);

  const filteredPeople = useMemo(() => {
    const normalizedSearch = search.trim().toLowerCase();
    return people.filter((person) => {
      if (person.uid === currentUid) return false;
      const matchesSkill = skill === 'All skills' || person.skillsOffered.some((item) => item.toLowerCase().includes(skill.toLowerCase()));
      const matchesSearch = !normalizedSearch || [person.displayName, person.bio, ...person.skillsOffered].join(' ').toLowerCase().includes(normalizedSearch);
      return matchesSkill && matchesSearch;
    });
  }, [currentUid, people, search, skill]);

  async function openProfile() {
    setProfileMessage('');
    setProfileOpen(true);
    const snapshot = await getDoc(doc(db, 'users', currentUid));
    const data = snapshot.data();
    if (data) setProfile({
      name: String(data.displayName ?? auth.currentUser?.displayName ?? ''), location: String(data.location ?? ''),
      offered: Array.isArray(data.skillsOffered) ? data.skillsOffered.join(', ') : '', wanted: Array.isArray(data.skillsWanted) ? data.skillsWanted.join(', ') : '',
      experience: String(data.experienceLevel ?? 'Novice'), availability: String(data.availability ?? 'Flexible'), bio: String(data.bio ?? ''),
    });
  }

  async function saveProfile(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!profile.name.trim()) { setProfileMessage('Name is required.'); return; }
    setProfileBusy(true); setProfileMessage('');
    try {
      await setDoc(doc(db, 'users', currentUid), {
        uid: currentUid, email: auth.currentUser?.email ?? '', displayName: profile.name.trim(), location: profile.location.trim() || null,
        skillsOffered: profile.offered.split(',').map((item) => item.trim()).filter(Boolean), skillsWanted: profile.wanted.split(',').map((item) => item.trim()).filter(Boolean),
        experienceLevel: profile.experience, availability: profile.availability, bio: profile.bio.trim(), profileComplete: true, createdAt: serverTimestamp(),
      }, { merge: true });
      setProfileMessage('Profile saved. Refresh Discover to see your updates.');
    } catch (saveError) { setProfileMessage(saveError instanceof Error ? saveError.message : 'Could not save profile.'); }
    finally { setProfileBusy(false); }
  }

  async function openRequestModal() {
    setRequestMessage('');
    setSkillWanted('');
    setSkillOffered('');
    setRequestText('');
    setRequestOpen(true);
  }

  async function submitRequest(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!skillWanted.trim()) { setRequestMessage('Please select a skill to learn.'); return; }
    if (!skillOffered.trim()) { setRequestMessage('Please select a skill to offer.'); return; }
    if (!selectedPerson) return;
    
    setRequestBusy(true);
    setRequestMessage('');
    try {
      await addDoc(collection(db, 'collaborations'), {
        requesterId: currentUid,
        requesterName: auth.currentUser?.displayName ?? 'SkillSwap member',
        requesterPhoto: auth.currentUser?.photoURL ?? null,
        targetId: selectedPerson.uid,
        targetName: selectedPerson.displayName,
        targetPhoto: selectedPerson.photoUrl ?? null,
        skillOffered: skillOffered.trim(),
        skillWanted: skillWanted.trim(),
        status: 'pending',
        message: requestText.trim() || null,
        createdAt: serverTimestamp(),
      });
      setRequestMessage('Request sent! They will review your offer soon.');
      setRequestOpen(false);
      setSelectedPerson(null);
    } catch (submitError) {
      setRequestMessage(submitError instanceof Error ? submitError.message : 'Could not send request.');
    } finally {
      setRequestBusy(false);
    }
  }

  return (
    <main className="workspace-page">
      <aside className="workspace-sidebar">
        <div className="brand-mark"><span>SS</span><strong>SkillSwap</strong></div>
        <nav aria-label="Primary navigation">
          <button className={`nav-link nav-button ${currentSection === 'dashboard' ? 'active' : ''}`} onClick={() => onNavigate?.('dashboard')} type="button">Home</button>
          <button className={`nav-link nav-button ${currentSection === 'discover' ? 'active' : ''}`} onClick={() => onNavigate?.('discover')} type="button">Discover</button>
          <button className={`nav-link nav-button ${currentSection === 'collaborations' ? 'active' : ''}`} onClick={() => onNavigate?.('collaborations')} type="button">Collaborations</button>
          <button className={`nav-link nav-button ${currentSection === 'profile' ? 'active' : ''}`} onClick={() => void openProfile()} type="button">My profile</button>
        </nav>
        <button className="sign-out" type="button" onClick={() => signOut(auth)}>Sign out</button>
      </aside>

      <section className="discover-content" id="discover">
        <header className="workspace-header">
          <div><p className="eyebrow">DISCOVER</p><h1>People who can help you grow.</h1><p>Find a useful exchange with someone who has the skill you need.</p></div>
          <div className="user-avatar">{auth.currentUser?.displayName?.slice(0, 1).toUpperCase() ?? 'U'}</div>
        </header>
        <div className="discover-toolbar">
          <label className="search-field"><span aria-hidden="true">⌕</span><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search names, skills, or interests" /></label>
          <div className="filter-list" aria-label="Filter by skill">
            {skillFilters.map((filter) => <button className={skill === filter ? 'filter-button active' : 'filter-button'} key={filter} onClick={() => setSkill(filter)} type="button">{filter}</button>)}
          </div>
        </div>
        {loading && <p className="state-message">Loading the community...</p>}
        {error && <p className="state-message error-state">{error}</p>}
        {!loading && !error && filteredPeople.length === 0 && <p className="state-message">No matching members found.</p>}
        <div className="people-grid">
          {filteredPeople.map((person) => (
            <article className="person-card" key={person.uid}>
              {person.photoUrl ? <img className="person-photo" src={person.photoUrl} alt="" /> : <div className="person-photo person-initial">{person.displayName.slice(0, 1).toUpperCase()}</div>}
              <div className="person-card-body"><div className="person-card-heading"><h2>{person.displayName}</h2><span>{person.experienceLevel}</span></div>
                {person.location && <p className="person-location">{person.location}</p>}
                <p className="person-bio">{person.bio || 'Open to a thoughtful skill exchange.'}</p>
                <div className="skill-tags">{person.skillsOffered.slice(0, 4).map((item) => <span key={item}>{item}</span>)}</div>
                <button className="connect-button" onClick={() => setSelectedPerson(person)} type="button">View profile <span aria-hidden="true">→</span></button>
              </div>
            </article>
          ))}
        </div>
        {selectedPerson && <div className="profile-dialog-backdrop" role="presentation" onClick={() => setSelectedPerson(null)}>
          <section className="profile-dialog" role="dialog" aria-modal="true" aria-labelledby="profile-dialog-title" onClick={(event) => event.stopPropagation()}>
            <button className="dialog-close" aria-label="Close profile" onClick={() => setSelectedPerson(null)} type="button">×</button>
            <div className="dialog-avatar">{selectedPerson.displayName.slice(0, 1).toUpperCase()}</div>
            <p className="eyebrow">SKILLSWAP MEMBER</p><h2 id="profile-dialog-title">{selectedPerson.displayName}</h2>
            {selectedPerson.location && <p className="person-location">{selectedPerson.location}</p>}
            <p className="dialog-bio">{selectedPerson.bio || 'Open to a thoughtful skill exchange.'}</p>
            <h3>Offers</h3><div className="skill-tags">{selectedPerson.skillsOffered.map((item) => <span key={item}>{item}</span>)}</div>
            <h3>Wants to learn</h3><div className="skill-tags">{selectedPerson.skillsWanted.length > 0 ? selectedPerson.skillsWanted.map((item) => <span key={item}>{item}</span>) : <span>No skills listed yet</span>}</div>
            <button className="primary-button" onClick={() => openRequestModal()} type="button">Request Skill Swap</button>
          </section>
        </div>}
        {profileOpen && <div className="profile-dialog-backdrop" role="presentation" onClick={() => setProfileOpen(false)}>
          <section className="profile-dialog profile-editor" role="dialog" aria-modal="true" aria-labelledby="profile-editor-title" onClick={(event) => event.stopPropagation()}>
            <button className="dialog-close" aria-label="Close profile editor" onClick={() => setProfileOpen(false)} type="button">×</button>
            <p className="eyebrow">YOUR PROFILE</p><h2 id="profile-editor-title">Tell the community what you bring.</h2>
            <form onSubmit={saveProfile}>
              <label>Full name<input required value={profile.name} onChange={(event) => setProfile({ ...profile, name: event.target.value })} /></label>
              <label>Location<input value={profile.location} onChange={(event) => setProfile({ ...profile, location: event.target.value })} placeholder="City or neighborhood" /></label>
              <label>Skills you offer<input value={profile.offered} onChange={(event) => setProfile({ ...profile, offered: event.target.value })} placeholder="Photography, cooking" /></label>
              <label>Skills you want to learn<input value={profile.wanted} onChange={(event) => setProfile({ ...profile, wanted: event.target.value })} placeholder="Spanish, gardening" /></label>
              <div className="editor-row"><label>Experience<select value={profile.experience} onChange={(event) => setProfile({ ...profile, experience: event.target.value })}><option>Novice</option><option>Expert</option><option>Master</option></select></label><label>Availability<select value={profile.availability} onChange={(event) => setProfile({ ...profile, availability: event.target.value })}><option>Weekdays</option><option>Weekends</option><option>Evenings</option><option>Weekends, Evenings</option><option>Flexible</option></select></label></div>
              <label>About you<textarea rows={3} value={profile.bio} onChange={(event) => setProfile({ ...profile, bio: event.target.value })} /></label>
              <button className="primary-button" disabled={profileBusy} type="submit">{profileBusy ? 'Saving...' : 'Save profile'}</button>
            </form>
            {profileMessage && <p className="auth-message" role="status">{profileMessage}</p>}
          </section>
        </div>}
        {requestOpen && selectedPerson && <div className="profile-dialog-backdrop" role="presentation" onClick={() => setRequestOpen(false)}>
          <section className="profile-dialog profile-editor" role="dialog" aria-modal="true" aria-labelledby="request-title" onClick={(event) => event.stopPropagation()}>
            <button className="dialog-close" aria-label="Close request form" onClick={() => setRequestOpen(false)} type="button">×</button>
            <p className="eyebrow">PROPOSE AN EXCHANGE</p><h2 id="request-title">Skill swap with {selectedPerson.displayName}</h2>
            <form onSubmit={submitRequest}>
              <label>Skill you want to learn<select value={skillWanted} onChange={(event) => setSkillWanted(event.target.value)}><option value="">— Select one of their skills —</option>{selectedPerson.skillsOffered.map((item) => <option key={item} value={item}>{item}</option>)}</select></label>
              <label>Skill you can offer<input value={skillOffered} onChange={(event) => setSkillOffered(event.target.value)} placeholder="Which of your skills would you share?" /></label>
              <label>Message (optional)<textarea rows={3} value={requestText} onChange={(event) => setRequestText(event.target.value)} placeholder="Tell them why you're interested..." /></label>
              <button className="primary-button" disabled={requestBusy} type="submit">{requestBusy ? 'Sending...' : 'Send request'}</button>
            </form>
            {requestMessage && <p className="auth-message" role="status">{requestMessage}</p>}
          </section>
        </div>}
      </section>
    </main>
  );
}