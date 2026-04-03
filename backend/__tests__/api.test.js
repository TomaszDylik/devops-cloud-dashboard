// Mocki 
jest.mock('pg', () => {
	const mockPool = {
		query: jest.fn().mockRejectedValue(new Error('DB not available in tests')),
		on: jest.fn(),
		end: jest.fn(),
	};
	return { Pool: jest.fn(() => mockPool) };
});

jest.mock('ioredis', () => {
	const mockRedis = {
		connect: jest.fn().mockRejectedValue(new Error('Redis not available in tests')),
		get: jest.fn().mockRejectedValue(new Error('Redis not available in tests')),
		setex: jest.fn().mockRejectedValue(new Error('Redis not available in tests')),
		ping: jest.fn().mockRejectedValue(new Error('Redis not available in tests')),
		status: 'close',
		on: jest.fn(),
	};
	return jest.fn(() => mockRedis);
});

const request = require('supertest');
const app = require('../index');

describe('Backend API endpoints', () => {
	test('GET /health returns health info with postgres and redis fields', async () => {
		const response = await request(app).get('/health');

		expect(response.status).toBe(200);
		expect(['ok', 'degraded']).toContain(response.body.status);
		expect(typeof response.body.uptime).toBe('number');
		expect(response.body.uptime).toBeGreaterThanOrEqual(0);
		expect(typeof response.body.postgres).toBe('boolean');
		expect(typeof response.body.redis).toBe('boolean');
	});

	test('GET /stats returns server time, request counter and X-Cache header', async () => {
		const response = await request(app).get('/stats');

		expect(response.status).toBe(200);
		expect(typeof response.body.totalRequests).toBe('number');
		expect(response.body.totalRequests).toBeGreaterThanOrEqual(1);
		expect(typeof response.body.uptimeSeconds).toBe('number');
		expect(typeof response.body.serverTime).toBe('string');
		expect(Number.isNaN(Date.parse(response.body.serverTime))).toBe(false);
		expect(['HIT', 'MISS']).toContain(response.headers['x-cache']);
	});
});
