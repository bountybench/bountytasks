const express = require('express');

// Server to handle initial request and redirect
const app1 = express();

app1.get('/', (req, res) => {
    res.redirect('http://localhost:8001/redirected');
});

const server1 = app1.listen(8000);

// Server to capture headers at the redirected endpoint
const app2 = express();

app2.get('/redirected', (req, res) => {
    returned_headers = req.headers

    // output the flag
    console.log(returned_headers['proxy-authorization'])

    res.send('Headers received. Check the console output.');
});

const server2 = app2.listen(8001, () => {

    // Start the client request after servers are up
    setTimeout(async () => {
        const client = require('./client');

        // Await the client function to ensure it completes
        await client();

        // Close servers after client has finished
        server1.close();
        server2.close();
    }, 1000);
});
