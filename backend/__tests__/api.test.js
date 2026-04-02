const request = require('supertest');
const app = require('../index');

describe('Backend API endpoints', () => {
	test('GET /health returns ok status and numeric uptime', async () => {
		const response = await request(app).get('/health');

		expect(response.status).toBe(200);
		expect(response.body.status).toBe('ok');
		expect(typeof response.body.uptime).toBe('number');
		expect(response.body.uptime).toBeGreaterThanOrEqual(0);
	});

	test('GET /stats returns server time and request counter', async () => {
		const response = await request(app).get('/stats');

		expect(response.status).toBe(200);
		expect(typeof response.body.totalRequests).toBe('number');
		expect(response.body.totalRequests).toBeGreaterThanOrEqual(1);
		expect(typeof response.body.uptimeSeconds).toBe('number');
		expect(typeof response.body.serverTime).toBe('string');
		expect(Number.isNaN(Date.parse(response.body.serverTime))).toBe(false);
	});
});
