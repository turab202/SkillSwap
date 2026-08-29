'use client';

import { useEffect, useRef, useState } from 'react';
import { collection, doc, getDocs, query, where, orderBy, addDoc, serverTimestamp, updateDoc, getDoc, limit, onSnapshot } from 'firebase/firestore';
import { signOut } from 'firebase/auth';
import { auth, db } from '@/lib/firebase';
import type { ChatModel, MessageModel, CollaborationModel } from '@/lib/models';

function asChatModel(id: string, data: Record<string, unknown>): ChatModel {
  return {
    id,
    participantIds: Array.isArray(data.participantIds) ? data.participantIds.map(String) : [],
    participantNames: typeof data.participantNames === 'object' && data.participantNames ? (data.participantNames as Record<string, string>) : {},
    participantPhotos: typeof data.participantPhotos === 'object' && data.participantPhotos ? (data.participantPhotos as Record<string, string | null>) : {},
    lastMessage: String(data.lastMessage ?? ''),
    lastAt: data.lastAt as ChatModel['lastAt'],
    unreadCounts: typeof data.unreadCounts === 'object' && data.unreadCounts ? (data.unreadCounts as Record<string, number>) : {},
  };
}

function asMessageModel(id: string, data: Record<string, unknown>): MessageModel {
  return {
    id,
    senderId: String(data.senderId ?? ''),
    senderName: String(data.senderName ?? ''),
    text: String(data.text ?? ''),
    createdAt: data.createdAt as MessageModel['createdAt'],
  };
}

export function Messaging({ currentUid, onNavigate, currentSection }: { currentUid: string; onNavigate?: (section: 'dashboard' | 'discover' | 'posts' | 'collaborations' | 'messaging') => void; currentSection?: string }) {
  const [chats, setChats] = useState<ChatModel[]>([]);
  const [selectedChat, setSelectedChat] = useState<ChatModel | null>(null);
  const [messages, setMessages] = useState<MessageModel[]>([]);
  const [loading, setLoading] = useState(true);
  const [messageText, setMessageText] = useState('');
  const [sending, setSending] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Load chats where current user is a participant
  useEffect(() => {
    let active = true;
    async function loadChats() {
      setLoading(true);
      try {
        const chatsQuery = query(
          collection(db, 'chats'),
          where('participantIds', 'array-contains', currentUid),
          orderBy('lastAt', 'desc'),
          limit(50),
        );
        const snapshot = await getDocs(chatsQuery);
        if (active) {
          const loadedChats = snapshot.docs.map((item) => asChatModel(item.id, item.data()));
          setChats(loadedChats);
          if (loadedChats.length > 0) setSelectedChat(loadedChats[0]);
        }
      } catch (loadError) {
        console.error('Failed to load chats:', loadError);
      } finally {
        if (active) setLoading(false);
      }
    }
    void loadChats();
    return () => { active = false; };
  }, [currentUid]);

  // Load messages for selected chat
  useEffect(() => {
    if (!selectedChat) return;
    
    const messagesRef = collection(db, 'chats', selectedChat.id, 'messages');
    const messagesQuery = query(messagesRef, orderBy('createdAt', 'asc'));
    
    const unsubscribe = onSnapshot(messagesQuery, (snapshot) => {
      const loadedMessages = snapshot.docs.map((item) => asMessageModel(item.id, item.data()));
      setMessages(loadedMessages);
      setTimeout(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
      }, 0);
    });

    return unsubscribe;
  }, [selectedChat]);

  async function sendMessage() {
    if (!messageText.trim() || !selectedChat) return;

    setSending(true);
    try {
      const messageRef = collection(db, 'chats', selectedChat.id, 'messages');
      await addDoc(messageRef, {
        senderId: currentUid,
        senderName: auth.currentUser?.displayName ?? 'User',
        text: messageText.trim(),
        createdAt: serverTimestamp(),
      });

      // Update chat's last message and timestamp
      const otherUserId = selectedChat.participantIds.find((id) => id !== currentUid) || '';
      await updateDoc(doc(db, 'chats', selectedChat.id), {
        lastMessage: messageText.trim(),
        lastAt: serverTimestamp(),
        [`unreadCounts.${otherUserId}`]: (selectedChat.unreadCounts[otherUserId] ?? 0) + 1,
      });

      setMessageText('');
    } catch (sendError) {
      console.error('Failed to send message:', sendError);
    } finally {
      setSending(false);
    }
  }

  const otherUserId = selectedChat?.participantIds.find((id) => id !== currentUid) || '';
  const otherUserName = selectedChat?.participantNames[otherUserId] || 'Unknown';
  const otherUserPhoto = selectedChat?.participantPhotos[otherUserId];

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
        </nav>
        <button className="sign-out" type="button" onClick={() => signOut(auth)}>Sign out</button>
      </aside>

      <section className="messaging-content" id="messaging">
        <div className="messaging-container">
          <aside className="chats-sidebar">
            <p className="chats-heading">Conversations</p>
            {loading ? (
              <p className="state-message">Loading chats...</p>
            ) : chats.length === 0 ? (
              <p className="state-message">No conversations yet. Start a skill swap!</p>
            ) : (
              <ul className="chats-list">
                {chats.map((chat) => {
                  const otherUid = chat.participantIds.find((id) => id !== currentUid) || '';
                  const otherName = chat.participantNames[otherUid] || 'Unknown';
                  const unreadBadge = chat.unreadCounts[currentUid] || 0;
                  return (
                    <li key={chat.id}>
                      <button
                        className={`chat-button ${selectedChat?.id === chat.id ? 'active' : ''}`}
                        onClick={() => setSelectedChat(chat)}
                        type="button"
                      >
                        <div className="chat-avatar">{otherName.slice(0, 1).toUpperCase()}</div>
                        <div className="chat-info">
                          <p className="chat-name">{otherName}</p>
                          <p className="chat-preview">{chat.lastMessage.slice(0, 40)}{chat.lastMessage.length > 40 ? '...' : ''}</p>
                        </div>
                        {unreadBadge > 0 && <span className="chat-unread-badge">{unreadBadge}</span>}
                      </button>
                    </li>
                  );
                })}
              </ul>
            )}
          </aside>

          <section className="messages-panel">
            {selectedChat ? (
              <>
                <header className="messages-header">
                  <div className="message-recipient">
                    <div className="recipient-avatar">{otherUserName.slice(0, 1).toUpperCase()}</div>
                    <div>
                      <h2>{otherUserName}</h2>
                      <p>Messaging</p>
                    </div>
                  </div>
                </header>

                <div className="messages-thread">
                  {messages.length === 0 ? (
                    <p className="state-message">No messages yet. Say hello!</p>
                  ) : (
                    messages.map((msg) => (
                      <div key={msg.id} className={`message ${msg.senderId === currentUid ? 'sent' : 'received'}`}>
                        <div className="message-bubble">
                          <p className="message-text">{msg.text}</p>
                          <span className="message-time">{new Date(msg.createdAt instanceof Date ? msg.createdAt : msg.createdAt.toDate?.() || new Date()).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                        </div>
                      </div>
                    ))
                  )}
                  <div ref={messagesEndRef} />
                </div>

                <footer className="messages-input-area">
                  <form onSubmit={(e) => { e.preventDefault(); sendMessage(); }} className="message-form">
                    <input
                      type="text"
                      value={messageText}
                      onChange={(e) => setMessageText(e.target.value)}
                      placeholder="Type a message..."
                      disabled={sending}
                      className="message-input"
                    />
                    <button className="send-button" disabled={!messageText.trim() || sending} type="submit">
                      {sending ? 'Sending...' : 'Send'}
                    </button>
                  </form>
                </footer>
              </>
            ) : (
              <div className="messages-empty">
                <p className="state-message">Select a conversation to start messaging</p>
              </div>
            )}
          </section>
        </div>
      </section>
    </main>
  );
}
