# Nginx Reverse-Proxy for multiple domains Dockerfile

## How it Works

- Latest `nginx` image is used in this `Dockerfile`

- Domain names are set as environmental variables. If an `IP` is used then certbot will fail to create certificates and `self-signed` ones will be used for `HTTPS`

- The execution mode is set as an environmental variable. If `production` mode is used then certbot certificates will be installed, else if, `development` mode is used then self-signed ones will be installed

- The cert-staging flag is set as an environmental variable. Set to 1 to test your setup to avoid hitting `Let's enrcypt`'s request limit

- `certbot` and `cron` are installed, to handle the certificates installation and their renewal

- The nginx configuration files are copied to the image

- The build scripts are copied to **docker-entrypoint.d** directory to be executed by nginx's entrypoint

- Change working directory to **/etc/nginx**

- The ports 80 and 443 are exposed

- To ensure the persistence of the database volumes are mounted

- The nginx configuration is split into multiple `.conf` files to be more clear:

```
base.conf contains the server blocks that listen to port 80 and 443
base.conf redirects requests from port 80 to 443
base.conf imports upstream_server.config
base.conf imports ssl.conf, with paths to certificates and base SSL parameters
base.conf imports common_headers.conf
common_headers.conf includes basic common headers
base.conf imports locations.conf
locations.conf contains the locations from main.conf
main.conf is renamed to locations.conf by configurate.sh script
main.conf imports common_proxy_headers.conf
common_proxy_headers.conf includes basic proxy headers
base.conf imports errors.conf
errors.conf redirects to error pages in case of an error
```

- During the container build the script `environment.sh` is executed first which uses `envsubst` to load environmental variables to nginx config files, like `REVERSE_PROXY_DOMAIN_1`

- The second script that is executed is named `configurate.sh` and manages the nginx configuration by coping all `.conf` files from
`REVERSE_PROXY_CONFIG_DIR` directory to nginx installation directory

- The last script, named `certificates.sh`, installs `self-signed` certificates and `Diffie Hellman key` in case there are non, to ensure that nginx will start properly (nginx fails to start if certs are missing). Then it tries to create certbot certificates and copy them to SSL directory of nginx. Also starts `cron` that handles the auto-renewal of them

## How to Configure

1. Select a `nginx` image version in case the latest does not meet the project's requirements

2. Change `REVERSE_PROXY_DOMAIN_XXX` environmental variables inside `Dockerfile` to project's domain-names or IP

3. Add `REVERSE_PROXY_DOMAIN_XXX` environmental variables inside `Dockerfile` for each domain name of the project

4. Add project's redirections inside **main.conf**

5. Add the upstream-server inside **upstream_servers.conf**

6. Set all environmental variables during `docker run` also (or in **docker-compose.xml** if it is used)

7. Modify default and error pages inside `default` directory to match project's needs

### NOTES:

- If an `IP` is used for `REVERSE_PROXY_DOMAIN_XXX` then certbot will fail to create certificates and `self-signed` ones will be used for `HTTPS`
