#!/bin/sh

set -e

run_migrations() {
    ${ETESYNC_DIRECTORY}/manage.py migrate
}

create_admin_user() {
    username="admin"

    password="${ETESYNC_INITIAL_ADMIN_PASSWORD}"
    if [ -z "${password}" ]; then
        password=$(openssl rand -base64 21)
        password_generated=true
    fi

    echo "from django.contrib.auth.models import User; User.objects.create_superuser('${username}', '', '${password}')" | ${ETESYNC_DIRECTORY}/manage.py shell

    echo ""
    printf "%76s\n" | tr " " "#"
    printf "## %-70s ##\n" "Created a new administrator user."
    printf "## %-70s ##\n" "  Username: ${username}"
    if [ "${password_generated}" = true ]; then
        printf "## %-70s ##\n" "  Password: ${password}"
    else
        printf "## %-70s ##\n" "  Password: Specified through an environment variable"
    fi
    printf "## %-70s ##\n" ""
    printf "## %-70s ##\n" "Open http://localhost:${ETESYNC_PORT}/admin (or the location where you mapped"
    printf "## %-70s ##\n" "the HTTP port) to manage users."
    printf "%76s\n" | tr " " "#"
    echo ""
}

if [ ! -f "${ETESYNC_DATA_DIRECTORY}/${ETESYNC_DATABASE_FILE}" ]; then
    run_migrations
    create_admin_user
else
    run_migrations
fi

# Run the server.
echo "Running server on port ${ETESYNC_PORT}..."
uwsgi /etc/uwsgi/uwsgi.ini > /dev/null
