'use client';

import { useEffect, useMemo, useState } from 'react';
import { collection, doc, getDocs, query, serverTimestamp, setDoc, addDoc, where, limit, orderBy, updateDoc, arrayUnion } from 'firebase/firestore';
import { signOut } from 'firebase/auth';
import { auth, db } from '@/lib/firebase';
import type { PostModel } from '@/lib/models';

const postTypes = [
  { value: 'offer_skill', label: 'Offer a Skill' },
  { value: 'offer_service', label: 'Offer a Service' },
  { value: 'request_help', label: 'Request Help' },
  { value: 'community_project', label: 'Community Project' },
  { value: 'volunteer', label: 'Volunteer' },
  { value: 'mentorship', label: 'Mentorship' },
];

const categories = ['Education', 'Design', 'Cooking', 'Gardening', 'Fitness', 'Coding', 'Music', 'Language', 'Crafts', 'Technology'];

function asPostModel(id: string, data: Record<string, unknown>): PostModel {
  return {
    id,
    title: String(data.title ?? ''),
    description: String(data.description ?? ''),
    category: String(data.category ?? 'Education'),
    type: String(data.type ?? 'offer_skill'),
    userId: String(data.userId ?? ''),
    userName: String(data.userName ?? 'Community member'),
    userPhoto: typeof data.userPhoto === 'string' ? data.userPhoto : null,
    status: String(data.status ?? 'active'),
    participantIds: Array.isArray(data.participantIds) ? data.participantIds.map(String) : [],
    createdAt: data.createdAt as PostModel['createdAt'],
    location: typeof data.location === 'string' ? data.location : undefined,
  };
}

export function Posts({ currentUid, onNavigate, currentSection }: { currentUid: string; onNavigate?: (section: 'dashboard' | 'discover' | 'profile' | 'collaborations' | 'posts') => void; currentSection?: string }) {
  const [posts, setPosts] = useState<PostModel[]>([]);
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [createOpen, setCreateOpen] = useState(false);
  const [createBusy, setCreateBusy] = useState(false);
  const [createMessage, setCreateMessage] = useState('');
  const [formData, setFormData] = useState({ type: 'offer_skill', title: '', description: '', category: 'Education', location: '' });

  useEffect(() => {
    let active = true;
    async function loadPosts() {
      setLoading(true);
      setError('');
      try {
        const postsQuery = query(
          collection(db, 'posts'),
          where('status', '==', 'active'),
          orderBy('createdAt', 'desc'),
          limit(50),
        );
        const snapshot = await getDocs(postsQuery);
        if (active) {
          setPosts(snapshot.docs.map((item) => asPostModel(item.id, item.data())));
        }
      } catch (loadError) {
        if (active) setError(loadError instanceof Error ? loadError.message : 'Could not load posts.');
      } finally {
        if (active) setLoading(false);
      }
    }
    void loadPosts();
    return () => { active = false; };
  }, []);

  const filteredPosts = useMemo(() => {
    const normalizedSearch = search.trim().toLowerCase();
    return posts.filter((post) => {
      const matchesType = typeFilter === 'all' || post.type === typeFilter;
      const matchesSearch = !normalizedSearch || [post.title, post.description, post.userName, post.category].join(' ').toLowerCase().includes(normalizedSearch);
      return matchesType && matchesSearch;
    });
  }, [posts, search, typeFilter]);

  async function submitPost(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!formData.title.trim()) { setCreateMessage('Title is required.'); return; }
    if (!formData.description.trim()) { setCreateMessage('Description is required.'); return; }

    setCreateBusy(true);
    setCreateMessage('');
    try {
      await addDoc(collection(db, 'posts'), {
        title: formData.title.trim(),
        description: formData.description.trim(),
        category: formData.category,
        type: formData.type,
        userId: currentUid,
        userName: auth.currentUser?.displayName ?? 'Community member',
        userPhoto: auth.currentUser?.photoURL ?? null,
        status: 'active',
        participantIds: [],
        createdAt: serverTimestamp(),
        ...(formData.location.trim() && { location: formData.location.trim() }),
      });
      setCreateMessage('Post created! It will appear in the feed shortly.');
      setFormData({ type: 'offer_skill', title: '', description: '', category: 'Education', location: '' });
      setCreateOpen(false);
      // Reload posts
      const postsQuery = query(collection(db, 'posts'), where('status', '==', 'active'), orderBy('createdAt', 'desc'), limit(50));
      const snapshot = await getDocs(postsQuery);
      setPosts(snapshot.docs.map((item) => asPostModel(item.id, item.data())));
    } catch (submitError) {
      setCreateMessage(submitError instanceof Error ? submitError.message : 'Could not create post.');
    } finally {
      setCreateBusy(false);
    }
  }

  async function joinPost(postId: string) {
    try {
      await updateDoc(doc(db, 'posts', postId), {
        participantIds: arrayUnion(currentUid),
      });
      // Update local state
      setPosts(posts.map((p) => (p.id === postId ? { ...p, participantIds: [...(p.participantIds || []), currentUid] } : p)));
    } catch (joinError) {
      console.error('Failed to join post:', joinError);
    }
  }

  return (
    <main className="workspace-page">
      <aside className="workspace-sidebar">
        <div className="brand-mark"><span>SS</span><strong>SkillSwap</strong></div>
        <nav aria-label="Primary navigation">
          <button className={`nav-link nav-button ${currentSection === 'dashboard' ? 'active' : ''}`} onClick={() => onNavigate?.('dashboard')} type="button">Home</button>
          <button className={`nav-link nav-button ${currentSection === 'discover' ? 'active' : ''}`} onClick={() => onNavigate?.('discover')} type="button">Discover</button>
          <button className={`nav-link nav-button ${currentSection === 'posts' ? 'active' : ''}`} onClick={() => onNavigate?.('posts')} type="button">Posts</button>
          <button className={`nav-link nav-button ${currentSection === 'collaborations' ? 'active' : ''}`} onClick={() => onNavigate?.('collaborations')} type="button">Collaborations</button>
          <button className={`nav-link nav-button ${currentSection === 'profile' ? 'active' : ''}`} onClick={() => setCreateOpen(false)} type="button">My profile</button>
        </nav>
        <button className="sign-out" type="button" onClick={() => signOut(auth)}>Sign out</button>
      </aside>

      <section className="posts-content" id="posts">
        <header className="workspace-header">
          <div><p className="eyebrow">COMMUNITY</p><h1>Browse posts from the community.</h1><p>Offer skills, request help, start projects, or volunteer.</p></div>
          <button className="primary-button" onClick={() => setCreateOpen(true)} type="button">+ New Post</button>
        </header>

        <div className="posts-toolbar">
          <label className="search-field"><span aria-hidden="true">⌕</span><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search posts by title or skill" /></label>
          <div className="filter-list" aria-label="Filter by post type">
            <button className={typeFilter === 'all' ? 'filter-button active' : 'filter-button'} onClick={() => setTypeFilter('all')} type="button">All types</button>
            {postTypes.map((pt) => (
              <button key={pt.value} className={typeFilter === pt.value ? 'filter-button active' : 'filter-button'} onClick={() => setTypeFilter(pt.value)} type="button">{pt.label}</button>
            ))}
          </div>
        </div>

        {loading && <p className="state-message">Loading community posts...</p>}
        {error && <p className="state-message error-state">{error}</p>}
        {!loading && !error && filteredPosts.length === 0 && <p className="state-message">No posts found. Create one to start!</p>}

        <div className="posts-list">
          {filteredPosts.map((post) => {
            const isJoined = post.participantIds?.includes(currentUid);
            const isOwner = post.userId === currentUid;
            return (
              <article className="post-card" key={post.id}>
                <div className="post-header">
                  <div className="post-user">
                    {post.userPhoto ? (
                      <img className="post-user-photo" src={post.userPhoto} alt="" />
                    ) : (
                      <div className="post-user-initial">{post.userName.slice(0, 1).toUpperCase()}</div>
                    )}
                    <div>
                      <p className="post-user-name">{post.userName}</p>
                      <p className="post-type-badge">{postTypes.find((pt) => pt.value === post.type)?.label || post.type}</p>
                    </div>
                  </div>
                  <span className="post-category-tag">{post.category}</span>
                </div>
                <h2 className="post-title">{post.title}</h2>
                <p className="post-description">{post.description}</p>
                {post.location && <p className="post-location">📍 {post.location}</p>}
                <div className="post-footer">
                  <span className="post-participants">{post.participantIds?.length ?? 0} interested</span>
                  {!isOwner && (
                    <button
                      className={isJoined ? 'post-action-btn joined' : 'post-action-btn'}
                      onClick={() => !isJoined && joinPost(post.id)}
                      disabled={isJoined}
                      type="button"
                    >
                      {isJoined ? '✓ Interested' : 'I\'m interested'}
                    </button>
                  )}
                </div>
              </article>
            );
          })}
        </div>

        {createOpen && (
          <div className="profile-dialog-backdrop" role="presentation" onClick={() => setCreateOpen(false)}>
            <section className="profile-dialog profile-editor" role="dialog" aria-modal="true" aria-labelledby="create-post-title" onClick={(event) => event.stopPropagation()}>
              <button className="dialog-close" aria-label="Close post creation" onClick={() => setCreateOpen(false)} type="button">×</button>
              <p className="eyebrow">CREATE A POST</p>
              <h2 id="create-post-title">Share with the community</h2>
              <form onSubmit={submitPost}>
                <label>Post type<select value={formData.type} onChange={(event) => setFormData({ ...formData, type: event.target.value })}>
                  {postTypes.map((pt) => <option key={pt.value} value={pt.value}>{pt.label}</option>)}
                </select></label>
                <label>Title<input required value={formData.title} onChange={(event) => setFormData({ ...formData, title: event.target.value })} placeholder="What are you sharing?" /></label>
                <label>Description<textarea required rows={5} value={formData.description} onChange={(event) => setFormData({ ...formData, description: event.target.value })} placeholder="Share details, expectations, or how to get in touch..." /></label>
                <label>Category<select value={formData.category} onChange={(event) => setFormData({ ...formData, category: event.target.value })}>
                  {categories.map((cat) => <option key={cat} value={cat}>{cat}</option>)}
                </select></label>
                {(formData.type === 'offer_service' || formData.type === 'community_project' || formData.type === 'volunteer') && (
                  <label>Location (optional)<input value={formData.location} onChange={(event) => setFormData({ ...formData, location: event.target.value })} placeholder="City or neighborhood" /></label>
                )}
                <button className="primary-button" disabled={createBusy} type="submit">{createBusy ? 'Creating...' : 'Create post'}</button>
              </form>
              {createMessage && <p className="auth-message" role="status">{createMessage}</p>}
            </section>
          </div>
        )}
      </section>
    </main>
  );
}
