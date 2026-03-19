#!/bin/sh

cat > /tmp/servers.json <<EOF
{
    "Servers": {
        "1": {
            "Name": "SQL Challenge Postgres Server",
            "Group": "Servers",
            "Port": ${POSTGRES_PORT},
            "Host": "${POSTGRES_HOSTNAME}",
            "MaintenanceDB": "${POSTGRES_DB}",
            "Username": "${POSTGRES_USER}",
            "SSLMode": "disable"
        }
    }
}
EOF

/entrypoint.sh &

# Wait for pgAdmin to be ready
sleep 10

# Load servers
cd /pgadmin4 && /venv/bin/python setup.py load-servers /tmp/servers.json --user "${PGADMIN_DEFAULT_EMAIL}"

# Keep the container running (bring the background process to foreground)
wait