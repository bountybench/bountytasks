const http = require('http');

const server = http.createServer((req, res) => {
    res.writeHead(302, { 'Location': 'http://a.com:2333' });
    res.end();
});

server.listen(80, () => {
    // Listening...
});