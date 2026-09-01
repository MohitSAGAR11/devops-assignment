import { useState } from 'react';

export default function App() {
  const [clicks, setClicks] = useState(0);

  return (
    <main style={{ fontFamily: 'system-ui, sans-serif', textAlign: 'center', padding: 60 }}>
      <h1>Hello World</h1>
      <p>
        Served by a <strong>React</strong> app (built with Vite) inside Docker
      </p>
      <button onClick={() => setClicks(clicks + 1)}>
        clicked {clicks} times
      </button>
      <p style={{ color: '#666', marginTop: 24 }}>
        the button proves React itself is running, not just static HTML
      </p>
    </main>
  );
}
