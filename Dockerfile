FROM nginx:latest

# TODO: Add here the project's domain
# Main Environmental Variables
ENV REVERSE_PROXY_EXECUTION_MODE='production' \
    REVERSE_PROXY_EXECUTION_STAGE='production' \
    REVERSE_PROXY_CONFIG_DIR='/config' \
    REVERSE_PROXY_HTML_DIR='/html'

# Projects' Environmental Variables
ENV REVERSE_PROXY_DOMAIN_1='project_1.domain.gr' \
    REVERSE_PROXY_DOMAIN_1_EMAIL='project_1_noreply@iti.gr' \
    REVERSE_PROXY_DOMAIN_1_FRONTEND=${REVERSE_PROXY_DOMAIN_1}:81 \
    REVERSE_PROXY_DOMAIN_1_BACKEND=${REVERSE_PROXY_DOMAIN_1}:8001 \
    REVERSE_PROXY_DOMAIN_2='project_2.domain.gr' \
    REVERSE_PROXY_DOMAIN_2_EMAIL='project_2_noreply@iti.gr' \
    REVERSE_PROXY_DOMAIN_2_FRONTEND=${REVERSE_PROXY_DOMAIN_2}:82 \
    REVERSE_PROXY_DOMAIN_2_BACKEND=${REVERSE_PROXY_DOMAIN_2}:8002

# Install dependencies:
# NOTE: Install either 'systemd-sysv' or 'cron' to auto-renew certificates
RUN apt-get update && \
    apt-get install -y --no-install-recommends cron certbot && \
    apt-get clean

# Copy configuration files, handler pages:
COPY config/ ${REVERSE_PROXY_CONFIG_DIR}/
COPY default/ ${REVERSE_PROXY_HTML_DIR}/

# Copy configuration scripts:
# NOTE: Append numbers as suffixes before each script's name to dictate the execution order.
#       Start from 99 and dicrease them, so the nginx default scripts to be executed first
COPY ./build/* /build/
RUN chmod 750 -R /build/ && \
    mv /build/environment.sh /docker-entrypoint.d/97-environment.sh && \
    mv /build/configurate.sh /docker-entrypoint.d/98-configurate.sh && \
    mv /build/certificates.sh /docker-entrypoint.d/99-certificates.sh

WORKDIR /etc/nginx

# Expose to the World:
EXPOSE 80 443

# Ensure Persistence of Data:
VOLUME ["/etc/ssl/live", "/etc/letsencrypt"]
