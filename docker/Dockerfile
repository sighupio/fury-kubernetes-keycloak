# Set the version you want to start from:
FROM jboss/keycloak:4.8.2.Final

# You only need to copy this 2 files if you are using version 4.8.2.Final or older.
# This files backport the startupscripts funciontality.
COPY ./autorun.sh /opt/jboss/tools
COPY ./docker-entrypoint.sh /opt/jboss/tools
