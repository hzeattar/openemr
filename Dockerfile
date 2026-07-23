# Railway deployment image for OpenEMR
# Uses the official stable production image instead of rebuilding the full source tree.
FROM openemr/openemr:8.2.0

# OpenEMR's Apache service listens on port 80 inside the container.
ENV PORT=80
EXPOSE 80

# Railway persistent volumes are empty bind mounts. Seed the official OpenEMR
# sites skeleton before the upstream startup script performs first-time setup.
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh

# Fail the image build if an upstream image layout change would make the Railway
# bootstrap unsafe. The static file is intentionally independent of OpenEMR's
# database-backed readiness endpoint and becomes available when Apache starts.
RUN test -d /swarm-pieces/sites/default \
    && test -f /root/docker-version \
    && test -x /var/www/localhost/htdocs/openemr/openemr.sh \
    && chmod 755 /usr/local/bin/railway-entrypoint.sh \
    && printf 'ok\n' > /var/www/localhost/htdocs/openemr/railway-health \
    && chown apache:apache /var/www/localhost/htdocs/openemr/railway-health \
    && chmod 444 /var/www/localhost/htdocs/openemr/railway-health

CMD ["/usr/local/bin/railway-entrypoint.sh"]
