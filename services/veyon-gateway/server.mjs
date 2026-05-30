import http from "node:http";
import { readFileSync } from "node:fs";
import { URL } from "node:url";

const PORT = Number(process.env.GATEWAY_PORT || 8088);
const API_KEY = String(process.env.GATEWAY_API_KEY || "");
const UPSTREAM_BASE_URL = String(process.env.VEYON_WEBAPI_BASE_URL || "http://host.docker.internal:11080").replace(/\/+$/, "");
const REQUEST_TIMEOUT_MS = Number(process.env.GATEWAY_REQUEST_TIMEOUT_MS || 15000);
const CLEANUP_INTERVAL_MS = Number(process.env.GATEWAY_CLEANUP_INTERVAL_MS || 30000);
const REUSE_SKEW_MS = Number(process.env.GATEWAY_REUSE_SKEW_MS || 5000);

const DEFAULT_AUTH_METHOD = String(process.env.VEYON_DEFAULT_AUTH_METHOD || "auth_logon");

const ALLOW_INSECURE_TLS = ["1", "true", "yes"].includes(String(process.env.VEYON_WEBAPI_INSECURE_SKIP_TLS_VERIFY || "false").toLowerCase());
if (ALLOW_INSECURE_TLS) {
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
}

const AUTH_METHODS = {
  auth_keys: "0c69b301-81b4-42d6-8fae-128cdd113314",
  auth_ldap: "6f0a491e-c1c6-4338-8244-f823b0bf8670",
  auth_logon: "63611f7c-b457-42c7-832e-67d0f9281085",
  auth_simple: "73430b14-ef69-4c75-a145-ba635d1cc676"
};

const FEATURE_UIDS = {
  screen_lock: "ccb535a2-1d24-4cc1-a709-8b47d2b2ac79",
  input_devices_lock: "e4a77879-e544-4fec-bc18-e534f33b934c",
  user_logoff: "7311d43d-ab53-439e-a03a-8cb25f7ed526",
  reboot: "4f7d98f0-395a-4fff-b968-e49b8d0f748c",
  power_down: "6f5a27a0-0e2f-496e-afcc-7aae62eede10",
  text_message: "e75ae9c8-ac17-4d00-8f0d-019348346208",
  open_website: "8a11a75d-b3db-48b6-b9cb-f8422ddd5b0c",
  start_app: "da9ca56a-b2ad-4fff-8f8a-929b2927b442"
};

const connectionsByUid = new Map();
const connectionKeyToUid = new Map();

function defaultCredentialsFor(authMethod) {
  switch (authMethod) {
    case "auth_keys": {
      const keyname = process.env.VEYON_AUTH_KEYNAME;
      const keydata = readAuthKeyData();
      return keyname && keydata ? { keyname, keydata } : null;
    }
    case "auth_logon":
    case "auth_ldap": {
      const username = process.env.VEYON_AUTH_USERNAME;
      const password = process.env.VEYON_AUTH_PASSWORD;
      return username && password ? { username, password } : null;
    }
    case "auth_simple": {
      const password = process.env.VEYON_AUTH_SIMPLE_PASSWORD;
      return password ? { password } : null;
    }
    default:
      return null;
  }
}

function readAuthKeyData() {
  const keydataFile = process.env.VEYON_AUTH_KEYDATA_FILE;
  if (keydataFile) {
    try {
      return readFileSync(keydataFile, "utf8");
    } catch (error) {
      console.error(`Unable to read VEYON_AUTH_KEYDATA_FILE at ${keydataFile}: ${error.message}`);
      return null;
    }
  }

  return process.env.VEYON_AUTH_KEYDATA;
}

function connectionKey(host, authMethod, credentials) {
  return `${host}|${authMethod}|${JSON.stringify(credentials || {})}`;
}

function nowMs() {
  return Date.now();
}

function parseTimeMs(value) {
  const t = Date.parse(value || "");
  return Number.isNaN(t) ? 0 : t;
}

function isConnectionAlive(connection) {
  return connection && parseTimeMs(connection.validUntil) > nowMs() + REUSE_SKEW_MS;
}

function cleanupConnections() {
  for (const [uid, connection] of connectionsByUid.entries()) {
    if (!isConnectionAlive(connection)) {
      connectionsByUid.delete(uid);
      connectionKeyToUid.delete(connection.key);
    }
  }
}

setInterval(cleanupConnections, CLEANUP_INTERVAL_MS).unref();

function getHeader(req, name) {
  return req.headers[name.toLowerCase()];
}

function writeJson(res, status, data) {
  const payload = JSON.stringify(data);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(payload)
  });
  res.end(payload);
}

function writeError(res, status, code, message, extra = {}) {
  writeJson(res, status, {
    error: {
      code,
      message,
      ...extra
    }
  });
}

async function readJsonBody(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }
  if (!chunks.length) {
    return {};
  }

  const raw = Buffer.concat(chunks).toString("utf8");
  if (!raw.trim()) {
    return {};
  }

  try {
    return JSON.parse(raw);
  } catch (_error) {
    throw new Error("invalid_json");
  }
}

function buildUpstreamUrl(pathname, query = {}) {
  const url = new URL(pathname, `${UPSTREAM_BASE_URL}/`);
  for (const [key, value] of Object.entries(query)) {
    if (value === undefined || value === null || value === "") continue;
    url.searchParams.set(key, String(value));
  }
  return url;
}

async function upstreamRequest(method, pathname, { headers = {}, query = {}, jsonBody, binary = false, accept } = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  const requestHeaders = {
    Accept: accept || (binary ? "image/jpeg,image/png,*/*" : "application/json"),
    ...headers
  };

  let body;
  if (jsonBody !== undefined) {
    requestHeaders["Content-Type"] = "application/json";
    body = JSON.stringify(jsonBody);
  }

  try {
    const response = await fetch(buildUpstreamUrl(pathname, query), {
      method,
      headers: requestHeaders,
      body,
      signal: controller.signal
    });

    const contentType = response.headers.get("content-type") || "";

    if (binary) {
      const arrayBuffer = await response.arrayBuffer();
      const buffer = Buffer.from(arrayBuffer);
      const text = response.ok ? null : buffer.toString("utf8");
      let json = null;
      try {
        json = text ? JSON.parse(text) : null;
      } catch (_error) {
        json = null;
      }

      return {
        ok: response.ok,
        status: response.status,
        headers: response.headers,
        contentType,
        buffer,
        text,
        json
      };
    }

    const text = await response.text();
    let json = null;
    try {
      json = text ? JSON.parse(text) : null;
    } catch (_error) {
      json = null;
    }

    return {
      ok: response.ok,
      status: response.status,
      headers: response.headers,
      contentType,
      text,
      json
    };
  } finally {
    clearTimeout(timer);
  }
}

function normalizeUpstreamError(upstream, fallbackCode = "upstream_error", fallbackMessage = "Upstream request failed") {
  const upstreamError = upstream?.json?.error;
  const code = upstreamError?.code ?? fallbackCode;
  const message = upstreamError?.message || fallbackMessage;

  return {
    code: String(code),
    message,
    upstream_status: upstream?.status || 0
  };
}

function logUpstreamFailure(operation, upstream) {
  const body = upstream?.text ? upstream.text.replace(/\s+/g, " ").slice(0, 300) : "";
  console.error(
    `[veyon-gateway] ${operation} upstream failed: status=${upstream?.status || 0} content-type=${upstream?.contentType || ""}${body ? ` body=${body}` : ""}`
  );
}

async function authenticateHost(host, authMethod, credentials) {
  const methodUuid = AUTH_METHODS[authMethod];
  if (!methodUuid) {
    return { ok: false, status: 400, error: { code: "invalid_auth_method", message: `Unsupported auth_method: ${authMethod}` } };
  }

  const availableMethods = await upstreamRequest("GET", `/api/v1/authentication/${encodeURIComponent(host)}`);
  if (!availableMethods.ok) {
    return { ok: false, status: availableMethods.status || 502, error: normalizeUpstreamError(availableMethods, "methods_failed", "Failed to query authentication methods") };
  }

  const methods = Array.isArray(availableMethods.json?.methods) ? availableMethods.json.methods : [];
  if (!methods.includes(methodUuid)) {
    return {
      ok: false,
      status: 400,
      error: {
        code: "auth_method_not_available",
        message: `Authentication method ${authMethod} is not available for ${host}`
      }
    };
  }

  const authResponse = await upstreamRequest("POST", `/api/v1/authentication/${encodeURIComponent(host)}`, {
    jsonBody: {
      method: methodUuid,
      credentials
    }
  });

  if (!authResponse.ok) {
    return {
      ok: false,
      status: authResponse.status || 502,
      error: normalizeUpstreamError(authResponse, "authentication_failed", "Failed to authenticate host")
    };
  }

  const connectionUid = authResponse.json?.["connection-uid"];
  const validUntil = authResponse.json?.validUntil;
  if (!connectionUid || !validUntil) {
    return {
      ok: false,
      status: 502,
      error: {
        code: "invalid_upstream_payload",
        message: "Upstream authentication response is missing connection-uid or validUntil"
      }
    };
  }

  return {
    ok: true,
    connectionUid,
    validUntil
  };
}

function getValidConnectionByKey(key) {
  const uid = connectionKeyToUid.get(key);
  if (!uid) return null;

  const connection = connectionsByUid.get(uid);
  if (!isConnectionAlive(connection)) {
    if (connection) {
      connectionKeyToUid.delete(connection.key);
      connectionsByUid.delete(uid);
    }
    return null;
  }

  return connection;
}

function getValidConnectionByHost(host) {
  for (const connection of connectionsByUid.values()) {
    if (connection.host === host && isConnectionAlive(connection)) {
      return connection;
    }
  }
  return null;
}

async function openOrReuseConnection({ host, authMethod, credentials }) {
  const key = connectionKey(host, authMethod, credentials);
  const existing = getValidConnectionByKey(key);
  if (existing) {
    return {
      ok: true,
      reused: true,
      connection: existing
    };
  }

  const authResult = await authenticateHost(host, authMethod, credentials);
  if (!authResult.ok) {
    return authResult;
  }

  const connection = {
    uid: authResult.connectionUid,
    host,
    authMethod,
    credentials,
    key,
    validUntil: authResult.validUntil,
    createdAt: new Date().toISOString()
  };

  connectionsByUid.set(connection.uid, connection);
  connectionKeyToUid.set(key, connection.uid);

  return {
    ok: true,
    reused: false,
    connection
  };
}

async function ensureHostConnection(host) {
  const existing = getValidConnectionByHost(host);
  if (existing) {
    return { ok: true, connection: existing, opened: false };
  }

  const credentials = defaultCredentialsFor(DEFAULT_AUTH_METHOD);
  if (!credentials) {
    return {
      ok: false,
      status: 400,
      error: {
        code: "missing_default_credentials",
        message: `No default credentials configured for auth method ${DEFAULT_AUTH_METHOD}`
      }
    };
  }

  const result = await openOrReuseConnection({
    host,
    authMethod: DEFAULT_AUTH_METHOD,
    credentials
  });

  if (!result.ok) {
    return result;
  }

  return { ok: true, connection: result.connection, opened: true };
}

async function closeConnection(connection) {
  const upstream = await upstreamRequest("DELETE", `/api/v1/authentication/${encodeURIComponent(connection.host)}`, {
    headers: {
      "Connection-Uid": connection.uid
    }
  });

  connectionKeyToUid.delete(connection.key);
  connectionsByUid.delete(connection.uid);

  if (!upstream.ok && upstream.status !== 401) {
    return {
      ok: false,
      status: upstream.status || 502,
      error: normalizeUpstreamError(upstream, "close_failed", "Failed to close connection upstream")
    };
  }

  return { ok: true };
}

async function callWithConnection(host, handler) {
  let ensured = await ensureHostConnection(host);
  if (!ensured.ok) {
    return ensured;
  }

  let result = await handler(ensured.connection);
  if (result.ok) {
    return result;
  }

  const invalidConnection = result.status === 401 || result.error?.code === "2" || result.error?.code === "8";
  if (!invalidConnection) {
    return result;
  }

  // Remove stale local connection and retry once.
  connectionKeyToUid.delete(ensured.connection.key);
  connectionsByUid.delete(ensured.connection.uid);

  ensured = await ensureHostConnection(host);
  if (!ensured.ok) {
    return ensured;
  }

  return handler(ensured.connection);
}

function routeMatch(pathname, pattern) {
  const match = pathname.match(pattern);
  if (!match) return null;
  return match.slice(1).map((segment) => decodeURIComponent(segment));
}

function toIntegerOrUndefined(value) {
  if (value === null || value === undefined || value === "") return undefined;
  const n = Number(value);
  if (!Number.isInteger(n) || n <= 0) return undefined;
  return n;
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url || "/", "http://gateway.local");
  const { pathname, searchParams } = url;

  try {
    if (pathname !== "/v1/health") {
      const providedApiKey = String(getHeader(req, "x-api-key") || "");
      if (!API_KEY || providedApiKey !== API_KEY) {
        writeError(res, 401, "unauthorized", "Missing or invalid X-API-Key header");
        return;
      }
    }

    if (req.method === "GET" && pathname === "/v1/health") {
      writeJson(res, 200, {
        status: "ok",
        time: new Date().toISOString(),
        upstream_base_url: UPSTREAM_BASE_URL,
        connections_open: connectionsByUid.size,
        default_auth_method: DEFAULT_AUTH_METHOD
      });
      return;
    }

    if (req.method === "POST" && pathname === "/v1/connections/open") {
      const body = await readJsonBody(req);
      const host = String(body.host || "").trim();
      const authMethod = String(body.auth_method || DEFAULT_AUTH_METHOD).trim();
      const credentials = body.credentials && typeof body.credentials === "object" ? body.credentials : defaultCredentialsFor(authMethod);

      if (!host) {
        writeError(res, 400, "invalid_data", "host is required");
        return;
      }
      if (!AUTH_METHODS[authMethod]) {
        writeError(res, 400, "invalid_auth_method", `Unsupported auth_method: ${authMethod}`);
        return;
      }
      if (!credentials || typeof credentials !== "object") {
        writeError(res, 400, "invalid_credentials", `Missing credentials for auth_method: ${authMethod}`);
        return;
      }

      const result = await openOrReuseConnection({ host, authMethod, credentials });
      if (!result.ok) {
        writeError(res, result.status || 502, result.error.code, result.error.message, { upstream_status: result.error.upstream_status });
        return;
      }

      writeJson(res, 200, {
        connection_uid: result.connection.uid,
        valid_until: result.connection.validUntil,
        reused: result.reused
      });
      return;
    }

    const closeSegments = routeMatch(pathname, /^\/v1\/connections\/([^/]+)$/);
    if (req.method === "DELETE" && closeSegments) {
      const [connectionUid] = closeSegments;
      const connection = connectionsByUid.get(connectionUid);
      if (!connection) {
        writeError(res, 404, "connection_not_found", "Connection UID not found");
        return;
      }

      const result = await closeConnection(connection);
      if (!result.ok) {
        writeError(res, result.status || 502, result.error.code, result.error.message, { upstream_status: result.error.upstream_status });
        return;
      }

      writeJson(res, 200, { success: true });
      return;
    }

    const framebufferSegments = routeMatch(pathname, /^\/v1\/hosts\/([^/]+)\/framebuffer$/);
    if (req.method === "GET" && framebufferSegments) {
      const [host] = framebufferSegments;

      const format = String(searchParams.get("format") || "jpeg").toLowerCase();
      const width = toIntegerOrUndefined(searchParams.get("width"));
      const height = toIntegerOrUndefined(searchParams.get("height"));
      const quality = toIntegerOrUndefined(searchParams.get("quality"));

      const result = await callWithConnection(host, async (connection) => {
        const upstream = await upstreamRequest("GET", "/api/v1/framebuffer", {
          headers: { "Connection-Uid": connection.uid },
          query: {
            format,
            width,
            height,
            quality
          },
          binary: true,
          accept: format === "png" ? "image/png,*/*" : "image/jpeg,*/*"
        });

        if (!upstream.ok) {
          logUpstreamFailure("framebuffer", upstream);
          return {
            ok: false,
            status: upstream.status || 502,
            error: normalizeUpstreamError(upstream, "framebuffer_failed", "Failed to fetch framebuffer")
          };
        }

        return {
          ok: true,
          buffer: upstream.buffer,
          contentType: upstream.contentType || (format === "png" ? "image/png" : "image/jpeg")
        };
      });

      if (!result.ok) {
        writeError(res, result.status || 503, result.error.code, result.error.message, { upstream_status: result.error.upstream_status });
        return;
      }

      res.writeHead(200, {
        "Content-Type": result.contentType,
        "Content-Length": result.buffer.length,
        "Cache-Control": "no-store"
      });
      res.end(result.buffer);
      return;
    }

    const featureSegments = routeMatch(pathname, /^\/v1\/hosts\/([^/]+)\/features\/([^/]+)$/);
    if (req.method === "POST" && featureSegments) {
      const [host, featureKey] = featureSegments;
      const featureUid = FEATURE_UIDS[featureKey];
      if (!featureUid) {
        writeError(res, 400, "invalid_feature", `Unsupported feature key: ${featureKey}`);
        return;
      }

      const body = await readJsonBody(req);
      const active = body.active !== undefined ? Boolean(body.active) : true;
      const args = body.arguments;

      const result = await callWithConnection(host, async (connection) => {
        const upstream = await upstreamRequest("PUT", `/api/v1/feature/${featureUid}`, {
          headers: { "Connection-Uid": connection.uid },
          jsonBody: {
            active,
            arguments: args
          }
        });

        if (!upstream.ok) {
          return {
            ok: false,
            status: upstream.status || 502,
            error: normalizeUpstreamError(upstream, "feature_failed", "Failed to execute feature")
          };
        }

        return { ok: true, upstreamStatus: upstream.status };
      });

      if (!result.ok) {
        writeError(res, result.status || 502, result.error.code, result.error.message, { upstream_status: result.error.upstream_status });
        return;
      }

      writeJson(res, 200, {
        success: true,
        upstream_code: 0,
        upstream_message: "OK"
      });
      return;
    }

    const userSegments = routeMatch(pathname, /^\/v1\/hosts\/([^/]+)\/user$/);
    if (req.method === "GET" && userSegments) {
      const [host] = userSegments;
      const result = await callWithConnection(host, async (connection) => {
        const upstream = await upstreamRequest("GET", "/api/v1/user", {
          headers: { "Connection-Uid": connection.uid }
        });

        if (!upstream.ok) {
          return {
            ok: false,
            status: upstream.status || 502,
            error: normalizeUpstreamError(upstream, "user_info_failed", "Failed to query user info")
          };
        }

        const payload = upstream.json || {};
        return {
          ok: true,
          data: {
            login: payload.login || "",
            full_name: payload.fullName || ""
          }
        };
      });

      if (!result.ok) {
        writeError(res, result.status || 502, result.error.code, result.error.message, { upstream_status: result.error.upstream_status });
        return;
      }

      writeJson(res, 200, result.data);
      return;
    }

    const sessionSegments = routeMatch(pathname, /^\/v1\/hosts\/([^/]+)\/session$/);
    if (req.method === "GET" && sessionSegments) {
      const [host] = sessionSegments;
      const result = await callWithConnection(host, async (connection) => {
        const upstream = await upstreamRequest("GET", "/api/v1/session", {
          headers: { "Connection-Uid": connection.uid }
        });

        if (!upstream.ok) {
          return {
            ok: false,
            status: upstream.status || 502,
            error: normalizeUpstreamError(upstream, "session_info_failed", "Failed to query session info")
          };
        }

        const payload = upstream.json || {};
        return {
          ok: true,
          data: {
            session_id: payload.sessionId,
            session_uptime_seconds: payload.sessionUptime,
            session_client_address: payload.sessionClientAddress,
            session_client_name: payload.sessionClientName,
            session_host_name: payload.sessionHostName
          }
        };
      });

      if (!result.ok) {
        writeError(res, result.status || 502, result.error.code, result.error.message, { upstream_status: result.error.upstream_status });
        return;
      }

      writeJson(res, 200, result.data);
      return;
    }

    writeError(res, 404, "not_found", "Endpoint not found");
  } catch (error) {
    if (error && error.message === "invalid_json") {
      writeError(res, 400, "invalid_json", "Request body is not valid JSON");
      return;
    }

    if (error && error.name === "AbortError") {
      writeError(res, 504, "timeout", "Request timed out while contacting upstream WebAPI");
      return;
    }

    writeError(res, 500, "internal_error", error?.message || "Internal server error");
  }
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`[veyon-gateway] listening on 0.0.0.0:${PORT}`);
  console.log(`[veyon-gateway] upstream base url: ${UPSTREAM_BASE_URL}`);
  console.log(`[veyon-gateway] default auth method: ${DEFAULT_AUTH_METHOD}`);
});
