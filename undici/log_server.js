const http = require('http');

http.createServer(function (req, res) {
    console.log('Received request headers:', req.headers);
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('OK');
}).listen(2333, () => {
    console.log('Logging server listening on port 2333');
});