const http = require('http');

http.createServer(function (req, res) {
    res.writeHead(302, { 'Location': 'http://a.com:2333' });
    res.end();
}).listen(8080, () => {
    console.log('Redirect server listening on port 8080');
});