FROM php:8.2-apache

LABEL maintainer="dl@varme.pw"

ENV TZ=Europe/Moscow

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ARG COMPOSER_VERSION="2.5.4"

RUN set -ex && \
    apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libgmp-dev \
        libwebp-dev \
        libxml2-dev \
        zlib1g-dev \
        libncurses5-dev \
        libldb-dev \
        libldap2-dev \
        libicu-dev \
        libmemcached-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libsqlite3-dev \
        libzip-dev \
        libonig-dev \
        curl \
        ssmtp \
        wget \
        git \
        nano \
        zip \
        mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN pecl install xdebug \
    && pecl install memcached \
    && pecl install redis \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
    && docker-php-ext-configure mysqli --with-mysqli=mysqlnd \
    && docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) mysqli pdo_mysql exif bcmath pcntl intl gmp mbstring gd soap zip opcache sockets

RUN wget https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar -O /usr/local/bin/composer && \
    chmod a+rx /usr/local/bin/composer

RUN groupadd --gid 1000 1000 && \
    usermod --non-unique --uid 1000 www-data && \
    usermod --gid 1000 www-data

RUN mkdir /var/www/.composer && \
    mkdir /var/www/.ssh

RUN chown www-data:www-data /var/www -R && \
    chown www-data:www-data /usr/local/etc/php/conf.d -R && \
    chown www-data:www-data /var/www/.composer && \
    chown www-data:www-data /var/www/.ssh

RUN echo 'DocumentRoot ${DOCUMENT_ROOT}' >> /etc/apache2/apache2.conf && \
    echo 'ServerName ${HOST_NAME}' > /etc/apache2/conf-enabled/default.conf && \
    echo 'ServerSignature Off' > /etc/apache2/conf-enabled/z-security.conf && \
    echo 'ServerTokens Minimal' >> /etc/apache2/conf-enabled/z-security.conf && \
    rm /etc/apache2/sites-enabled/000-default.conf

RUN a2enmod rewrite

COPY php.ini /usr/local/etc/php
COPY ssmtp.conf /etc/ssmtp/
COPY .bashrc /var/www/
COPY docker-entrypoint.sh /entrypoint.sh

WORKDIR /var/www
USER www-data:www-data

ENTRYPOINT ["/entrypoint.sh"]
