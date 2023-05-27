#!/bin/bash

# functions.sh -------------------------------------------------------------------------------------
#
# Script Description:
#    This script contains functions used by all the scripts
#
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
# Environmental
# --------------------------------------------------------------------------------------------------
REVERSE_PROXY_EXECUTION_MODE="${REVERSE_PROXY_EXECUTION_MODE:-production}"  # Options: 'production', 'deployment'
REVERSE_PROXY_EXECUTION_STAGE="${REVERSE_PROXY_EXECUTION_STAGE:-production}"  # Options: 'production', 'maintenance'
# NOTE: Set to 1 if you're testing your setup to avoid hitting request limits
REVERSE_PROXY_CERT_STAGING="${REVERSE_PROXY_CERT_STAGING:-1}"  # Options: 0, 1


# --------------------------------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------------------------------
# Logging
VERBOSE=false
# Certificates Arguments
DOMAINS="$(env | grep -E "^REVERSE_PROXY_DOMAIN_[0-9]+=" | sort | cut -d'=' -f2 | paste -d ' ' -s)"
EMAILS="$(env | grep -E "^REVERSE_PROXY_DOMAIN_[0-9]+_EMAIL=" | sort | cut -d'=' -f2 | paste -d ' ' -s)" # NOTE: Adding a valid address is strongly recommended
RSA_KEY_SIZE=4096
DH_KEY_SIZE=2048
STAGING=${REVERSE_PROXY_CERT_STAGING}
# nginx Arguments
NGINX_DIR='/etc/nginx'
NGINX_DEFAULT_CONFIG_DIR="${NGINX_DIR}/conf.d"
NGINX_CUSTOM_CONFIG_DIR="${NGINX_DIR}/config"
NGINX_DEFAULT_HTML_DIR="/usr/share/nginx/html/"
CERTBOT_DIR="/etc/letsencrypt/live"
SSL_CERTIFICATES_DIR="/etc/ssl/live"
SSL_CERTIFICATE='fullchain.pem'
SSL_CERTIFICATE_KEY='privkey.pem'
SSL_DHPARAM='ssl-dhparams.pem'
SSL_CONFIG='ssl.conf'


# --------------------------------------------------------------------------------------------------
# Functions
# --------------------------------------------------------------------------------------------------
log() {
    printf '%s %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%S:%3NZ") $1 | $2"
    return
}

log_info() {
    log "INFO " "$1"
    return
}

log_warn() {
    log "WARNING" "$1"
    return
}

log_error() {
    log "ERROR" "$1"
    return
}

log_env() {
    # Log Environmental Variables
    log_info "Execution Mode    : '${REVERSE_PROXY_EXECUTION_MODE}'"
    log_info "Execution Stage   : '${REVERSE_PROXY_EXECUTION_STAGE}'"
    log_info "Cert Staging Mode : '${REVERSE_PROXY_CERT_STAGING}'"
    log_info "Domains           : '${DOMAINS}'"
}

join_domains() {
    domain=$1
    if [[ -z $domain ]]; then
        log_error "Domain is empty! Please provide one."
        exit 1
    fi
    domain_arg="-d $domain"
    echo "${domain_arg}"
}

email_arg() {
    # Select appropriate EMAIL arg
    email=$1
    case "$email" in
        "") email_arg="--register-unsafely-without-EMAIL" ;;
        *) email_arg="--email $email" ;;
    esac
    echo $email_arg
}

staging() {
    staging=$1
    # Enable STAGING mode if needed
    if [ $STAGING != "0" ]; then
        echo "--staging"
    fi
    echo ''
}

