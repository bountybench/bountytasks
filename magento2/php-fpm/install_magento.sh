#!/bin/bash 
set -x

echo "Waiting for database to be ready..."
until mysqladmin ping -h "$DB_HOST" --silent; do
    sleep 5
done
echo "Database is ready, proceeding with Magento installation."
db credentials

if [ ! -f /var/www/html/app/etc/env.php ]; then
    echo "Magento is not installed. Starting installation..."

    composer config --global http-basic.${COMPOSER_AUTH_URL} "${PUBLIC_KEY}" "${PRIVATE_KEY}"

    # Install magento
    # composer install
    composer create-project --repository-url=https://${COMPOSER_AUTH_URL}/ magento/project-community-edition=2.4.7 /var/www/html --no-interaction 

    chown -R www-data:www-data .
    chmod u+x bin/magento
    
    cd /var/www/html
    
    # Install Magento with Magento CLI
    php bin/magento setup:install \
        --base-url=http://magento.test \
        --db-host=${DB_HOST} \
        --db-name=${MYSQL_DATABASE} \
        --db-user=${MYSQL_USER} \
        --db-password=${MYSQL_PASSWORD} \
        --admin-firstname=${ADMIN_FIRSTNAME} \
        --admin-lastname=${ADMIN_LASTNAME} \
        --admin-email=${ADMIN_EMAIL} \
        --admin-user=${ADMIN_USER} \
        --admin-password=${ADMIN_PASSWORD} \
        --language=en_US \
        --currency=USD \
        --timezone=America/New_York \
        --use-rewrites=1 \
        --search-engine=elasticsearch7 \
        --elasticsearch-host=${ELASTICSEARCH_HOST} \
        --elasticsearch-port=${ELASTICSEARCH_PORT} \
        --elasticsearch-enable-auth=0 \
        --elasticsearch-index-prefix=magento2 \
        --elasticsearch-timeout=15
    
    # Additional setup steps
    echo "Running additional Magento setup commands..."
    php bin/magento setup:upgrade
    php bin/magento setup:di:compile
    php bin/magento cache:flush

    echo "Magento installation completed!"
else
    echo "Magento is already installed. Skipping."
fi