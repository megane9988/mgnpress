#!/usr/bin/env bash

set -ex;

mysql.server start

DB_USER=${1-root}
DB_PASS=$2
DB_NAME=${3-mgnwordpress}
PORT=8080
WP_PATH=$(pwd)/www
WP_TITLE='Welcome to the WordPress'
WP_DESC='Hello World!'

if [ -e "$WP_PATH/wp-config.php" ]; then
    open http://127.0.0.1:$PORT
    bin/wp server --host=0.0.0.0 --port=$PORT --docroot=$WP_PATH
    exit 0
fi

if ! bin/wp --info ; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli-nightly.phar
    rm -fr bin && mkdir bin
    mv wp-cli-nightly.phar bin/wp
    chmod 755 bin/wp
fi

echo "path: www" > $(pwd)/wp-cli.yml

if [ $DB_PASS ]; then
    echo "DROP DATABASE IF EXISTS $DB_NAME;" | mysql -u$DB_USER -p$DB_PASS
    echo "CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;" | mysql -u$DB_USER -p$DB_PASS
else
    echo "DROP DATABASE IF EXISTS $DB_NAME;" | mysql -u$DB_USER
    echo "CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;" | mysql -u$DB_USER
fi
bin/wp core download --path=$WP_PATH --locale=ja --force

if [ $DB_PASS ]; then
bin/wp core config \
--dbhost=localhost \
--dbname="$DB_NAME" \
--dbuser="$DB_USER" \
--dbpass="$DB_PASS" \
--dbprefix=wp_ \
--locale=en_US \
--extra-php <<PHP
define( 'JETPACK_DEV_DEBUG', true );
define( 'WP_DEBUG', true );
PHP
else
bin/wp core config \
--dbhost=localhost \
--dbname=$DB_NAME \
--dbuser=$DB_USER \
--dbprefix=wp_ \
--locale=en_US \
--extra-php <<PHP
define( 'JETPACK_DEV_DEBUG', true );
define( 'WP_DEBUG', true );
PHP
fi

bin/wp core install \
--url=http://127.0.0.1:$PORT \
--title="WordPress" \
--admin_user="admin" \
--admin_password="admin" \
--admin_email="admin@example.com"

bin/wp rewrite structure "/archives/%post_id%"

bin/wp option update blogname "$WP_TITLE"
bin/wp option update blogdescription "$WP_DESC"
bin/wp plugin install show-current-template wp-sitemanager mw-wp-form smart-custom-field intuitive-custom-post-order --activate

if [ -e "provision-post.sh" ]; then
    bash provision-post.sh
fi

open http://127.0.0.1:$PORT
bin/wp server --host=0.0.0.0 --port=$PORT --docroot=$WP_PATH
