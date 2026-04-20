#!/usr/bin/env node

import {readFile} from "node:fs/promises";
import {resolve} from "node:path";
import process from "node:process";
import admin from "firebase-admin";

const projectRoot = resolve(process.cwd());
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

if (!serviceAccountPath) {
  console.error("Set GOOGLE_APPLICATION_CREDENTIALS to a Firebase service account JSON file before running this script.");
  process.exit(1);
}

const serviceAccount = JSON.parse(
  await readFile(resolve(serviceAccountPath), "utf8")
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const projectId = process.argv[2] ?? "trek-long-island";
const region = process.argv[3] ?? "us-central1";
const environment = process.argv[4] ?? "sandbox";
const conventionID = "trekli-2026";
const rootURL = `https://${region}-${projectId}.cloudfunctions.net`;

const payload = {
  status: "disconnected",
  environment,
  redirectURI: `${rootURL}/squareOAuthCallback?conventionID=${conventionID}`,
  backendBaseURL: rootURL,
  backendModeEnabled: true,
  cmsSyncEnabled: false,
  ticketSyncEnabled: true,
  allowedScopes: [
    "CUSTOMERS_READ",
    "CUSTOMERS_WRITE",
    "ORDERS_READ",
    "PAYMENTS_READ",
    "ITEMS_READ",
    "MERCHANT_PROFILE_READ"
  ],
  capabilities: [
    "customers",
    "orders",
    "catalog",
    "locations"
  ],
  ticketItemKeywords: [
    "ticket",
    "badge",
    "pass",
    "admission",
    "vip"
  ],
  ticketCatalogObjectIDs: [],
  merchantID: "",
  merchantName: "",
  locationIDs: [],
  lastErrorMessage: "",
  updatedAt: admin.firestore.FieldValue.serverTimestamp()
};

await db
  .collection("conventions")
  .doc(conventionID)
  .collection("integrations")
  .doc("square")
  .set(payload, {merge: true});

console.log(`Seeded conventions/${conventionID}/integrations/square for project ${projectId} (${environment}, ${region}).`);
console.log(JSON.stringify(payload, null, 2));
