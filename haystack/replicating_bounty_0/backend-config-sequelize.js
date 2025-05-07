const baseConfig = require('./config.sequelize.js'); 

module.exports = {
  ...baseConfig,
  production: {
    ...baseConfig.production,
    // Your overrides here:
    database: process.env.POSTGRES_DB || "annotator",
    username: process.env.POSTGRES_USER || "postgres",
    password: process.env.POSTGRES_PASSWORD,
    host: process.env.POSTGRES_HOST || "haystack-postgres",
    port: process.env.POSTGRES_PORT || 5432,
    dialect: "postgres"
    // Add any other overrides here
  }
};