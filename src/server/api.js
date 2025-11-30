#!/usr/bin/env node
// REST API for Work Context System
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const util = require('util');

const execPromise = util.promisify(exec);
const app = express();
const PORT = process.env.PORT || 3042;
const DATA_DIR = process.env.HOME + '/.claude-work-data';
const SESSION_FILE = path.join(DATA_DIR, 'sessions.jsonl');
const STATE_FILE = path.join(DATA_DIR, 'context-state.json');

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../../web')));

// GET /api/status - Current work context
app.get('/api/status', async (req, res) => {
    try {
        if (!fs.existsSync(STATE_FILE)) {
            return res.json({ error: 'No active context. Start daemon first.' });
        }
        
        const state = JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
        const daemonStatus = await checkDaemonStatus();
        
        res.json({
            ...state,
            daemon: daemonStatus,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// GET /api/timeline/:date - Context switches for a date
app.get('/api/timeline/:date', (req, res) => {
    try {
        const { date } = req.params;
        const limit = parseInt(req.query.limit) || 100;
        
        if (!fs.existsSync(SESSION_FILE)) {
            return res.json({ events: [], total: 0 });
        }
        
        const events = fs.readFileSync(SESSION_FILE, 'utf8')
            .trim()
            .split('\n')
            .filter(line => line.length > 0)
            .map(line => JSON.parse(line))
            .filter(event => {
                if (date === 'today') {
                    const today = new Date().toISOString().split('T')[0];
                    return event.timestamp.startsWith(today);
                } else if (date === 'week') {
                    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
                    return new Date(event.timestamp) >= weekAgo;
                } else {
                    return event.timestamp.startsWith(date);
                }
            })
            .slice(-limit)
            .reverse();
        
        res.json({
            events,
            total: events.length,
            date: date === 'today' ? new Date().toISOString().split('T')[0] : date
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// GET /api/analytics - Work analytics summary
app.get('/api/analytics', (req, res) => {
    try {
        if (!fs.existsSync(SESSION_FILE)) {
            return res.json({ 
                total_events: 0, 
                context_switches: 0, 
                projects: {} 
            });
        }
        
        const events = fs.readFileSync(SESSION_FILE, 'utf8')
            .trim()
            .split('\n')
            .filter(line => line.length > 0)
            .map(line => JSON.parse(line));
        
        const contextChanges = events.filter(e => e.type === 'context_change');
        const afkPeriods = events.filter(e => e.type === 'afk_detected');
        
        // Project statistics
        const projectStats = {};
        const workTypeStats = {};
        
        contextChanges.forEach(event => {
            const project = event.data?.project || 'unknown';
            const workType = event.data?.work_type || 'unknown';
            
            projectStats[project] = (projectStats[project] || 0) + 1;
            workTypeStats[workType] = (workTypeStats[workType] || 0) + 1;
        });
        
        // Sort projects by frequency
        const topProjects = Object.entries(projectStats)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 10)
            .map(([name, count]) => ({ name, count }));
        
        const topWorkTypes = Object.entries(workTypeStats)
            .sort((a, b) => b[1] - a[1])
            .map(([type, count]) => ({ type, count }));
        
        res.json({
            total_events: events.length,
            context_switches: contextChanges.length,
            afk_periods: afkPeriods.length,
            projects: topProjects,
            work_types: topWorkTypes,
            period: {
                start: events[0]?.timestamp,
                end: events[events.length - 1]?.timestamp
            }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// GET /api/projects - List all projects
app.get('/api/projects', (req, res) => {
    try {
        if (!fs.existsSync(SESSION_FILE)) {
            return res.json({ projects: [] });
        }
        
        const events = fs.readFileSync(SESSION_FILE, 'utf8')
            .trim()
            .split('\n')
            .filter(line => line.length > 0)
            .map(line => JSON.parse(line))
            .filter(e => e.type === 'context_change');
        
        const projectMap = new Map();
        
        events.forEach(event => {
            const project = event.data?.project || 'unknown';
            if (!projectMap.has(project)) {
                projectMap.set(project, {
                    name: project,
                    first_seen: event.timestamp,
                    last_seen: event.timestamp,
                    switches: 0
                });
            }
            const proj = projectMap.get(project);
            proj.last_seen = event.timestamp;
            proj.switches++;
        });
        
        const projects = Array.from(projectMap.values())
            .sort((a, b) => new Date(b.last_seen) - new Date(a.last_seen));
        
        res.json({ projects, total: projects.length });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// POST /api/note - Add manual annotation
app.post('/api/note', (req, res) => {
    try {
        const { note } = req.body;
        if (!note) {
            return res.status(400).json({ error: 'Note text required' });
        }
        
        const timestamp = new Date().toISOString();
        const entry = {
            type: 'work_note',
            timestamp,
            data: { note }
        };
        
        fs.appendFileSync(SESSION_FILE, JSON.stringify(entry) + '\n');
        res.json({ success: true, timestamp });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Helper: Check daemon status
async function checkDaemonStatus() {
    try {
        const { stdout } = await execPromise('pgrep -f "work-context-system.*daemon.sh"');
        return { running: true, pid: stdout.trim().split('\n')[0] };
    } catch {
        return { running: false };
    }
}

// Start server
app.listen(PORT, () => {
    console.log(`Work Context API listening on http://localhost:${PORT}`);
    console.log(`Dashboard: http://localhost:${PORT}/dashboard.html`);
    console.log(`Data directory: ${DATA_DIR}`);
});
