import { AuthForm } from '@/components/auth-form';

export default function HomePage() {
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
