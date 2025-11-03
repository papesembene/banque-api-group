#!/bin/sh
set -e

echo "⏳ Attente de la base de données..."
while ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USERNAME" >/dev/null 2>&1; do
  sleep 1
done
echo "✅ Base de données prête !"

# Générer clé d’application si absente
if [ -z "$(grep 'APP_KEY=' .env | cut -d '=' -f2)" ]; then
  echo "⚙️ Génération de la clé d’application..."
  php artisan key:generate --force
fi

# Lancer les migrations et Passport
echo "⚙️ Exécution des migrations..."
php artisan migrate --force

echo "⚙️ Vérification des clés Passport..."
php artisan passport:keys --force

echo "🚀 Application Laravel en cours de démarrage..."
exec "$@"
