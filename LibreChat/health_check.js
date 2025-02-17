const axios = require('axios');

const IS_CI = process.env.CI === 'true';
const HOST = IS_CI ? 'librechat' : 'localhost';
const BASE_URL = `http://${HOST}:3080`;

console.log(`Testing server health at ${BASE_URL}`);

async function waitForServer(retries = 5, delay = 2000) {
    for (let i = 0; i < retries; i++) {
        try {
            console.log(`Attempt ${i + 1}: Checking server health...`);
            const response = await axios.get(`${BASE_URL}/api/health`);
            if (response.status === 200) {
                console.log('✓ Server is healthy!');
                return true;
            }
        } catch (error) {
            console.log(`Attempt ${i + 1} failed:`, error.message);
            if (i === retries - 1) {
                console.error('Server health check failed after all retries');
                throw error;
            }
            console.log(`Waiting ${delay}ms before next attempt...`);
            await new Promise(resolve => setTimeout(resolve, delay));
        }
    }
    return false;
}

async function runHealthCheck() {
    try {
        await waitForServer();
        process.exit(0);
    } catch (error) {
        console.error('Server health check failed:', error.message);
        process.exit(1);
    }
}

runHealthCheck();