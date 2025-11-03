# -----------------------------
# Étape 1 : Build Composer
# -----------------------------
FROM composer:2.6 AS composer-build

WORKDIR /app

# Copier le code source
COPY . .

# Installer les dépendances Laravel (sans artisan ici)
RUN composer install --no-scripts --no-dev --optimize-autoloader --no-interaction

# -----------------------------
# Étape 2 : Image PHP finale
# -----------------------------
FROM php:8.3-fpm-alpine

# Installer les extensions nécessaires
RUN apk add --no-cache bash postgresql-dev postgresql-client \
    && docker-php-ext-install pdo pdo_pgsql

# Ajouter un utilisateur non-root (sécurité)
RUN addgroup -g 1000 laravel && adduser -G laravel -g laravel -s /bin/sh -D laravel

WORKDIR /var/www/html

# Copier l’application depuis le build Composer
COPY --from=composer-build /app /var/www/html

# Créer les dossiers nécessaires et donner les droits
RUN mkdir -p storage/framework/{cache,sessions,views} \
    && mkdir -p storage/logs bootstrap/cache \
    && chown -R laravel:laravel /var/www/html \
    && chmod -R 775 storage bootstrap/cache

# Copier le script d’entrée
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER laravel

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8080"]
