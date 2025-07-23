import React from 'react';
import Layout from '@theme/Layout';

export default function Home(): React.ReactElement {
  return (
    <Layout
      title="Welcome to KawaiiSec OS"
      description="The world's cutest pentesting distro 💻🌸">
      <main style={{ textAlign: 'center', padding: '4rem' }}>
        <h1>🌸 KawaiiSec OS 🌸</h1>
        <p style={{ fontSize: '1.2rem' }}>
          Cute on the outside. Terminally dangerous on the inside. 💀💕<br />
          A Linux distro for ethical hackers who vibe in pink.
        </p>
        <img src="/img/Kawaii.png" alt="KawaiiSec OS Mascot" width="300px" />
        <div style={{ marginTop: '2rem' }}>
          <a href="/docs" className="button button--primary button--lg">
            Get Started with KawaiiSec →
          </a>
        </div>
      </main>
    </Layout>
  );
}
