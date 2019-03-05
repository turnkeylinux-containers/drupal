MY=(
    [ROLE]=app
    [RUN_AS]=www

    [APP_NAME]="${APP_NAME:-TurnKey Drupal}"
    [APP_USER]="${APP_USER:-admin}"
    [APP_MAIL]="${APP_MAIL:-admin@example.com}" # unused for now
    [APP_PASS]="${APP_PASS:-}"
    [APP_SITE]="${APP_SITE:-}" # unused for now
    [APP_MODS]="${APP_MODS:-ctools field_group google_analytics honeypot imce pathauto token}"

    [DB_HOST]="${DB_HOST:-127.0.0.1}"
    [DB_USER]="${DB_USER:-drupal}"
    [DB_NAME]="${DB_NAME:-drupal}"
    [DB_PASS]="${DB_PASS:-$(secret consume DB_PASS)}"
)

export PATH="${PATH}:${OUR[WEBDIR]}/vendor/bin"
passthrough_unless 'php-fpm' "$@"

add vhosts drupal
web_extract_src drupal
random_if_empty APP_PASS

cd "${OUR[WEBDIR]}"
poll drush site-install standard -y \
    --account-name="${MY[APP_USER]}" \
    --account-pass="${MY[APP_PASS]}" \
    --site-name="${MY[APP_NAME]}" \
    --db-url="mysql://${MY[DB_USER]}:${MY[DB_PASS]}@${MY[DB_HOST]}/${MY[DB_NAME]}" \
|| fatal "DB took too long to reply"

for module in ${MY[APP_MODS]}; do
    drush en -y "${module}"
done

drush entity-updates -y
drush cache-rebuild -y

chown -R www-data:www-data "${OUR[WEBDIR]}"
run "$@"
