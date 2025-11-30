#!/usr/bin/env node
// Web server for Work Context Dashboard

const fs = require('fs');
const path = require('path');
const http = require('http');
const os = require('os');

const SESSION_FILE = path.join(os.homedir(), '.claude-work-data', 'sessions.jsonl');
const STATE_FILE = path.join(os.homedir(), '.claude-work-data', 'context-state.json');

// Read and parse JSON Lines file
function readSessions() {
    try {
        if (!fs.existsSync(SESSION_FILE)) return [];
        const data = fs.readFileSync(SESSION_FILE, 'utf8');
        return data.split('\n').filter(l => l).map(l => JSON.parse(l));
    } catch (e) {
        return [];
    }
}

// Get current state
function getState() {
    try {
        if (!fs.existsSync(STATE_FILE)) return null;
        return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
    } catch (e) {
        return null;
    }
}

// API endpoints
const server = http.createServer((req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Content-Type', 'application/json');

    if (req.url === '/api/status') {
        const state = getState();
        res.writeHead(200);
        res.end(JSON.stringify(state || {}));
    } 
    else if (req.url === '/api/timeline') {
        const sessions = readSessions();
        const today = new Date().toISOString().split('T')[0];
        const filtered = sessions.filter(e => e.timestamp.startsWith(today));
        res.writeHead(200);
        res.end(JSON.stringify(filtered));
    }
    else if (req.url === '/api/analytics') {
        const sessions = readSessions();
        const projects = {};
        const worktypes = {};
        let totalAfk = 0;
        let afkCount = 0;

        sessions.forEach(e => {
            if (e.type === 'context_change') {
                projects[e.data.project] = (projects[e.data.project] || 0) + 1;
                worktypes[e.data.work_type] = (worktypes[e.data.work_type] || 0) + 1;
            }
            if (e.type === 'afk_detected') {
                totalAfk += e.data.idle_minutes || 0;
                afkCount++;
            }
        });

        res.writeHead(200);
        res.end(JSON.stringify({
            totalEvents: sessions.length,
            projects,
            worktypes,
            totalAfkMinutes: totalAfk,
            afkCount
        }));
    }
    else if (req.url === '/') {
        const html = fs.readFileSync(path.join(__dirname, 'index.html'), 'utf8');
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(html);
    }
    else {
        res.writeHead(404);
        res.end('{"error": "Not found"}');
    }
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`✓ Dashboard running at http://localhost:${PORT}`);
    console.log('');
    console.log('API Endpoints:');
    console.log(`  GET /api/status    - Current work context`);
    console.log(`  GET /api/timeline  - Today\'s timeline`);
    console.log(`  GET /api/analytics - Work statistics`);
});
