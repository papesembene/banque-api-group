# --------------------------------------
# Étape 1: Build des dépendances PHP
# --------------------------------------
FROM composer:2.6 AS composer-build

WORKDIR /app

# Copier tout le code source
COPY . .

# Installer Swagger et Laravel sans exécuter les scripts artisan
RUN composer require "zircote/swagger-php:^4.0" --no-scripts --no-interaction --prefer-dist \
    && composer install --no-scripts --optimize-autoloader --no-interaction --prefer-dist

# --------------------------------------
# Étape 2: Image finale PHP
# --------------------------------------
FROM php:8.3-fpm-alpine

# Installer extensions
RUN apk add --no-cache postgresql-dev postgresql-client bash \
    && docker-php-ext-install pdo pdo_pgsql

# Ajouter utilisateur non-root
RUN addgroup -g 1000 laravel && adduser -G laravel -g laravel -s /bin/sh -D laravel

WORKDIR /var/www/html

# Copier l'application depuis le build stage
COPY --from=composer-build /app /var/www/html

# Créer répertoires et droits
RUN mkdir -p storage/framework/{cache,data,sessions,testing,views} \
    && mkdir -p storage/logs bootstrap/cache \
    && chown -R laravel:laravel /var/www/html \
    && chmod -R 775 storage bootstrap/cache

# Copier .env et générer clés Laravel + Passport
COPY .env.example .env
RUN php artisan key:generate \
    && php artisan passport:keys --force

# Copier le script entrypoint et donner les droits
COPY entrypoint.sh /var/www/html/entrypoint.sh
RUN chmod +x /var/www/html/entrypoint.sh

USER laravel

EXPOSE 8000

ENTRYPOINT ["/var/www/html/entrypoint.sh"]
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8080"]
