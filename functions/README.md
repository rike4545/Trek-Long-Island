# Trek Long Island Firebase Functions

This backend is the Square integration layer for the Trek Long Island app.

It is responsible for:

- generating Square OAuth authorization URLs
- handling the Square OAuth callback
- storing seller connection state in Firestore
- proxying CRM customer sync from the app to Square
- receiving Square webhooks and persisting raw events for downstream sync jobs

## Firestore document

The app listens to:

- `conventions/trekli-2026/integrations/square`

Suggested fields:

- `status`: `disconnected | pending | connected | error`
- `environment`: `sandbox | production`
- `redirectURI`: OAuth callback URL
- `backendBaseURL`: base URL used by the app, such as the Functions URL root
  You can store either the root Functions URL or the full `squareCRMCustomerSync` URL.
- `cmsSyncEnabled`: operator-controlled master toggle
- `ticketSyncEnabled`: whether Square orders should materialize into QR-ready ticket records
- `backendModeEnabled`: whether the app should use backend proxy mode
- `allowedScopes`: array of Square OAuth scopes
- `capabilities`: array such as `customers`, `orders`, `catalog`, `locations`
- `ticketItemKeywords`: optional array such as `["ticket", "badge", "vip pass"]`
- `ticketCatalogObjectIDs`: optional array of specific catalog object IDs that should count as tickets
- `merchantID`
- `merchantName`
- `locationIDs`
- `lastOAuthAt`
- `lastWebhookAt`
- `lastErrorMessage`

The function also writes to:

- `conventions/trekli-2026/square_sync/*`
- `conventions/trekli-2026/square_webhooks/*`

## Secrets

Set these Firebase Functions secrets before deploying:

- `SQUARE_APP_ID`
- `SQUARE_APP_SECRET`
- `SQUARE_WEBHOOK_SIGNATURE_KEY`

## Endpoints

- `squareAuthorizeURL`
- `squareOAuthCallback`
- `squareCRMCustomerSync`
- `squareTicketOrderSync`
- `squareWebhook`

## Notes

- The mobile app should not store production seller access tokens.
- Direct-to-Square access from the app is only intended as a debug fallback.
- Webhook consumers for orders, catalog, and locations should build on top of the raw event persistence added here.
- `squareWebhook` now attempts to normalize completed payment/order events into `ticket_orders` records for QR scanning.
