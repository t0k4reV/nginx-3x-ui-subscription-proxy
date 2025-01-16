# nginx-3x-ui-subscription-proxy

A reverse proxy configuration for Nginx to dynamically handle and aggregate [3x-UI](https://github.com/MHSanaei/3x-ui?tab=readme-ov-file) subscriptions from multiple servers.

Конфигурация Nginx для объединения подписок с нескольких серверов [3x-UI](https://github.com/MHSanaei/3x-ui?tab=readme-ov-file).

## Overview
This project allows you to set up an Nginx-based reverse proxy that fetches and aggregates subscription configurations from multiple 3x-UI servers. It simplifies subscription management by unifying configurations in a single endpoint.

## Important Notes

1. Each client must have the same **subscription ID** across all your servers.
2. Subscription encryption must be enabled on all 3x-UI servers.


## Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/your-repo/nginx-3x-ui-subscription-proxy.git
cd nginx-3x-ui-subscription-proxy
```

### 2. Copy the Environment File
```bash
cp .env.template .env
```

### 3. Configure Environment Variables
Edit the `.env` file and fill in the following variables with your own data:

| Variable        | Description                                                                                     |
|-----------------|-------------------------------------------------------------------------------------------------|
| `TLS_MODE`  | Enables or disables SSL. Default set `off`. When set to `on`, SSL certificates must be generated (e.g., via Certbot), and their paths must be specified in the `PATH_SSL_KEY` variable. |
| `PATH_SSL_KEY`  | Path to the directory containing your SSL certificate and private key (e.g., `/etc/letsencrypt/live/your_site/`). |
| `SITE_HOST`     | Domain name for your Nginx server (e.g., `subserver.example`).                                           |
| `SITE_PORT`     | Port number where Nginx will listen for requests (e.g., `443`).                                |
| `SERVERS`       | List of 3x-UI server URLs to aggregate subscriptions from (e.g., `https://server1.com/sub/ https://server2.com/sub/`). |
| `SUB`           | Static part of the subscription path (e.g., `sub`).                                             |

#### Subscription URL Format

Once you've configured the environment variables, your subscription URL will look like this:
`https://subserver.example/sub/subscription_ID
`

Where:
- `subserver.example` is the domain you set in the `SITE_HOST` variable.
- `sub` is the static part of the subscription path, set in the `SUB` variable.
- `subscription_ID` is the unique ID for for each client from 3x-ui.

### 4. Start the Application
Run the following command to start the application:
```bash
docker compose up -d
```

This will build and start the Nginx container with the provided configuration.

## How It Works
- The proxy dynamically fetches subscription configurations from the servers listed in `SERVERS`.
- It listens on the domain and port specified in `SITE_HOST` and `SITE_PORT`.
- SSL certificates are loaded from the path specified in `PATH_SSL_KEY`.

## Example Configuration
Here is an example `.env` file:
```dotenv
PATH_SSL_KEY=/etc/letsencrypt/live/example.com/
SITE_HOST=example.com
SITE_PORT=443
SERVERS="https://server1.com/sub/ https://server2.com/sub/"
SUB=sub
```

## License
This project is licensed under the MIT License. See the `LICENSE` file for details.

