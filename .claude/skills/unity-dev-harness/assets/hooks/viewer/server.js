const express = require('express');
const fs = require('fs');
const fsp = require('fs/promises');
const path = require('path');
const chokidar = require('chokidar');

const ARTIFACT_FILES = [
    { key: '00-input', title: '00. 입력 정리' },
    { key: '01-design', title: '01. 설계' },
    { key: '02-validation', title: '02. 검증 (4단계 게이트)' },
    { key: '03-review', title: '03. 리뷰' },
    { key: '04-user-feedback', title: '04. 사용자 검증 피드백' },
    { key: 'improvement-log', title: '개선 기록' }
];

const app = express();
const port = Number(process.env.PORT || 5179);
const writableKeys = new Set(['04-user-feedback']);
const artifactMap = new Map(ARTIFACT_FILES.map(item => [item.key, item]));
const sseClients = new Set();

function existsDir(dir) {
    try {
        return fs.statSync(dir).isDirectory();
    }
    catch {
        return false;
    }
}

function findUp(startDir, matcher) {
    let current = path.resolve(startDir);

    while (true) {
        if (matcher(current)) {
            return current;
        }

        const parent = path.dirname(current);

        if (parent === current) {
            return null;
        }

        current = parent;
    }
}

function inferProjectDir() {
    if (process.env.CLAUDE_PROJECT_DIR) {
        return path.resolve(process.env.CLAUDE_PROJECT_DIR);
    }

    const candidates = [process.cwd(), __dirname];

    for (const candidate of candidates) {
        const hit = findUp(candidate, dir => existsDir(path.join(dir, 'artifacts')) && existsDir(path.join(dir, '.claude')));

        if (hit) {
            return hit;
        }
    }

    for (const candidate of candidates) {
        const hit = findUp(candidate, dir => existsDir(path.join(dir, 'artifacts')));

        if (hit) {
            return hit;
        }
    }

    const hookRootCandidate = path.resolve(__dirname, '..', '..', '..');

    if (path.basename(path.dirname(__dirname)).toLowerCase() === 'hooks') {
        return hookRootCandidate;
    }

    return process.cwd();
}

function inferArtifactDir(projectDir) {
    if (process.env.ARTIFACT_DIR) {
        return path.resolve(process.env.ARTIFACT_DIR);
    }

    return path.resolve(projectDir, 'artifacts');
}

function inferStaticDir() {
    const publicDir = path.resolve(__dirname, 'public');

    if (existsDir(publicDir)) {
        return publicDir;
    }

    return __dirname;
}

const projectDir = inferProjectDir();
const artifactDir = inferArtifactDir(projectDir);
const staticDir = inferStaticDir();

app.use(express.json({ limit: '2mb' }));
app.use(express.static(staticDir));

function getArtifactPath(key) {
    const item = artifactMap.get(key);

    if (!item) {
        return null;
    }

    return path.join(artifactDir, `${item.key}.md`);
}

async function readArtifact(item) {
    const filePath = getArtifactPath(item.key);

    try {
        const content = await fsp.readFile(filePath, 'utf8');
        return { ...item, fileName: `${item.key}.md`, exists: true, content };
    }
    catch (error) {
        if (error.code === 'ENOENT') {
            return { ...item, fileName: `${item.key}.md`, exists: false, content: null };
        }

        throw error;
    }
}

async function readAllArtifacts() {
    await fsp.mkdir(artifactDir, { recursive: true });
    return Promise.all(ARTIFACT_FILES.map(item => readArtifact(item)));
}

function sendEvent(payload) {
    const text = `data: ${JSON.stringify(payload)}\n\n`;

    for (const res of sseClients) {
        res.write(text);
    }
}

app.get('/api/health', (req, res) => {
    res.json({ ok: true, app: 'unity-dev-harness-viewer', version: '1.2.0', projectDir, artifactDir, staticDir });
});

app.get('/api/artifacts', async (req, res) => {
    try {
        const files = await readAllArtifacts();
        res.json({ projectDir, artifactDir, files });
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to read artifacts.', detail: error.message });
    }
});

app.get('/api/artifacts/:key', async (req, res) => {
    const item = artifactMap.get(req.params.key);

    if (!item) {
        res.status(404).json({ error: 'Unknown artifact key.' });
        return;
    }

    try {
        const file = await readArtifact(item);
        res.json({ projectDir, artifactDir, file });
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to read artifact.', detail: error.message });
    }
});

app.post('/api/artifacts/:key', async (req, res) => {
    const key = req.params.key;

    if (!writableKeys.has(key)) {
        res.status(403).json({ error: 'This artifact is read-only from the viewer.' });
        return;
    }

    if (typeof req.body.content !== 'string') {
        res.status(400).json({ error: 'content must be a string.' });
        return;
    }

    try {
        await fsp.mkdir(artifactDir, { recursive: true });
        await fsp.writeFile(getArtifactPath(key), req.body.content, 'utf8');
        sendEvent({ type: 'saved', fileName: `${key}.md` });
        res.json({ ok: true, projectDir, artifactDir, fileName: `${key}.md` });
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to save artifact.', detail: error.message });
    }
});

app.post('/api/feedback', async (req, res) => {
    if (typeof req.body.content !== 'string') {
        res.status(400).json({ error: 'content must be a string.' });
        return;
    }

    try {
        await fsp.mkdir(artifactDir, { recursive: true });
        await fsp.writeFile(getArtifactPath('04-user-feedback'), req.body.content, 'utf8');
        sendEvent({ type: 'saved', fileName: '04-user-feedback.md' });
        res.json({ ok: true, projectDir, artifactDir, fileName: '04-user-feedback.md' });
    }
    catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Failed to save feedback.', detail: error.message });
    }
});

app.get('/api/events', (req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders?.();
    res.write(`data: ${JSON.stringify({ type: 'connected' })}\n\n`);
    sseClients.add(res);
    req.on('close', () => sseClients.delete(res));
});

app.get('*', (req, res) => {
    res.sendFile(path.join(staticDir, 'viewer.html'));
});

async function main() {
    await fsp.mkdir(artifactDir, { recursive: true });
    chokidar.watch(artifactDir, { ignoreInitial: true }).on('all', (event, filePath) => {
        const fileName = path.basename(filePath);
        sendEvent({ type: event, fileName });
        console.log(`[${event}] ${fileName}`);
    });
    app.listen(port, '127.0.0.1', () => {
        console.log(`Eval viewer: http://localhost:${port}`);
        console.log(`Project dir: ${projectDir}`);
        console.log(`Artifact dir: ${artifactDir}`);
        console.log(`Static dir: ${staticDir}`);
    });
}

main().catch(error => {
    console.error(error);
    process.exit(1);
});
