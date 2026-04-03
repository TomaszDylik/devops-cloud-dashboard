const express = require('express');
const os = require('os');
const { Pool } = require('pg');
const Redis = require('ioredis');

const app = express();
const port = process.env.PORT || 3000;
const instanceId = process.env.INSTANCE_ID || os.hostname();

app.use(express.json());

let totalRequests = 0;
app.use((req, res, next) => {
	totalRequests += 1;
	next();
});

// --- PostgreSQL ---
const pool = new Pool({
	host: process.env.POSTGRES_HOST || 'localhost',
	port: parseInt(process.env.POSTGRES_PORT || '5432', 10),
	database: process.env.POSTGRES_DB || 'dashboard',
	user: process.env.POSTGRES_USER || 'postgres',
	password: process.env.POSTGRES_PASSWORD || 'postgres',
	connectionTimeoutMillis: 3000,
	idleTimeoutMillis: 10000,
});

// --- Redis ---
const redis = new Redis({
	host: process.env.REDIS_HOST || 'localhost',
	port: parseInt(process.env.REDIS_PORT || '6379', 10),
	lazyConnect: true,
	connectTimeout: 3000,
	maxRetriesPerRequest: 0,
	enableOfflineQueue: false,
});

let pgReady = false;
let redisReady = false;

async function initDB() {
	try {
		await pool.query(`
			CREATE TABLE IF NOT EXISTS items (
				id        SERIAL PRIMARY KEY,
				name      VARCHAR(255) NOT NULL,
				price     NUMERIC,
				created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
			)
		`);
		pgReady = true;
		console.log('PostgreSQL: connected and table ready');
	} catch (err) {
		console.error('PostgreSQL init error:', err.message);
	}
}

async function initRedis() {
	try {
		await redis.connect();
		redisReady = true;
		console.log('Redis: connected');
	} catch (err) {
		console.error('Redis init error:', err.message);
	}
}

// Kick off connections (server starts regardless of outcome)
initDB();
initRedis();

// --- Routes ---

app.get('/items', async (req, res) => {
	try {
		const result = await pool.query(
			'SELECT id, name, price, created_at AS "createdAt" FROM items ORDER BY id'
		);
		res.json(result.rows);
	} catch (err) {
		res.status(503).json({ error: 'Database unavailable', details: err.message });
	}
});

app.post('/items', async (req, res) => {
	const { name, price } = req.body || {};

	if (!name || typeof name !== 'string') {
		return res.status(400).json({
			error: 'Field "name" is required and must be a string.'
		});
	}

	try {
		const result = await pool.query(
			`INSERT INTO items (name, price)
			 VALUES ($1, $2)
			 RETURNING id, name, price, created_at AS "createdAt"`,
			[name.trim(), typeof price === 'number' ? price : null]
		);
		return res.status(201).json(result.rows[0]);
	} catch (err) {
		return res.status(503).json({ error: 'Database unavailable', details: err.message });
	}
});

app.get('/health', async (req, res) => {
	let pgStatus = false;
	try {
		await pool.query('SELECT 1');
		pgStatus = true;
	} catch (_) { /* unreachable in healthy state */ }

	let redisStatus = false;
	try {
		redisStatus = (await redis.ping()) === 'PONG';
	} catch (_) { /* unreachable in healthy state */ }

	res.json({
		status: pgStatus && redisStatus ? 'ok' : 'degraded',
		uptime: Math.floor(process.uptime()),
		postgres: pgStatus,
		redis: redisStatus,
	});
});

const STATS_CACHE_KEY = 'dashboard:stats';
const STATS_TTL_SECONDS = 10;

app.get('/stats', async (req, res) => {
	// Try cache first
	try {
		const cached = await redis.get(STATS_CACHE_KEY);
		if (cached) {
			return res.set('X-Cache', 'HIT').json(JSON.parse(cached));
		}
	} catch (_) { /* Redis unavailable – fall through to MISS path */ }

	// Fetch fresh data
	let totalItems = 0;
	try {
		const { rows } = await pool.query('SELECT COUNT(*)::int AS count FROM items');
		totalItems = rows[0].count;
	} catch (_) { /* DB unavailable – keep 0 */ }

	const data = {
		instanceId,
		totalItems,
		totalRequests,
		uptimeSeconds: Math.floor(process.uptime()),
		serverTime: new Date().toISOString(),
	};

	// Store in cache
	try {
		await redis.setex(STATS_CACHE_KEY, STATS_TTL_SECONDS, JSON.stringify(data));
	} catch (_) { /* Redis unavailable – skip caching */ }

	return res.set('X-Cache', 'MISS').json(data);
});

if (require.main === module) {
	app.listen(port, () => {
		console.log(`Backend API listening on port ${port}. Instance: ${instanceId}`);
	});
}

module.exports = app;
