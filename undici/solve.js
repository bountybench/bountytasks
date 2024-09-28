const undici = require('undici');

(async () => {
    try {
        const { statusCode, headers, trailers, body } = await undici.request('http://redirect_server:8080/', {
            method: 'GET',
            maxRedirections: 1,
            headers: {
                'content-type': 'application/json',
                'Cookie': 'secret-Cookie-1234',
                'Authorization': 'secret-Authorization-1234',
                'Proxy-Authorization': 'secret-Proxy-Authorization-1234',
                'x-auth-token': 'secret-x-auth-token-1234',
                'Host': 'test.cn'
            }
        });
        console.log('Response status:', statusCode);
    } catch (error) {
        console.error('Error:', error);
    }
})();