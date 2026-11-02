// Supabase Edge Function: send-truck-alerts (Deno)
// Receives a truck location ping, calls `find_eligible_area_subscribers`,
// skips users already in `notifications_log` for that `dedup_key`, and sends
// push notifications via the FCM HTTP v1 API using a service-account key stored
// ONLY in Edge Function secrets (`FIREBASE_SERVICE_ACCOUNT_JSON`).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
}

interface EligibleSubscriber {
  user_id: string;
  area_id: string;
  dedup_key: string;
}

function base64UrlEncodeBytes(bytes: Uint8Array): string {
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function base64UrlEncodeString(input: string): string {
  return base64UrlEncodeBytes(new TextEncoder().encode(input));
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s+/g, '');
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer;
}

async function getFcmAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const tokenUri = sa.token_uri || 'https://oauth2.googleapis.com/token';

  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: tokenUri,
    iat: now,
    exp: now + 3600,
  };

  const signingInput = `${base64UrlEncodeString(JSON.stringify(header))}.${base64UrlEncodeString(JSON.stringify(payload))}`;
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signatureBuffer = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput),
  );
  const jwt = `${signingInput}.${base64UrlEncodeBytes(new Uint8Array(signatureBuffer))}`;

  const res = await fetch(tokenUri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`OAuth token exchange failed (${res.status}): ${errText}`);
  }

  const tokenData = await res.json();
  return tokenData.access_token as string;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers':
          'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceRoleKey =
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const serviceAccountRaw =
      Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON') ?? '';

    if (!supabaseUrl || !supabaseServiceRoleKey) {
      return new Response(
        JSON.stringify({ error: 'Missing Supabase environment variables.' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      );
    }

    if (!serviceAccountRaw) {
      return new Response(
        JSON.stringify({
          sent: 0,
          skipped: 0,
          message:
            'FIREBASE_SERVICE_ACCOUNT_JSON secret is not configured in Edge Function secrets.',
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      );
    }

    const body = await req.json();
    const record = body.record ?? body;
    const truckId = String(record.truck_id ?? '').trim();
    const latitude = Number(record.latitude);
    const longitude = Number(record.longitude);
    const recordedAt =
      record.recorded_at ?? new Date().toISOString();

    if (!truckId || Number.isNaN(latitude) || Number.isNaN(longitude)) {
      return new Response(
        JSON.stringify({
          error: 'Invalid payload: truck_id, latitude, and longitude are required.',
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // 1. Find eligible area subscribers via PostGIS RPC
    const { data: subscribers, error: rpcError } = await supabase.rpc(
      'find_eligible_area_subscribers',
      {
        p_truck_id: truckId,
        p_truck_lat: latitude,
        p_truck_lng: longitude,
        p_recorded_at: recordedAt,
      },
    );

    if (rpcError) {
      return new Response(
        JSON.stringify({ error: rpcError.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      );
    }

    const eligibleList = (subscribers ?? []) as EligibleSubscriber[];
    if (eligibleList.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, skipped: 0 }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      );
    }

    // 2. Explicitly verify notifications_log and skip users already logged for that dedup_key
    const dedupKeys = eligibleList.map((s) => s.dedup_key);
    const { data: existingLogs } = await supabase
      .from('notifications_log')
      .select('dedup_key')
      .in('dedup_key', dedupKeys);

    const existingDedupSet = new Set(
      (existingLogs ?? []).map((r: { dedup_key: string }) => r.dedup_key),
    );

    const pendingSubscribers = eligibleList.filter(
      (s) => !existingDedupSet.has(s.dedup_key),
    );

    if (pendingSubscribers.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, skipped: eligibleList.length }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      );
    }

    // 3. Load truck details and recipient FCM tokens
    const { data: truckRow } = await supabase
      .from('trucks')
      .select('id, name, cuisine, address')
      .eq('id', truckId)
      .maybeSingle();

    const truckName = truckRow?.name ?? 'A RoamBite food truck';
    const truckAddress = truckRow?.address ? ` near ${truckRow.address}` : '';

    const userIds = [...new Set(pendingSubscribers.map((s) => s.user_id))];
    const { data: profileRows } = await supabase
      .from('profiles')
      .select('id, fcm_token')
      .in('id', userIds);

    const tokenByUser = new Map<string, string>();
    for (const row of profileRows ?? []) {
      if (row.fcm_token && String(row.fcm_token).trim().length > 0) {
        tokenByUser.set(row.id, String(row.fcm_token).trim());
      }
    }

    const serviceAccount = JSON.parse(serviceAccountRaw) as ServiceAccount;
    const accessToken = await getFcmAccessToken(serviceAccount);
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;

    let sentCount = 0;
    let skippedCount = eligibleList.length - pendingSubscribers.length;

    for (const sub of pendingSubscribers) {
      const fcmToken = tokenByUser.get(sub.user_id);
      if (!fcmToken) {
        skippedCount++;
        continue;
      }

      const fcmResponse = await fetch(fcmEndpoint, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token: fcmToken,
            notification: {
              title: `${truckName} is live nearby`,
              body: `Serving now${truckAddress}. Tap to view the menu and directions.`,
            },
            data: {
              truck_id: truckId,
            },
            android: {
              priority: 'HIGH',
            },
          },
        }),
      });

      if (fcmResponse.ok) {
        await supabase.from('notifications_log').insert({
          dedup_key: sub.dedup_key,
          user_id: sub.user_id,
          truck_id: truckId,
          sent_at: new Date().toISOString(),
        });
        sentCount++;
      } else {
        skippedCount++;
      }
    }

    return new Response(
      JSON.stringify({ sent: sentCount, skipped: skippedCount }),
      { status: 200, headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});
