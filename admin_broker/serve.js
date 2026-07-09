const http = require('http');
const fs = require('fs');
const path = require('path');

// Port to run the server on
const PORT = process.env.PORT || 8080;
const PUBLIC_DIR = path.join(__dirname, 'build', 'web');

// Common MIME types for Flutter Web assets
const MIME_TYPES = {
  '.html': 'text/html; charset=UTF-8',
  '.css': 'text/css; charset=UTF-8',
  '.js': 'application/javascript; charset=UTF-8',
  '.json': 'application/json; charset=UTF-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

const server = http.createServer((req, res) => {
  // Extract path and decode URL to support spaces and special characters
  const decodedUrl = decodeURIComponent(req.url.split('?')[0]);
  let filePath = path.join(PUBLIC_DIR, decodedUrl);

  // If path refers to a directory (or has no extension), check if the file exists.
  // If not, treat it as an SPA route and fall back to serving index.html.
  if (decodedUrl.endsWith('/') || !path.extname(filePath)) {
    if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
      filePath = path.join(PUBLIC_DIR, 'index.html');
    }
  }

  const extname = String(path.extname(filePath)).toLowerCase();
  const contentType = MIME_TYPES[extname] || 'application/octet-stream';

  fs.readFile(filePath, (error, content) => {
    if (error) {
      if (error.code === 'ENOENT') {
        // Fall back to index.html for SPA deep linking
        fs.readFile(path.join(PUBLIC_DIR, 'index.html'), (err, fallbackContent) => {
          if (err) {
            res.writeHead(500, { 'Content-Type': 'text/plain' });
            res.end('Error loading index.html: ' + err.code);
          } else {
            res.writeHead(200, { 'Content-Type': 'text/html; charset=UTF-8' });
            res.end(fallbackContent, 'utf-8');
          }
        });
      } else {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('Server Error: ' + error.code);
      }
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});

server.listen(PORT, () => {
  console.log(`\n🚀 Server is running on localhost!`);
  console.log(`👉 URL: http://localhost:${PORT}`);
  console.log(`\nPress Ctrl+C to stop.`);
});
