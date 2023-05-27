#!/bin/bash

# certificates.sh ----------------------------------------------------------------------------------
#
# Script Description:
#    This script manages the SSL certificates handled by nginx
#    The script executes the following steps:
#        1. Checks if certificates exist and if not then it creates dummy ones,
#           so the nginx can start (in any case)
#        2. Checks if certbot certificates exit and if not then generates new ones,
#           else renew them
#        3. Coping the certbot certificates to nginx ssl directory
#
# Required Arguments:
#
# Optional Arguments:
#    -h | --help  : Help message
#
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
# Initialize script
# --------------------------------------------------------------------------------------------------
#
source "/build/functions.sh"


# --------------------------------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------------------------------
#
log_info "Running: ${0##*/}"
log_env

# Check if execution mode is set
if [[ -z "${REVERSE_PROXY_EXECUTION_MODE}" ]]; then
    log_error "Please specify REVERSE_PROXY_EXECUTION_MODE variable"
    exit 1
fi

if [[ "${REVERSE_PROXY_EXECUTION_MODE}" != 'production' && "${REVERSE_PROXY_EXECUTION_MODE}" != 'development' ]]; then
    log_error "Unkwown REVERSE_PROXY_EXECUTION_MODE variable: '${REVERSE_PROXY_EXECUTION_MODE}'"
    exit 1
fi

# Split domains and emails to arrays
domains_to_list=($DOMAINS)
emails_to_list=($EMAILS)
# Iterate over the domains' array
for index in "${!domains_to_list[@]}"; do
    domain="${domains_to_list[$index]}"
    email="${emails_to_list[$index]}"

    # Generate the domain's certificates' directory
    mkdir -p "${SSL_CERTIFICATES_DIR}/${domain}"

    # ------------------------------
    # Self-Signed certificates
    # ------------------------------
    #
    # Generate dummy self-signed certificates, so the nginx can start
    if [[ ! -f "${SSL_CERTIFICATES_DIR}/${domain}/${SSL_CERTIFICATE_KEY}" ]]; then
        log_info "Creating dummy certificates for $domain ..."
        openssl req -x509 -nodes -newkey rsa:$RSA_KEY_SIZE -days 1             \
            -keyout "${SSL_CERTIFICATES_DIR}/${domain}/${SSL_CERTIFICATE_KEY}" \
            -out "${SSL_CERTIFICATES_DIR}/${domain}/${SSL_CERTIFICATE}"        \
            -subj '/CN=localhost'
    fi

    # ------------------------------
    # Diffie Hellman certificate
    # ------------------------------
    #
    # Generate a Diffie Hellman encryption certificate, so the nginx can start
    if [[ ! -f "${SSL_CERTIFICATES_DIR}/${domain}/${SSL_DHPARAM}" ]]; then
        log_info "Creating Diffie Hellman certificate for $domain ..."
        openssl dhparam -out "${SSL_CERTIFICATES_DIR}/${domain}/${SSL_DHPARAM}" ${DH_KEY_SIZE}
    fi

    if [[ "${REVERSE_PROXY_EXECUTION_MODE}" != 'production' ]]; then
        log_info "Running with Self-Signed certificates for $domain ..."
        continue
    fi

    # ------------------------------
    # Certbot certificates
    # ------------------------------
    #
    # Generate certbot certificates
    if [[ ! -f "${CERTBOT_DIR}/${domain}/${SSL_CERTIFICATE_KEY}" ]]; then
        log_info "Creating certbot certificates for $domain ..."
        certbot certonly --standalone                \
                        --preferred-challenges http \
                        --non-interactive           \
                        --agree-tos                 \
                        $(join_domains $domain)     \
                        $(email_arg $email)         \
                        $(staging $STAGING)
    else
        log_info "Renew certbot certificates for $domain ..."
        certbot renew
    fi

    # ------------------------------
    # Override certificates
    # ------------------------------
    #
    if [[ ! -f "${CERTBOT_DIR}/${domain}/${SSL_CERTIFICATE}" || ! -f "${CERTBOT_DIR}/${domain}/${SSL_CERTIFICATE_KEY}" ]]; then
        log_warn "Certbot certificates haven't been generated!"
        continue
    fi

    cp "${CERTBOT_DIR}/${domain}/${SSL_CERTIFICATE}" "${SSL_CERTIFICATES_DIR}/${domain}/${SSL_CERTIFICATE}"
    cp "${CERTBOT_DIR}/${domain}/${SSL_CERTIFICATE_KEY}" "${SSL_CERTIFICATES_DIR}/${domain}/${SSL_CERTIFICATE_KEY}"
done

#
# Handle certificates auto-renewal
#
# NOTE: certbot installs a system timer and a cronjob that auto-renews the certificates
#       If cron is installed on the system, then the cronjob handles the auto-renewal
#       but if the systemd or systemctl are install, then the system.timer handles it
# # Copy cron file to the cron.d directory
# echo "0 */12 * * * certbot renew > /proc/1/fd/1 2>/proc/1/fd/2" > /etc/cron.d/crontab
# chmod 0644 /etc/cron.d/crontab        # Give execution rights on the cron job
# /usr/bin/crontab /etc/cron.d/crontab  # Apply cron job
# Start cron
/usr/bin/crontab
