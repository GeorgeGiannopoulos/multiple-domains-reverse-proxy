#!/bin/bash

# environment.sh -----------------------------------------------------------------------------------
#
# Script Description:
#    This script uses envsubst to load enviromental variables to nginx config files
#    NOTE: Must be executed before running the configurate.sh script that copies the files
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

#
# Rename the domains' config and html directories
#
# Loop through all environmental variables that start with REVERSE_PROXY_DOMAIN_
for var in $(env | grep -E "^REVERSE_PROXY_DOMAIN_[0-9]+=" | awk -F= '{print $1}'); do
    value=$(eval echo "\$$var")

    # Rename the directory using the value of the environmental variable
    if [[ -d "${REVERSE_PROXY_CONFIG_DIR}/${var}" ]]; then
        mv "${REVERSE_PROXY_CONFIG_DIR}/${var}" "${REVERSE_PROXY_CONFIG_DIR}/${value}"
    fi

    # Rename the directory using the value of the environmental variable
    if [[ -d "${REVERSE_PROXY_HTML_DIR}/${var}" ]]; then
        mv "${REVERSE_PROXY_HTML_DIR}/${var}" "${REVERSE_PROXY_HTML_DIR}/${value}"
    fi
done

#
# Replace environmental variables inside nginx config files
#
find ${REVERSE_PROXY_CONFIG_DIR} -type f | while read f; do
    if [[ -f "$f" ]]; then
        log_info "Update Enviromental Variables in '$f'..."
        envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < "$f" > temp$$; mv temp$$ "$f"
    fi
done

exit 0
