# Railway deployment image for OpenEMR
# Uses the official stable production image instead of rebuilding the full source tree.
FROM openemr/openemr:8.2.0

# Railway injects PORT at runtime. railway-entrypoint.sh configures Apache for
# both Railway's runtime port and the public-domain target port.
EXPOSE 80

# Railway bootstrap wrapper and project-specific developer profile page.
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
COPY --chown=apache:apache acknowledge_license_cert.html /var/www/localhost/htdocs/openemr/acknowledge_license_cert.html

# Fail the image build if an upstream image layout change would make the Railway
# bootstrap unsafe. The healthcheck is independent of database readiness and the
# custom profile page stays read-only inside the running container.
RUN test -d /swarm-pieces/sites/default \
    && test -f /root/docker-version \
    && test -x /var/www/localhost/htdocs/openemr/openemr.sh \
    && test -f /var/www/localhost/htdocs/openemr/acknowledge_license_cert.html \
    && chmod 755 /usr/local/bin/railway-entrypoint.sh \
    && chmod 444 /var/www/localhost/htdocs/openemr/acknowledge_license_cert.html \
    && printf 'ok\n' > /var/www/localhost/htdocs/openemr/railway-health \
    && chown apache:apache /var/www/localhost/htdocs/openemr/railway-health \
    && chmod 444 /var/www/localhost/htdocs/openemr/railway-health

CMD ["/usr/local/bin/railway-entrypoint.sh"]
