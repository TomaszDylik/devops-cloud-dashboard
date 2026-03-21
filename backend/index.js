const express = require('express');
const os = require('os');

const app = express();
const port = process.env.PORT || 3000;
const instanceId = os.hostname();

app.use(express.json());

const items = [];
let nextId = 1;
let totalRequests = 0;

app.use((req, res, next) => {
	totalRequests += 1;
	next();
});

app.get('/items', (req, res) => {
	res.json(items);
});

app.post('/items', (req, res) => {
	const { name, price } = req.body || {};

	if (!name || typeof name !== 'string') {
		return res.status(400).json({
			error: 'Field "name" is required and must be a string.'
		});
	}

	const item = {
		id: nextId,
		name: name.trim(),
		price: typeof price === 'number' ? price : null,
		createdAt: new Date().toISOString()
	};

	items.push(item);
	nextId += 1;

	return res.status(201).json(item);
});

app.get('/stats', (req, res) => {
	res.json({
		instanceId,
		totalItems: items.length,
		totalRequests,
		uptimeSeconds: Math.floor(process.uptime())
	});
});

app.listen(port, () => {
	console.log(`Backend API listening on port ${port}. Instance: ${instanceId}`);
});
