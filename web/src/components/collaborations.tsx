'use client';

import { useEffect, useState } from 'react';
import { collection, query, where, getDocs, doc, updateDoc, Timestamp, or } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import type { CollaborationModel } from '@/lib/models';

interface CollaborationsProps {
  currentUid: string;
  onNavigate?: (section: 'dashboard' | 'discover' | 'profile' | 'collaborations') => void;
  currentSection?: string;
}

function asCollaborationModel(id: string, data: Record<string, unknown>): CollaborationModel {
  return {
    id,
    requesterId: String(data.requesterId ?? ''),
    requesterName: String(data.requesterName ?? 'Unknown'),
    requesterPhoto: typeof data.requesterPhoto === 'string' ? data.requesterPhoto : null,
    targetId: String(data.targetId ?? ''),
    targetName: String(data.targetName ?? 'Unknown'),
    targetPhoto: typeof data.targetPhoto === 'string' ? data.targetPhoto : null,
    skillOffered: String(data.skillOffered ?? ''),
    skillWanted: String(data.skillWanted ?? ''),
    status: (data.status as CollaborationModel['status']) ?? 'pending',
    message: typeof data.message === 'string' ? data.message : null,
    createdAt: data.createdAt as CollaborationModel['createdAt'],
    scheduledAt: (data.scheduledAt ?? null) as CollaborationModel['scheduledAt'],
    completedAt: (data.completedAt ?? null) as CollaborationModel['completedAt'],
  };
}

const statusTabs = ['pending', 'accepted', 'inProgress', 'completed', 'cancelled'] as const;
const statusLabels: Record<string, string> = {
  pending: 'Pending',
  accepted: 'Accepted',
  inProgress: 'In Progress',
  completed: 'Completed',
  cancelled: 'Cancelled',
};

export function Collaborations({ currentUid, onNavigate, currentSection }: CollaborationsProps) {
  const [collaborations, setCollaborations] = useState<CollaborationModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [activeTab, setActiveTab] = useState('pending');
  const [actioning, setActioning] = useState<string | null>(null);

  useEffect(() => {
    async function loadCollaborations() {
      setLoading(true);
      setError('');
      try {
        const collabQuery = query(
          collection(db, 'collaborations'),
          or(
            where('requesterId', '==', currentUid),
            where('targetId', '==', currentUid),
          ),
        );
        const snapshot = await getDocs(collabQuery);
        const items = snapshot.docs
          .map((item) => asCollaborationModel(item.id, item.data()))
          .sort((a, b) => {
            const timeA = (a.createdAt as Timestamp)?.toMillis?.() ?? 0;
            const timeB = (b.createdAt as Timestamp)?.toMillis?.() ?? 0;
            return timeB - timeA;
          });
        setCollaborations(items);
      } catch (loadError) {
        setError(loadError instanceof Error ? loadError.message : 'Could not load collaborations.');
      } finally {
        setLoading(false);
      }
    }
    void loadCollaborations();
  }, [currentUid]);

  async function updateStatus(collabId: string, newStatus: CollaborationModel['status']) {
    setActioning(collabId);
    try {
      await updateDoc(doc(db, 'collaborations', collabId), {
        status: newStatus,
        ...(newStatus === 'completed' && { completedAt: Timestamp.now() }),
      });
      setCollaborations((prev) =>
        prev.map((c) =>
          c.id === collabId ? { ...c, status: newStatus } : c,
        ),
      );
    } catch (updateError) {
      setError(updateError instanceof Error ? updateError.message : 'Could not update status.');
    } finally {
      setActioning(null);
    }
  }

  const filtered = collaborations.filter((c) => c.status === activeTab);

  return (
    <main className="workspace-page">
      <aside className="workspace-sidebar">
        <div className="brand-mark"><span>SS</span><strong>SkillSwap</strong></div>
        <nav aria-label="Primary navigation">
          <button className={`nav-link nav-button ${currentSection === 'dashboard' ? 'active' : ''}`} onClick={() => onNavigate?.('dashboard')} type="button">Home</button>
          <button className={`nav-link nav-button ${currentSection === 'discover' ? 'active' : ''}`} onClick={() => onNavigate?.('discover')} type="button">Discover</button>
          <button className={`nav-link nav-button ${currentSection === 'collaborations' ? 'active' : ''}`} onClick={() => onNavigate?.('collaborations')} type="button">Collaborations</button>
          <button className={`nav-link nav-button ${currentSection === 'profile' ? 'active' : ''}`} onClick={() => onNavigate?.('profile')} type="button">My profile</button>
        </nav>
      </aside>

      <section className="discover-content" id="collaborations">
        <header className="workspace-header">
          <div>
            <p className="eyebrow">MY COLLABORATIONS</p>
            <h1>Skill swaps in progress.</h1>
            <p>View requests, schedule, and track your skill exchanges.</p>
          </div>
        </header>

        {loading ? (
          <p className="state-message">Loading collaborations...</p>
        ) : error ? (
          <p className="state-message error-state">{error}</p>
        ) : collaborations.length === 0 ? (
          <p className="state-message">No collaborations yet. <a href="#" onClick={(e) => { e.preventDefault(); onNavigate?.('discover'); }}>Find people to collaborate with</a>.</p>
        ) : (
          <>
            <div className="status-tabs">
              {statusTabs.map((status) => {
                const count = collaborations.filter((c) => c.status === status).length;
                return (
                  <button
                    key={status}
                    className={`status-tab ${activeTab === status ? 'active' : ''}`}
                    onClick={() => setActiveTab(status)}
                    type="button"
                  >
                    {statusLabels[status]} {count > 0 && <span className="tab-badge">{count}</span>}
                  </button>
                );
              })}
            </div>

            {filtered.length === 0 ? (
              <p className="state-message">No {statusLabels[activeTab].toLowerCase()} collaborations.</p>
            ) : (
              <div className="collaborations-list">
                {filtered.map((collab) => {
                  const isRequester = collab.requesterId === currentUid;
                  const otherName = isRequester ? collab.targetName : collab.requesterName;
                  const otherPhoto = isRequester ? collab.targetPhoto : collab.requesterPhoto;
                  const canRespond = !isRequester && collab.status === 'pending';

                  return (
                    <article className="collaboration-card" key={collab.id}>
                      <div className="collab-header">
                        <div className="collab-person">
                          {otherPhoto ? (
                            <img className="person-avatar-sm" src={otherPhoto} alt={otherName} />
                          ) : (
                            <div className="person-avatar-sm person-initial-sm">{otherName.slice(0, 1).toUpperCase()}</div>
                          )}
                          <div>
                            <h3>{otherName}</h3>
                            <p className="skill-exchange">{collab.skillOffered} ↔ {collab.skillWanted}</p>
                          </div>
                        </div>
                        <span className={`status-badge status-${collab.status}`}>{statusLabels[collab.status]}</span>
                      </div>

                      {collab.message && (
                        <p className="collab-message">{collab.message}</p>
                      )}

                      <div className="collab-actions">
                        {canRespond && (
                          <>
                            <button
                              className="action-btn action-accept"
                              disabled={actioning !== null}
                              onClick={() => updateStatus(collab.id, 'accepted')}
                              type="button"
                            >
                              {actioning === collab.id ? 'Accepting...' : 'Accept'}
                            </button>
                            <button
                              className="action-btn action-decline"
                              disabled={actioning !== null}
                              onClick={() => updateStatus(collab.id, 'cancelled')}
                              type="button"
                            >
                              {actioning === collab.id ? 'Declining...' : 'Decline'}
                            </button>
                          </>
                        )}
                        {collab.status === 'accepted' && (
                          <button
                            className="action-btn action-start"
                            disabled={actioning !== null}
                            onClick={() => updateStatus(collab.id, 'inProgress')}
                            type="button"
                          >
                            {actioning === collab.id ? 'Starting...' : 'Start exchange'}
                          </button>
                        )}
                        {collab.status === 'inProgress' && (
                          <button
                            className="action-btn action-complete"
                            disabled={actioning !== null}
                            onClick={() => updateStatus(collab.id, 'completed')}
                            type="button"
                          >
                            {actioning === collab.id ? 'Marking...' : 'Mark complete'}
                          </button>
                        )}
                      </div>
                    </article>
                  );
                })}
              </div>
            )}
          </>
        )}
      </section>
    </main>
  );
}
