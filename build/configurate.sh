#!/bin/bash

# configurate.sh -----------------------------------------------------------------------------------
#
# Script Description:
#    This script manages the nginx configuration
#
# Required Arguments:
#
# Optional Arguments:
#    -d | --deployment : Copies the configuration for the deployment (Prompts a Down-Time message)
#    -h | --help       : Help message
#
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
# Initialize script
# --------------------------------------------------------------------------------------------------
#
# Turn on bash's exit on error (e)
set -e

source "/build/functions.sh"


# --------------------------------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------------------------------
#
log_info "Running: ${0##*/}"
log_env

# Check if execution stage is set
if [[ -z "${REVERSE_PROXY_EXECUTION_STAGE}" ]]; then
    log_error "Please specify REVERSE_PROXY_EXECUTION_STAGE variable"
    exit 1
fi

if [[ "${REVERSE_PROXY_EXECUTION_MODE}" != 'production' && "${REVERSE_PROXY_EXECUTION_MODE}" != 'maintenance' ]]; then
    log_error "Unkwown REVERSE_PROXY_EXECUTION_MODE variable: '${REVERSE_PROXY_EXECUTION_MODE}'"
    exit 1
fi

mkdir -p "${NGINX_DEFAULT_CONFIG_DIR}"
mkdir -p "${NGINX_CUSTOM_CONFIG_DIR}"

# Copy domains' common config files
find "${REVERSE_PROXY_CONFIG_DIR}/common" -type f | while read f; do
    if [[ -f "$f" ]]; then
        log_info "Coping '${f}/' to '${NGINX_CUSTOM_CONFIG_DIR}/'"
        cp "${f}" "${NGINX_CUSTOM_CONFIG_DIR}/"
    fi
done
# Copy domains' common HTML pages
cp -r "${REVERSE_PROXY_HTML_DIR}/common"/* "${NGINX_DEFAULT_HTML_DIR}/"

for domain in ${DOMAINS}; do
    echo "Configure Domain '${domain}' directories structure"
    mkdir -p "${NGINX_CUSTOM_CONFIG_DIR}/${domain}"
    # Configuration files
    find "${REVERSE_PROXY_CONFIG_DIR}/${domain}" -type f | while read f; do
        if [[ -f "$f" ]]; then
            # Configuration file with server blocks (this will be inluced by nginx)
            if echo "${f}" | grep -q "base.conf"; then
                destination="${NGINX_DEFAULT_CONFIG_DIR}/${domain}.conf"
            else
                destination="${NGINX_CUSTOM_CONFIG_DIR}/${domain}/`basename ${f}`"
            fi
            # Configuration file with the locations during 'production' mode
            if echo "${f}" | grep -q "main.conf"; then
                if [[ "${REVERSE_PROXY_EXECUTION_STAGE}" != 'production' ]]; then
                    continue
                fi
                destination="${NGINX_CUSTOM_CONFIG_DIR}/${domain}/locations.conf"
            fi
            # Configuration file with the locations during 'maintenance' mode
            if echo "${f}" | grep -q "down_time.conf"; then
                if [[ "${REVERSE_PROXY_EXECUTION_STAGE}" != 'maintenance' ]]; then
                    continue
                fi
                destination="${NGINX_CUSTOM_CONFIG_DIR}/${domain}/locations.conf"
            fi
            # Copy file
            if [[ $(echo "${f}" | grep -q "upstream_servers.conf") && "${REVERSE_PROXY_EXECUTION_STAGE}" == 'maintenance' ]]; then
                log_info "Generated an empty '${destination}'..."
                true > "${destination}"
            else
                log_info "Coping '${f}' to '${destination}'"
                cp "${f}" "${destination}"
            fi
        fi
    done
    # HTML default pages
    if [[ -d "${REVERSE_PROXY_HTML_DIR}/${domain}" ]]; then
        cp -r "${REVERSE_PROXY_HTML_DIR}/${domain}" "${NGINX_DEFAULT_HTML_DIR}/"
    fi
done

exit 0
