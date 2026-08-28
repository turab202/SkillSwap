import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'SkillSwap',
  description: 'A community skill exchange platform.',
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
