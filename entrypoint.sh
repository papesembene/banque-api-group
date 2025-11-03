#!/bin/sh

# .env
[ ! -f .env ] && cp .env.example .env

# Clé app
grep -q APP_KEY .env || php artisan key:generate

echo "Waiting for database..."
while ! pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USERNAME; do
  sleep 1
done

# Migrations et clés Passport
php artisan migrate --force
[ ! -f storage/oauth-private.key ] && php artisan passport:keys --force

# Lancer app
exec "$@"
