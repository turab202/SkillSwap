'use client';

import { useEffect, useState } from 'react';
import { collection, getDocs, query, where, orderBy, limit, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { signOut } from 'firebase/auth';
import { auth, db } from '@/lib/firebase';
import type { NotificationModel } from '@/lib/models';

function asNotificationModel(id: string, data: Record<string, unknown>): NotificationModel {
  return {
    id,
    userId: String(data.userId ?? ''),
    title: String(data.title ?? ''),
    body: String(data.body ?? ''),
    type: (data.type as NotificationModel['type']) ?? 'system',
    read: Boolean(data.read ?? false),
    actionId: typeof data.actionId === 'string' ? data.actionId : null,
    createdAt: data.createdAt as NotificationModel['createdAt'],
  };
}

const typeColors: Record<string, string> = {
  request: '#fbbf24',
  collaboration: '#10b981',
  community: '#06b6d4',
  match: '#8b5cf6',
  appreciation: '#ec4899',
  system: '#6b7280',
};

const typeEmojis: Record<string, string> = {
  request: '🤝',
  collaboration: '✨',
  community: '👥',
  match: '💡',
  appreciation: '⭐',
  system: 'ℹ️',
};

export function Notifications({ currentUid, onNavigate, currentSection }: { currentUid: string; onNavigate?: (section: 'dashboard' | 'discover' | 'posts' | 'collaborations' | 'messaging' | 'notifications') => void; currentSection?: string }) {
  const [notifications, setNotifications] = useState<NotificationModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'unread'>('all');

  useEffect(() => {
    let active = true;
    async function loadNotifications() {
      setLoading(true);
      try {
        const notificationsQuery = query(
          collection(db, 'notifications'),
          where('userId', '==', currentUid),
          orderBy('createdAt', 'desc'),
          limit(100),
        );
        const snapshot = await getDocs(notificationsQuery);
        if (active) {
          setNotifications(snapshot.docs.map((item) => asNotificationModel(item.id, item.data())));
        }
      } catch (loadError) {
        console.error('Failed to load notifications:', loadError);
      } finally {
        if (active) setLoading(false);
      }
    }
    void loadNotifications();
    return () => { active = false; };
  }, [currentUid]);

  const filteredNotifications = filter === 'unread' ? notifications.filter((n) => !n.read) : notifications;
  const unreadCount = notifications.filter((n) => !n.read).length;

  async function markAsRead(notificationId: string) {
    try {
      await updateDoc(doc(db, 'notifications', notificationId), { read: true });
      setNotifications(notifications.map((n) => (n.id === notificationId ? { ...n, read: true } : n)));
    } catch (error) {
      console.error('Failed to mark as read:', error);
    }
  }

  async function deleteNotification(notificationId: string) {
    try {
      await deleteDoc(doc(db, 'notifications', notificationId));
      setNotifications(notifications.filter((n) => n.id !== notificationId));
    } catch (error) {
      console.error('Failed to delete notification:', error);
    }
  }

  function handleNotificationClick(notification: NotificationModel) {
    if (!notification.read) {
      markAsRead(notification.id);
    }
    if (notification.type === 'collaboration' || notification.type === 'request') {
      onNavigate?.('collaborations');
    } else if (notification.type === 'community') {
      onNavigate?.('posts');
    } else if (notification.type === 'match') {
      onNavigate?.('discover');
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
          <button className={`nav-link nav-button ${currentSection === 'messaging' ? 'active' : ''}`} onClick={() => onNavigate?.('messaging')} type="button">Messages</button>
          <button className={`nav-link nav-button ${currentSection === 'notifications' ? 'active' : ''}`} onClick={() => onNavigate?.('notifications')} type="button">Notifications</button>
        </nav>
        <button className="sign-out" type="button" onClick={() => signOut(auth)}>Sign out</button>
      </aside>

      <section className="notifications-content" id="notifications">
        <header className="workspace-header">
          <div>
            <p className="eyebrow">ACTIVITY</p>
            <h1>Stay updated</h1>
            <p>See all activity and messages from the community.</p>
          </div>
        </header>

        <div className="notifications-toolbar">
          <div className="filter-list" aria-label="Filter notifications">
            <button className={filter === 'all' ? 'filter-button active' : 'filter-button'} onClick={() => setFilter('all')} type="button">
              All {notifications.length > 0 && <span className="badge-count">({notifications.length})</span>}
            </button>
            <button className={filter === 'unread' ? 'filter-button active' : 'filter-button'} onClick={() => setFilter('unread')} type="button">
              Unread {unreadCount > 0 && <span className="badge-count">({unreadCount})</span>}
            </button>
          </div>
        </div>

        {loading ? (
          <p className="state-message">Loading notifications...</p>
        ) : filteredNotifications.length === 0 ? (
          <p className="state-message">No {filter === 'unread' ? 'unread ' : ''}notifications yet. Stay tuned!</p>
        ) : (
          <ul className="notifications-list">
            {filteredNotifications.map((notification) => (
              <li key={notification.id} className={`notification-item ${notification.read ? 'read' : 'unread'}`}>
                <button
                  className="notification-button"
                  onClick={() => handleNotificationClick(notification)}
                  type="button"
                >
                  <div className="notification-icon" style={{ backgroundColor: typeColors[notification.type] }}>
                    {typeEmojis[notification.type]}
                  </div>
                  <div className="notification-content">
                    <p className="notification-title">{notification.title}</p>
                    <p className="notification-body">{notification.body}</p>
                    <span className="notification-time">
                      {new Date(notification.createdAt instanceof Date ? notification.createdAt : notification.createdAt.toDate?.() || new Date()).toLocaleString()}
                    </span>
                  </div>
                  {!notification.read && <div className="notification-unread-dot" />}
                </button>
                <button
                  className="notification-delete"
                  onClick={() => deleteNotification(notification.id)}
                  aria-label="Delete notification"
                  type="button"
                >
                  ✕
                </button>
              </li>
            ))}
          </ul>
        )}
      </section>
    </main>
  );
}
