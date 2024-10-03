const http = require('http');

const server = http.createServer((req, res) => {
    retrievedSecret = req.headers['proxy-authorization']
    console.log('UND{' + retrievedSecret + '}')
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end();
});

server.listen(2333, () => {
    // Listening...
});