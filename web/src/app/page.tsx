export default function HomePage() {
  return (
    <main style={{ maxWidth: 960, margin: '0 auto', padding: '80px 24px' }}>
      <p style={{ color: '#1b5e20', fontWeight: 700, letterSpacing: '0.08em' }}>SKILLSWAP WEB</p>
      <h1 style={{ fontFamily: 'Space Grotesk, sans-serif', fontSize: 'clamp(2.5rem, 7vw, 5rem)', lineHeight: 1.05, maxWidth: 720 }}>
        The web foundation is ready.
      </h1>
      <p style={{ maxWidth: 560, color: '#6b7280', fontSize: '1.15rem', lineHeight: 1.6 }}>
        This Next.js App Router client is connected to the same Firebase project as the Flutter mobile app. Feature screens will be added one at a time.
      </p>
    </main>
  );
}
