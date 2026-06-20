import crypto from "node:crypto";
import {URL, URLSearchParams} from "node:url";
import * as admin from "firebase-admin";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";

admin.initializeApp();

const db = admin.firestore();
const conventionID = "trekli-2026";

const squareAppID = defineSecret("SQUARE_APP_ID");
const squareAppSecret = defineSecret("SQUARE_APP_SECRET");
const squareWebhookSignatureKey = defineSecret("SQUARE_WEBHOOK_SIGNATURE_KEY");

type SquareEnvironment = "sandbox" | "production";

type SquareTokenResponse = {
  access_token: string;
  refresh_token?: string;
  expires_at?: string;
  merchant_id?: string;
  short_lived?: boolean;
};

type SquareErrorResponse = {
  errors?: Array<{
    code?: string;
    detail?: string;
    category?: string;
  }>;
};

type CRMCustomerSyncBody = {
  conventionID?: string;
  contact?: {
    contactID: string;
    fullName: string;
    organization?: string;
    roleTitle?: string;
    kind?: string;
    email?: string;
    phone?: string;
    squareCustomerID?: string | null;
    tags?: string[];
    notes?: string;
  };
};

type TicketOrderSyncBody = {
  conventionID?: string;
  daysBack?: number;
};

type PublishedNotification = {
  title?: unknown;
  message?: unknown;
  body?: unknown;
  role?: unknown;
  category?: unknown;
  track?: unknown;
  isPriority?: unknown;
  showAsBanner?: unknown;
  priority?: unknown;
  timestamp?: unknown;
  pushDisabled?: unknown;
};

type SquarePayment = {
  id: string;
  status?: string;
  order_id?: string;
  receipt_number?: string;
  updated_at?: string;
  buyer_email_address?: string;
};

type SquareOrderLineItem = {
  name?: string;
  quantity?: string;
  catalog_object_id?: string;
};

type SquareOrder = {
  id: string;
  reference_id?: string;
  state?: string;
  created_at?: string;
  updated_at?: string;
  customer_id?: string;
  line_items?: SquareOrderLineItem[];
  fulfillments?: Array<{
    pickup_details?: {
      recipient?: {
        display_name?: string;
      };
    };
    shipment_details?: {
      recipient?: {
        display_name?: string;
      };
    };
  }>;
};

function getSquareBaseURL(environment: SquareEnvironment): string {
  return environment === "sandbox"
    ? "https://connect.squareupsandbox.com"
    : "https://connect.squareup.com";
}

function integrationDoc(convention = conventionID) {
  return db.collection("conventions").doc(convention).collection("integrations").doc("square");
}

function canonicalEnvironment(value: unknown): SquareEnvironment {
  return value === "sandbox" ? "sandbox" : "production";
}

async function getIntegrationConfig(convention = conventionID) {
  const snapshot = await integrationDoc(convention).get();
  const data = snapshot.data() ?? {};
  const environment = canonicalEnvironment(data.environment);

  return {
    environment,
    appID: squareAppID.value(),
    appSecret: squareAppSecret.value(),
    webhookSignatureKey: squareWebhookSignatureKey.value(),
    redirectURI: (data.redirectURI as string | undefined)?.trim() ?? "",
    backendBaseURL: (data.backendBaseURL as string | undefined)?.trim() ?? "",
    cmsSyncEnabled: Boolean(data.cmsSyncEnabled),
    ticketSyncEnabled: data.ticketSyncEnabled === undefined ? Boolean(data.cmsSyncEnabled) : Boolean(data.ticketSyncEnabled),
    allowedScopes: Array.isArray(data.allowedScopes) ? data.allowedScopes.filter((item): item is string => typeof item === "string") : [],
    locationIDs: Array.isArray(data.locationIDs) ? data.locationIDs.filter((item): item is string => typeof item === "string") : [],
    ticketItemKeywords: Array.isArray(data.ticketItemKeywords) ? data.ticketItemKeywords.filter((item): item is string => typeof item === "string") : [],
    ticketCatalogObjectIDs: Array.isArray(data.ticketCatalogObjectIDs) ? data.ticketCatalogObjectIDs.filter((item): item is string => typeof item === "string") : [],
    merchantID: (data.merchantID as string | undefined)?.trim() ?? "",
    tokenAccessToken: (data.accessToken as string | undefined)?.trim() ?? "",
    tokenRefreshToken: (data.refreshToken as string | undefined)?.trim() ?? "",
    expiresAt: (data.expiresAt as string | undefined)?.trim() ?? ""
  };
}

async function writeIntegrationState(
  patch: Record<string, unknown>,
  convention = conventionID
) {
  await integrationDoc(convention).set(
    {
      ...patch,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {merge: true}
  );
}

async function fetchSquareJSON<T>(
  environment: SquareEnvironment,
  path: string,
  init: RequestInit,
  accessToken?: string
): Promise<T> {
  const url = new URL(path, getSquareBaseURL(environment));
  const headers = new Headers(init.headers ?? {});
  headers.set("Content-Type", "application/json");
  headers.set("Accept", "application/json");
  headers.set("Square-Version", "2026-01-21");
  if (accessToken) {
    headers.set("Authorization", `Bearer ${accessToken}`);
  }

  const response = await fetch(url, {...init, headers});
  const text = await response.text();
  const json = text ? (JSON.parse(text) as T | SquareErrorResponse) : ({} as T);

  if (!response.ok) {
    const errorPayload = json as SquareErrorResponse;
    const detail = errorPayload.errors?.[0]?.detail ?? errorPayload.errors?.[0]?.code ?? "Unknown Square error";
    throw new Error(detail);
  }

  return json as T;
}

async function refreshAccessTokenIfNeeded(convention = conventionID) {
  const config = await getIntegrationConfig(convention);
  if (!config.tokenRefreshToken) {
    return config;
  }

  if (config.expiresAt) {
    const expiresAt = Date.parse(config.expiresAt);
    const refreshThreshold = Date.now() + 5 * 60 * 1000;
    if (!Number.isNaN(expiresAt) && expiresAt > refreshThreshold) {
      return config;
    }
  }

  const tokenResponse = await fetchSquareJSON<SquareTokenResponse>(
    config.environment,
    "/oauth2/token",
    {
      method: "POST",
      body: JSON.stringify({
        client_id: config.appID,
        client_secret: config.appSecret,
        grant_type: "refresh_token",
        refresh_token: config.tokenRefreshToken
      })
    }
  );

  await writeIntegrationState(
    {
      accessToken: tokenResponse.access_token,
      refreshToken: tokenResponse.refresh_token ?? config.tokenRefreshToken,
      expiresAt: tokenResponse.expires_at ?? "",
      status: "connected",
      lastErrorMessage: ""
    },
    convention
  );

  return {
    ...config,
    tokenAccessToken: tokenResponse.access_token,
    tokenRefreshToken: tokenResponse.refresh_token ?? config.tokenRefreshToken,
    expiresAt: tokenResponse.expires_at ?? ""
  };
}

function splitName(fullName: string) {
  const parts = fullName.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) {
    return {givenName: undefined, familyName: undefined};
  }
  if (parts.length === 1) {
    return {givenName: parts[0], familyName: undefined};
  }
  return {
    givenName: parts[0],
    familyName: parts.slice(1).join(" ")
  };
}

function normalizeText(value: string | undefined | null): string {
  return (value ?? "").trim();
}

function normalizeUnknownText(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function parseBoolean(value: unknown): boolean {
  if (typeof value === "boolean") {
    return value;
  }
  if (typeof value === "string") {
    const normalized = value.trim().toLowerCase();
    return normalized === "true" || normalized === "yes" || normalized === "1";
  }
  if (typeof value === "number") {
    return value === 1;
  }
  return false;
}

function parsePriority(value: PublishedNotification): boolean {
  if (parseBoolean(value.isPriority) || parseBoolean(value.showAsBanner)) {
    return true;
  }

  const priority = normalizeUnknownText(value.priority).toLowerCase();
  return priority === "high" || priority === "critical" || priority === "priority";
}

function topicForNotificationRole(role: string): string {
  switch (role.trim().toLowerCase()) {
  case "guest":
    return "trekli_2026_guest";
  case "qvip":
  case "vip":
  case "premium":
    return "trekli_2026_qvip";
  case "staff":
    return "trekli_2026_staff";
  case "ops":
  case "operations":
    return "trekli_2026_ops";
  case "vendor":
  case "vendors":
    return "trekli_2026_vendor";
  case "all":
  case "public":
  default:
    return "trekli_2026";
  }
}

function timestampDate(value: unknown): Date | null {
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate();
  }
  if (value instanceof Date) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Date.parse(value);
    return Number.isNaN(parsed) ? null : new Date(parsed);
  }
  return null;
}

function parseQuantity(value: string | undefined): number {
  const parsed = Number.parseFloat(value ?? "0");
  if (Number.isNaN(parsed) || parsed <= 0) {
    return 0;
  }
  return Math.max(0, Math.round(parsed));
}

function deterministicUUID(seed: string): string {
  const hash = crypto.createHash("sha1").update(seed).digest();
  const bytes = Buffer.from(hash.subarray(0, 16));
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.toString("hex");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20, 32)}`;
}

function matchesTicketLineItem(
  item: SquareOrderLineItem,
  config: Awaited<ReturnType<typeof getIntegrationConfig>>
): boolean {
  const name = normalizeText(item.name).toLowerCase();
  const catalogID = normalizeText(item.catalog_object_id);

  if (config.ticketCatalogObjectIDs.includes(catalogID)) {
    return true;
  }

  if (config.ticketItemKeywords.length === 0) {
    return name.includes("ticket") || name.includes("badge") || name.includes("pass") || name.includes("admission");
  }

  return config.ticketItemKeywords.some((keyword) => name.includes(keyword.toLowerCase()));
}

function resolveTicketCount(
  order: SquareOrder,
  config: Awaited<ReturnType<typeof getIntegrationConfig>>
): number {
  return (order.line_items ?? [])
    .filter((item) => matchesTicketLineItem(item, config))
    .reduce((sum, item) => sum + parseQuantity(item.quantity), 0);
}

function resolveTicketHolderName(order: SquareOrder, payment?: SquarePayment): string {
  const pickupRecipient = order.fulfillments?.[0]?.pickup_details?.recipient?.display_name;
  const shipmentRecipient = order.fulfillments?.[0]?.shipment_details?.recipient?.display_name;

  return normalizeText(pickupRecipient)
    || normalizeText(shipmentRecipient)
    || normalizeText(payment?.buyer_email_address)
    || `Square Order ${order.id.slice(0, 8).toUpperCase()}`;
}

function resolveOrderNumber(order: SquareOrder, payment?: SquarePayment): string {
  return (
    normalizeText(order.reference_id)
    || normalizeText(payment?.receipt_number)
    || order.id
  ).toUpperCase();
}

async function retrieveSquareOrder(
  orderID: string,
  config: Awaited<ReturnType<typeof refreshAccessTokenIfNeeded>>
): Promise<SquareOrder> {
  const response = await fetchSquareJSON<{order?: SquareOrder}>(
    config.environment,
    `/v2/orders/${encodeURIComponent(orderID)}`,
    {method: "GET"},
    config.tokenAccessToken
  );

  if (!response.order) {
    throw new Error(`Square order ${orderID} was not returned.`);
  }

  return response.order;
}

async function upsertTicketOrderFromSquare(
  convention: string,
  order: SquareOrder,
  config: Awaited<ReturnType<typeof refreshAccessTokenIfNeeded>>,
  payment?: SquarePayment
) {
  if (!config.ticketSyncEnabled) {
    return null;
  }

  const ticketCount = resolveTicketCount(order, config);
  if (ticketCount <= 0) {
    return null;
  }

  const docID = `square_${order.id}`;
  const docRef = db.collection("conventions").doc(convention).collection("ticket_orders").doc(docID);
  const existingSnapshot = await docRef.get();
  const existingData = existingSnapshot.data() ?? {};
  const existingScannedCount = typeof existingData.scannedCount === "number" ? existingData.scannedCount : 0;
  const createdAt = order.created_at ? new Date(order.created_at) : new Date();
  const updatedAt = order.updated_at ? new Date(order.updated_at) : new Date();

  const payload = {
    id: typeof existingData.id === "string" ? existingData.id : deterministicUUID(`square-order:${order.id}`),
    name: resolveTicketHolderName(order, payment),
    ticketCount,
    orderNumber: resolveOrderNumber(order, payment),
    scannedCount: Math.min(existingScannedCount, ticketCount),
    issuer: "Trek Long Island Corp.",
    createdAt: admin.firestore.Timestamp.fromDate(createdAt),
    updatedAt: admin.firestore.Timestamp.fromDate(updatedAt),
    lastScannedAt: existingData.lastScannedAt ?? null,
    source: "square",
    externalOrderID: order.id,
    externalPaymentID: payment?.id ?? existingData.externalPaymentID ?? null,
    orderState: order.state ?? existingData.orderState ?? "COMPLETED",
    lastSquareSyncAt: admin.firestore.FieldValue.serverTimestamp()
  };

  await docRef.set(payload, {merge: true});
  return payload;
}

async function upsertSquareCustomer(convention: string, body: CRMCustomerSyncBody) {
  const config = await refreshAccessTokenIfNeeded(convention);

  if (!config.cmsSyncEnabled) {
    throw new Error("Square CMS sync is disabled.");
  }
  if (!config.tokenAccessToken) {
    throw new Error("Square merchant is not authorized.");
  }
  if (!body.contact) {
    throw new Error("CRM contact payload is required.");
  }

  const contact = body.contact;
  const names = splitName(contact.fullName);
  const referenceID = `tli.crm.${contact.contactID}`;
  const payload = {
    given_name: names.givenName,
    family_name: names.familyName,
    company_name: contact.organization?.trim() || undefined,
    email_address: contact.email?.trim() || undefined,
    phone_number: contact.phone?.trim() || undefined,
    note: contact.notes?.trim() || undefined,
    reference_id: referenceID,
    idempotency_key: crypto.randomUUID()
  };

  let customerID = contact.squareCustomerID?.trim() || "";
  let action = "updated";

  if (!customerID) {
    const searchResponse = await fetchSquareJSON<{customers?: Array<{id: string}>}>(
      config.environment,
      "/v2/customers/search",
      {
        method: "POST",
        body: JSON.stringify({
          limit: 1,
          query: {
            filter: {
              reference_id: {exact: referenceID}
            }
          }
        })
      },
      config.tokenAccessToken
    );
    customerID = searchResponse.customers?.[0]?.id ?? "";
  }

  if (customerID) {
    await fetchSquareJSON(
      config.environment,
      `/v2/customers/${encodeURIComponent(customerID)}`,
      {
        method: "PUT",
        body: JSON.stringify(payload)
      },
      config.tokenAccessToken
    );
  } else {
    const createResponse = await fetchSquareJSON<{customer?: {id: string}}>(
      config.environment,
      "/v2/customers",
      {
        method: "POST",
        body: JSON.stringify(payload)
      },
      config.tokenAccessToken
    );
    customerID = createResponse.customer?.id ?? "";
    action = "created";
  }

  if (!customerID) {
    throw new Error("Square did not return a customer ID.");
  }

  await db.collection("conventions")
    .doc(convention)
    .collection("square_sync")
    .doc(`crm_${contact.contactID}`)
    .set(
      {
        kind: "crm_customer",
        contactID: contact.contactID,
        squareCustomerID: customerID,
        action,
        syncedAt: admin.firestore.FieldValue.serverTimestamp()
      },
      {merge: true}
    );

  return {customerID, action, source: "firebase-functions"};
}

async function syncSquareOrderToTicketRecord(
  convention: string,
  orderID: string,
  payment?: SquarePayment
) {
  const config = await refreshAccessTokenIfNeeded(convention);
  if (!config.cmsSyncEnabled) {
    throw new Error("Square CMS sync is disabled.");
  }
  if (!config.tokenAccessToken) {
    throw new Error("Square merchant is not authorized.");
  }

  const order = await retrieveSquareOrder(orderID, config);
  return upsertTicketOrderFromSquare(convention, order, config, payment);
}

async function backfillSquareTicketOrders(convention: string, body: TicketOrderSyncBody) {
  const config = await refreshAccessTokenIfNeeded(convention);
  if (!config.cmsSyncEnabled) {
    throw new Error("Square CMS sync is disabled.");
  }
  if (!config.ticketSyncEnabled) {
    throw new Error("Square ticket sync is disabled.");
  }
  if (!config.tokenAccessToken) {
    throw new Error("Square merchant is not authorized.");
  }
  if (config.locationIDs.length === 0) {
    throw new Error("No Square location IDs are configured for ticket sync.");
  }

  const daysBack = Math.max(1, Math.min(body.daysBack ?? 30, 90));
  const startAt = new Date(Date.now() - daysBack * 24 * 60 * 60 * 1000).toISOString();
  const syncedOrderIDs = new Set<string>();
  const syncedDocIDs: string[] = [];
  let cursor: string | undefined;

  do {
    const searchResponse = await fetchSquareJSON<{orders?: SquareOrder[]; cursor?: string}>(
      config.environment,
      "/v2/orders/search",
      {
        method: "POST",
        body: JSON.stringify({
          location_ids: config.locationIDs,
          cursor,
          limit: 100,
          query: {
            filter: {
              state_filter: {
                states: ["COMPLETED"]
              },
              date_time_filter: {
                updated_at: {
                  start_at: startAt
                }
              }
            }
          }
        })
      },
      config.tokenAccessToken
    );

    for (const order of searchResponse.orders ?? []) {
      if (syncedOrderIDs.has(order.id)) {
        continue;
      }
      syncedOrderIDs.add(order.id);
      const payload = await upsertTicketOrderFromSquare(convention, order, config);
      if (payload && typeof payload.externalOrderID === "string") {
        syncedDocIDs.push(`square_${payload.externalOrderID}`);
      }
    }

    cursor = searchResponse.cursor;
  } while (cursor);

  return {
    syncedCount: syncedDocIDs.length,
    syncedDocIDs,
    daysBack
  };
}

export const squareAuthorizeURL = onRequest(
  {cors: true, secrets: [squareAppID, squareAppSecret]},
  async (request, response) => {
    try {
      const convention = typeof request.query.conventionID === "string" ? request.query.conventionID : conventionID;
      const config = await getIntegrationConfig(convention);

      if (!config.redirectURI) {
        response.status(400).json({error: "Square redirect URI is not configured in Firestore."});
        return;
      }

      const state = crypto.randomUUID();
      await writeIntegrationState(
        {
          oauthState: state,
          status: "pending",
          lastErrorMessage: ""
        },
        convention
      );

      const scopes = config.allowedScopes.length > 0
        ? config.allowedScopes
        : ["CUSTOMERS_READ", "CUSTOMERS_WRITE", "ORDERS_READ", "PAYMENTS_READ", "ITEMS_READ", "MERCHANT_PROFILE_READ"];

      const url = new URL(`${getSquareBaseURL(config.environment)}/oauth2/authorize`);
      url.search = new URLSearchParams({
        client_id: config.appID,
        scope: scopes.join(" "),
        session: "false",
        state,
        redirect_uri: config.redirectURI
      }).toString();

      response.status(200).json({authorizeURL: url.toString(), state});
    } catch (error) {
      response.status(500).json({error: error instanceof Error ? error.message : "Unknown error"});
    }
  }
);

export const squareOAuthCallback = onRequest(
  {cors: true, secrets: [squareAppID, squareAppSecret]},
  async (request, response) => {
    const convention = typeof request.query.conventionID === "string" ? request.query.conventionID : conventionID;
    const code = typeof request.query.code === "string" ? request.query.code : "";
    const state = typeof request.query.state === "string" ? request.query.state : "";

    try {
      const config = await getIntegrationConfig(convention);
      const snapshot = await integrationDoc(convention).get();
      const expectedState = (snapshot.data()?.oauthState as string | undefined) ?? "";

      if (!code || !state || state !== expectedState) {
        await writeIntegrationState(
        {
            status: "error",
            lastErrorMessage: "Square OAuth callback state verification failed."
          },
          convention
        );
        response.status(400).send("Square authorization failed: invalid state.");
        return;
      }

      const tokenResponse = await fetchSquareJSON<SquareTokenResponse>(
        config.environment,
        "/oauth2/token",
        {
          method: "POST",
          body: JSON.stringify({
            client_id: config.appID,
            client_secret: config.appSecret,
            code,
            grant_type: "authorization_code",
            redirect_uri: config.redirectURI
          })
        }
      );

      const merchantResponse = await fetchSquareJSON<{merchant?: {id?: string; business_name?: string}}>(
        config.environment,
        "/v2/merchants/me",
        {method: "GET"},
        tokenResponse.access_token
      );

      await writeIntegrationState(
        {
          status: "connected",
          merchantID: tokenResponse.merchant_id ?? merchantResponse.merchant?.id ?? "",
          merchantName: merchantResponse.merchant?.business_name ?? "",
          accessToken: tokenResponse.access_token,
          refreshToken: tokenResponse.refresh_token ?? "",
          expiresAt: tokenResponse.expires_at ?? "",
          lastOAuthAt: admin.firestore.FieldValue.serverTimestamp(),
          lastErrorMessage: ""
        },
        convention
      );

      response.status(200).send("Square authorization complete. You can return to Trek Long Island Ops.");
    } catch (error) {
      await writeIntegrationState(
        {
          status: "error",
          lastErrorMessage: error instanceof Error ? error.message : "Unknown OAuth error"
        },
        convention
      );
      response.status(500).send("Square authorization failed.");
    }
  }
);

export const squareCRMCustomerSync = onRequest(
  {cors: true, secrets: [squareAppID, squareAppSecret]},
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({error: "Use POST."});
      return;
    }

    try {
      const body = request.body as CRMCustomerSyncBody;
      const convention = body.conventionID?.trim() || conventionID;
      const result = await upsertSquareCustomer(convention, body);
      response.status(200).json(result);
    } catch (error) {
      await writeIntegrationState(
        {
          status: "error",
          lastErrorMessage: error instanceof Error ? error.message : "Unknown CRM sync error"
        },
        conventionID
      );
      response.status(500).json({error: error instanceof Error ? error.message : "Unknown error"});
    }
  }
);

export const squareTicketOrderSync = onRequest(
  {cors: true, secrets: [squareAppID, squareAppSecret]},
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({error: "Use POST."});
      return;
    }

    try {
      const body = request.body as TicketOrderSyncBody;
      const convention = body.conventionID?.trim() || conventionID;
      const result = await backfillSquareTicketOrders(convention, body);
      response.status(200).json(result);
    } catch (error) {
      await writeIntegrationState(
        {
          status: "error",
          lastErrorMessage: error instanceof Error ? error.message : "Unknown ticket sync error"
        },
        conventionID
      );
      response.status(500).json({error: error instanceof Error ? error.message : "Unknown error"});
    }
  }
);

export const squareWebhook = onRequest(
  {cors: false, secrets: [squareWebhookSignatureKey]},
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).send("Use POST.");
      return;
    }

    const rawBody = request.rawBody ?? Buffer.from("");
    const signature = request.header("x-square-hmacsha256-signature") ?? "";
    const notificationURL = request.url;
    const expectedSignature = crypto
      .createHmac("sha256", squareWebhookSignatureKey.value())
      .update(notificationURL + rawBody.toString("utf8"))
      .digest("base64");

    if (!signature || signature !== expectedSignature) {
      response.status(401).send("Invalid Square webhook signature.");
      return;
    }

    const payload = request.body as Record<string, unknown>;
    const eventID = typeof payload.event_id === "string" ? payload.event_id : crypto.randomUUID();
    const eventType = typeof payload.type === "string" ? payload.type : "unknown";

    await db.collection("conventions")
      .doc(conventionID)
      .collection("square_webhooks")
      .doc(eventID)
      .set(
        {
          type: eventType,
          payload,
          receivedAt: admin.firestore.FieldValue.serverTimestamp()
        },
        {merge: true}
      );

    await writeIntegrationState(
      {
        lastWebhookAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "connected",
        lastErrorMessage: ""
      },
      conventionID
    );

    if (eventType === "payment.updated") {
      const payment = ((payload.data as {object?: {payment?: SquarePayment}} | undefined)?.object?.payment);
      if (payment?.status === "COMPLETED" && payment.order_id) {
        await syncSquareOrderToTicketRecord(conventionID, payment.order_id, payment);
      }
    }

    if (eventType === "order.updated") {
      const orderUpdated = ((payload.data as {object?: {order_updated?: {order_id?: string; state?: string}}} | undefined)?.object?.order_updated);
      if (orderUpdated?.order_id && orderUpdated.state === "COMPLETED") {
        await syncSquareOrderToTicketRecord(conventionID, orderUpdated.order_id);
      }
    }

    response.status(200).send("OK");
  }
);

export const sendPushForPublishedNotification = onDocumentCreated(
  "conventions/{conventionID}/notifications/{notificationID}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const data = snapshot.data() as PublishedNotification;
    if (parseBoolean(data.pushDisabled)) {
      await snapshot.ref.set(
        {
          pushStatus: "disabled",
          pushUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
        },
        {merge: true}
      );
      return;
    }

    const title = normalizeUnknownText(data.title);
    const body = normalizeUnknownText(data.message) || normalizeUnknownText(data.body);
    if (!title || !body) {
      await snapshot.ref.set(
        {
          pushStatus: "skipped_missing_content",
          pushUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
        },
        {merge: true}
      );
      return;
    }

    const scheduledAt = timestampDate(data.timestamp);
    if (scheduledAt && scheduledAt.getTime() > Date.now() + 5 * 60 * 1000) {
      await snapshot.ref.set(
        {
          pushStatus: "skipped_future_timestamp",
          pushUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
        },
        {merge: true}
      );
      return;
    }

    const role = normalizeUnknownText(data.role) || "all";
    const category = normalizeUnknownText(data.category) || normalizeUnknownText(data.track) || "General";
    const isPriority = parsePriority(data);
    const topic = topicForNotificationRole(role);
    const sentAt = new Date();

    const message: admin.messaging.Message = {
      topic,
      notification: {
        title,
        body: body.length > 180 ? `${body.slice(0, 177)}...` : body
      },
      data: {
        title,
        message: body,
        body,
        role,
        category,
        isPriority: isPriority ? "true" : "false",
        notificationID: snapshot.id,
        documentID: snapshot.id,
        conventionID: event.params.conventionID,
        timestamp: scheduledAt?.toISOString() ?? sentAt.toISOString()
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            "content-available": 1
          }
        }
      }
    };

    try {
      const messageID = await admin.messaging().send(message);
      await snapshot.ref.set(
        {
          pushStatus: "sent",
          pushTopic: topic,
          pushMessageID: messageID,
          pushSentAt: admin.firestore.FieldValue.serverTimestamp(),
          pushUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
        },
        {merge: true}
      );
    } catch (error) {
      await snapshot.ref.set(
        {
          pushStatus: "failed",
          pushErrorMessage: error instanceof Error ? error.message : "Unknown push error",
          pushUpdatedAt: admin.firestore.FieldValue.serverTimestamp()
        },
        {merge: true}
      );
      throw error;
    }
  }
);
