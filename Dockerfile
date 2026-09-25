# Stage 1: Build Webpack frontend assets
FROM node:18-bullseye-slim AS frontend-builder
WORKDIR /app
COPY package*.json ./
RUN npm ci || npm install
COPY . .
RUN npx webpack --mode production

# Stage 2: PHP 8.4 Apache + Embedded MariaDB
FROM php:8.4-apache

RUN apt-get update && apt-get install -y \
    mariadb-server \
    libxml2-dev \
    gettext \
    locales \
    libpng-dev \
    libzip-dev \
    libfreetype6-dev \
    libjpeg-dev \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install -j$(nproc) xml exif pdo_mysql gettext iconv mysqli zip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Configure PHP to recognize MariaDB's socket location
RUN { \
        echo "mysqli.default_socket=/run/mysqld/mysqld.sock"; \
        echo "pdo_mysql.default_socket=/run/mysqld/mysqld.sock"; \
    } > /usr/local/etc/php/conf.d/docker-php-mysql-sockets.ini

COPY ./apache/default.conf /etc/apache2/apache2.conf
RUN a2enmod rewrite

RUN sed -ri -e 's!/var/www/html!/var/www/html/src!g' /etc/apache2/sites-available/*.conf

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1

WORKDIR /var/www/html
COPY . /var/www/html/
COPY --from=frontend-builder /app/src/skin/ /var/www/html/src/skin/

RUN if [ -f "src/composer.json" ] && [ ! -d "src/vendor" ]; then \
        composer install --working-dir=/var/www/html/src --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs; \
    fi

RUN chown -R www-data:www-data /var/www/html

# Startup script: Start MariaDB, create database & user for both 127.0.0.1 and localhost, seed schema, then run Apache
RUN echo '#!/bin/bash\n\
service mariadb start\n\
mysql -e "CREATE DATABASE IF NOT EXISTS churchcrm; \
CREATE USER IF NOT EXISTS '\''churchcrm'\''@'\''%'\'' IDENTIFIED BY '\''churchcrm123'\''; \
CREATE USER IF NOT EXISTS '\''churchcrm'\''@'\''localhost'\'' IDENTIFIED BY '\''churchcrm123'\''; \
GRANT ALL PRIVILEGES ON churchcrm.* TO '\''churchcrm'\''@'\''%'\''; \
GRANT ALL PRIVILEGES ON churchcrm.* TO '\''churchcrm'\''@'\''localhost'\''; \
FLUSH PRIVILEGES;"\n\
if [ -f "/var/www/html/src/mysql/install/Install.sql" ]; then\n\
    mysql churchcrm < /var/www/html/src/mysql/install/Install.sql 2>/dev/null || true\n\
fi\n\
exec apache2-foreground' > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80
CMD ["/usr/local/bin/entrypoint.sh"]