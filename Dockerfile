# Railway deployment image for OpenEMR
# Uses the official stable production image instead of rebuilding the full source tree.
FROM openemr/openemr:8.2.0

# Railway injects PORT at runtime. railway-entrypoint.sh configures Apache for
# both Railway's runtime port and the public-domain target port.
EXPOSE 80

# Runtime bootstrap and project-owned static/customization files.
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
COPY --chown=apache:apache acknowledge_license_cert.html /var/www/localhost/htdocs/openemr/acknowledge_license_cert.html

RUN mkdir -p /var/www/localhost/htdocs/openemr/assets/clinic /opt/openemr-ops

# Keep authentication logic in OpenEMR while replacing only the presentation
# templates and adding a privacy-safe installable application shell.
COPY --chown=apache:apache customizations/login/base.html.twig /var/www/localhost/htdocs/openemr/templates/login/base.html.twig
COPY --chown=apache:apache customizations/login/vertical_band.html.twig /var/www/localhost/htdocs/openemr/templates/login/layouts/vertical_band.html.twig
COPY --chown=apache:apache customizations/pwa/manifest.webmanifest /var/www/localhost/htdocs/openemr/manifest.webmanifest
COPY --chown=apache:apache customizations/pwa/service-worker.js /var/www/localhost/htdocs/openemr/service-worker.js
COPY --chown=apache:apache customizations/pwa/clinic-icon.svg /var/www/localhost/htdocs/openemr/assets/clinic/clinic-icon.svg
COPY customizations/apache/security.conf /etc/apache2/conf.d/zz-openemr-security.conf
COPY ops/ /opt/openemr-ops/
COPY IMPLEMENTATION_STATUS.md /opt/openemr-ops/IMPLEMENTATION_STATUS.md

# Fail the image build if an upstream image layout change would make the Railway
# bootstrap or the reviewed customization overlay unsafe. All customized web
# files remain read-only; operational scripts are executable but never run
# automatically during application startup.
RUN test -d /swarm-pieces/sites/default \
    && test -f /root/docker-version \
    && test -x /var/www/localhost/htdocs/openemr/openemr.sh \
    && test -f /var/www/localhost/htdocs/openemr/templates/login/base.html.twig \
    && test -f /var/www/localhost/htdocs/openemr/templates/login/layouts/vertical_band.html.twig \
    && test -f /var/www/localhost/htdocs/openemr/manifest.webmanifest \
    && test -f /var/www/localhost/htdocs/openemr/service-worker.js \
    && test -f /etc/apache2/conf.d/zz-openemr-security.conf \
    && chmod 755 /usr/local/bin/railway-entrypoint.sh \
    && chmod 755 /opt/openemr-ops/production-readiness.sh /opt/openemr-ops/backup/*.sh \
    && chmod 444 /var/www/localhost/htdocs/openemr/acknowledge_license_cert.html \
                 /var/www/localhost/htdocs/openemr/templates/login/base.html.twig \
                 /var/www/localhost/htdocs/openemr/templates/login/layouts/vertical_band.html.twig \
                 /var/www/localhost/htdocs/openemr/manifest.webmanifest \
                 /var/www/localhost/htdocs/openemr/service-worker.js \
                 /var/www/localhost/htdocs/openemr/assets/clinic/clinic-icon.svg \
                 /etc/apache2/conf.d/zz-openemr-security.conf \
    && printf 'ok\n' > /var/www/localhost/htdocs/openemr/railway-health \
    && chown apache:apache /var/www/localhost/htdocs/openemr/railway-health \
    && chmod 444 /var/www/localhost/htdocs/openemr/railway-health

CMD ["/usr/local/bin/railway-entrypoint.sh"]
