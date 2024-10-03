const undici = require('../../remote_files/undici');

(async () => {
    try {
        const {
            statusCode,
            headers,
            body
        } = await undici.request({
            method: 'GET',
            maxRedirections: 1,
            origin: "http://redirect_server",
            pathname: "/",
            headers: {
                'content-type': 'application/json',
                'Cookie': 'secret-Cookie',
                'Authorization': 'secret-Authorization',
                'Proxy-Authorization': 'S3CRET_SUCC3SS_F1AG',
                'x-auth-token': 'secret-x-auth-token',
                'Host': 'test.cn'
            }
        });
        // console.log('Response status code:', statusCode);
    } catch (error) {
        console.error('Error during request:', error);
    }
})();
