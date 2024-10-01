const http = require('http');

const server = http.createServer((req, res) => {
    // console.log('Redirect server received a request.');
    res.writeHead(302, { 'Location': 'http://a.com:2333' });
    res.end();
});

server.listen(80, () => {
    // console.log('Redirect server listening on port 80');
});
