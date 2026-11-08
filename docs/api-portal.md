# Connecting the API Portal

Configure these values only in the API Portal server environment:

```dotenv
KONG_ADMIN_URL=https://admin.gateway.example.com
KONG_ADMIN_TOKEN=<the value from the gateway .env>
KONG_PROXY_INTERNAL_URL=https://gateway.example.com
KONG_PROXY_PUBLIC_URL=https://gateway.example.com
```

The Next.js browser bundle must not receive the Admin URL token. The portal
server's Kong adapter adds `Kong-Admin-Token` to its Admin API requests; Caddy
validates that header before forwarding them.

For the hosted live demo, set `PORTAL_API_DOMAIN` in the apigw mode-600 `.env`,
create the external `portal-edge` network, and deploy the API Portal server with
the `portal-server` alias on that network. Caddy terminates HTTPS and is the only
public path to Fastify; do not publish port 4000.

For a private-network production deployment, set `KONG_ADMIN_URL` to the
private Kong address and remove the public Admin DNS route.
