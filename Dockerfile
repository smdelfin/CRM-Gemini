FROM php:8.4-apache

# 1. Install system dependencies and PHP extensions required by ChurchCRM
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    gettext \
    locales \
    locales-all \
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

# 2. Load global Apache configuration and enable rewrite
COPY ./apache/default.conf /etc/apache2/apache2.conf
RUN a2enmod rewrite

# 3. Configure DocumentRoot to serve directly from /var/www/html/src
RUN sed -ri -e 's!/var/www/html!/var/www/html/src!g' /etc/apache2/sites-available/*.conf

# 4. Pull Composer binary and configure root execution
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1

# 5. Copy full application source code
WORKDIR /var/www/html
COPY . /var/www/html/

# 6. Install PHP dependencies inside src/ if vendor is absent
RUN if [ -f "src/composer.json" ] && [ ! -d "src/vendor" ]; then \
        composer install --working-dir=/var/www/html/src --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs; \
    elif [ -f "composer.json" ] && [ ! -d "vendor" ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs; \
    fi

# 7. Grant ownership to Apache web server user
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
