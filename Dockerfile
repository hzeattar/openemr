# Railway deployment image for OpenEMR
# Uses the official stable production image instead of rebuilding the full source tree.
FROM openemr/openemr:8.2.0

# OpenEMR's Apache service listens on port 80 inside the container.
ENV PORT=80
EXPOSE 80

# Keep the official image entrypoint/CMD so automatic installation and upgrades work.
