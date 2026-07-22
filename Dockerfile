# Railway deployment image for OpenEMR
# Uses the official stable production image instead of rebuilding the full source tree.
FROM openemr/openemr:8.2.0

# OpenEMR's Apache service listens on port 80 inside the container.
ENV PORT=80
EXPOSE 80

# Railway persistent volumes are empty bind mounts. Seed the official OpenEMR
# sites skeleton before the upstream startup script performs first-time setup.
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 755 /usr/local/bin/railway-entrypoint.sh

CMD ["/usr/local/bin/railway-entrypoint.sh"]
