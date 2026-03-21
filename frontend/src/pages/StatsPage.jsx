import { useEffect, useState } from 'react';

function StatsPage() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const fetchStats = async () => {
    setLoading(true);
    setError('');

    try {
      const response = await fetch('/api/stats');
      if (!response.ok) {
        throw new Error('Failed to load stats.');
      }
      const data = await response.json();
      setStats(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();
  }, []);

  return (
    <section>
      <h2>Stats</h2>
      <div className="card">
        <button onClick={fetchStats} disabled={loading}>
          {loading ? 'Loading...' : 'Refresh Stats'}
        </button>

        {error && <p className="error">{error}</p>}

        {stats && (
          <dl className="stats-grid">
            <dt>Last Instance ID</dt>
            <dd>{stats.instanceId}</dd>

            <dt>Total Items</dt>
            <dd>{stats.totalItems}</dd>

            <dt>Total Requests</dt>
            <dd>{stats.totalRequests}</dd>

            <dt>Uptime (seconds)</dt>
            <dd>{stats.uptimeSeconds}</dd>
          </dl>
        )}
      </div>
    </section>
  );
}

export default StatsPage;
