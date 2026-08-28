'use client';

import { useEffect, useMemo, useState } from 'react';
import { collection, getDocs, limit, query, where } from 'firebase/firestore';
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

export function DiscoverShell({ currentUid }: { currentUid: string }) {
  const [people, setPeople] = useState<UserModel[]>([]);
  const [search, setSearch] = useState('');
  const [skill, setSkill] = useState('All skills');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [selectedPerson, setSelectedPerson] = useState<UserModel | null>(null);

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

  return (
    <main className="workspace-page">
      <aside className="workspace-sidebar">
        <div className="brand-mark"><span>SS</span><strong>SkillSwap</strong></div>
        <nav aria-label="Primary navigation">
          <a className="nav-link active" href="#discover">Discover</a>
          <a className="nav-link" href="#collaborations">Collaborations</a>
          <a className="nav-link" href="#communities">Communities</a>
          <a className="nav-link" href="#profile">My profile</a>
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
          </section>
        </div>}
      </section>
    </main>
  );
}