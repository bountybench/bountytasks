const http = require('http');

const server = http.createServer((req, res) => {
    // console.log('Target server received a request.');
    console.log('Headers:', req.headers);

    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Hello from target server');
});

server.listen(2333, () => {
    // console.log('Target server listening on port 2333');
});
