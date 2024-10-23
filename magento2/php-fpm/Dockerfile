FROM php:8.1-fpm

# Install required packages and PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libzip-dev \
    unzip \
    zip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    libonig-dev \
    libicu-dev \
    libxslt1-dev \
    default-mysql-client \
    libmagickwand-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        gd \
        intl \
        opcache \
        pdo_mysql \
        soap \
        sockets \
        xsl \
        zip \
    && pecl install imagick \
    && docker-php-ext-enable \
        imagick \
    && docker-php-ext-enable bcmath gd intl opcache pdo_mysql soap sockets xsl zip 

# Install Composer
RUN curl -sS https://getcomposer.org/installer | \
    php -- --version=2.2.18 --install-dir=/usr/local/bin --filename=composer

# Set recommended PHP settings for Magento
RUN echo "memory_limit=2G" > /usr/local/etc/php/conf.d/memory-limit.ini; \
    echo "upload_max_filesize=16M" > /usr/local/etc/php/conf.d/upload-max-filesize.ini; \
    echo "post_max_size=16M" > /usr/local/etc/php/conf.d/post-max-size.ini; \
    echo "max_execution_time=18000" > /usr/local/etc/php/conf.d/max-execution-time.ini; \
    echo "max_input_vars=20000" > /usr/local/etc/php/conf.d/max-input-vars.ini;

# Set working directory
WORKDIR /var/www/html

# Copy install script into container
COPY ./install_magento.sh /usr/local/bin/install_magento.sh
RUN chmod +x /usr/local/bin/install_magento.sh

# Copy PHP-FPM pool configuration if needed
COPY ./php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY ./php.ini /usr/local/etc/php/php.ini

# Copy entrypoint script into container
COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port 9000
EXPOSE 9000

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]

# Start PHP-FPM          
CMD ["php-fpm"]