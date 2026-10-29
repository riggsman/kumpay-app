# Platform feature flags and payment checks

The mobile app hides a service the moment the platform turns it off, and shows it again the moment the platform turns it back on. No restart is required.

Before any wallet movement, the app also checks that the person is allowed to do it: the service is on, the identity is verified, the amount is inside the account limits, and — when the platform asks — a second factor has been confirmed. The platform remains the source of truth. The app only refuses early so a person is not sent into a payment the server will reject.

Until `GET /api/features` answers, every flag below is treated as **on**. A missing key in a later snapshot stays **on**. To hide a service the platform must send that key as `false`.

Services the platform creates later — a name, a logo, and up to three inputs — travel in this same snapshot, so they appear without an app release. Account limits are monthly, quarterly, and annual, and they are applied again on every payment. The field rules, the staff methods, and the wallet-then-provider settlement are in [PLATFORM_SERVICES.md](PLATFORM_SERVICES.md).

## Feature keys

| Key | What disappears when it is `false` |
| --- | --- |
| `send` | Send tab, Send actions, the send-money screen |
| `deposit` | Add money / top up |
| `withdrawal` | Withdraw |
| `bills` | Pay tab and every biller |
| `school_fees` | School-fee list and school-fee payment |
| `eneo` | ENEO |
| `camwater` | CAMWATER |
| `canal_plus` | Canal+ (the app also accepts biller id `canal`) |
| `dstv` | DStv |
| `airtime` | Airtime category |
| `internet` | Internet category |
| `taxes` | Taxes category |
| `biometrics` | Biometric login row in Profile |
| `mfa` | Extra sign-in check row in Profile |

`bills` is the master switch. A biller also needs its own key. Hiding `bills` hides school fees even if `school_fees` is `true`.

## How the app stays in step

1. On launch it calls `GET /api/features` and applies the snapshot.
2. It opens `GET /api/features/stream` and applies each event in the same frame it arrives.
3. If the stream is not deployed (HTTP 404) or the connection drops, it polls `GET /api/features` every 4 seconds, and again whenever the app returns to the foreground.
4. `version` is monotonic. A slower response with a smaller version is ignored, so a poll cannot undo a newer stream event.
5. A screen whose tab was turned off is popped back to the root. A payment screen for a service that was turned off replaces its form with a short “turned off” message.

The public read endpoints must send `Cache-Control: no-store`.

## `GET /api/features`

No authentication. This is safe to call before login.

```http
GET /api/features
Accept: application/json
```

```json
{
  "version": 8,
  "updatedAt": "2026-10-29T09:15:00Z",
  "flags": {
    "send": true,
    "deposit": true,
    "withdrawal": false,
    "bills": true,
    "school_fees": true,
    "eneo": false,
    "camwater": false,
    "canal_plus": false,
    "dstv": false,
    "airtime": true,
    "internet": true,
    "taxes": false,
    "biometrics": true,
    "mfa": false
  },
  "services": [
    {
      "serviceName": "council",
      "logo": "council.png",
      "fields": ["amount", "type"]
    }
  ]
}
```

`version` is an integer. Start at `1` and add one on every change, including a new or edited service. `updatedAt` is ISO-8601 UTC. `flags` should include every key in the table. Unknown keys are ignored by this app version and should be stored anyway so a future release can read them.

`services` is the catalog from [PLATFORM_SERVICES.md](PLATFORM_SERVICES.md). Omitting the array leaves the catalog empty. A service with no recognized field is not shown.

## `GET /api/features/stream`

No authentication. `Content-Type: text/event-stream`. Keep the connection open and send one full snapshot (not a patch) whenever a flag changes. Send a comment heartbeat about every 15 seconds so proxies do not close the socket.

```text
HTTP/1.1 200 OK
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive

: ping

event: features
data: {"version":9,"updatedAt":"2026-10-29T09:16:02Z","flags":{"send":false,"deposit":true,"withdrawal":false,"bills":true,"school_fees":true,"eneo":false,"camwater":false,"canal_plus":false,"dstv":false,"airtime":true,"internet":true,"taxes":false,"biometrics":true,"mfa":false}}

```

The app reads `data:` lines and ignores comment lines (`:`). If this route returns 404, the app polls instead. Returning 404 is valid until the stream is ready; polling still hides a service within 4 seconds.

Each event is a full snapshot. Include `services` as well as `flags`. Creating, editing, or disabling a service bumps `version` and pushes one event, the same way a flag change does.

## Staff writes

These are the methods the backoffice uses. The mobile app does not call them. Both require a staff bearer token for an admin or super-admin.

### `GET /api/staff/features`

Returns the same snapshot as the public read, plus who last changed each flag when that is known.

```json
{
  "version": 9,
  "updatedAt": "2026-10-29T09:16:02Z",
  "flags": { "send": false },
  "items": [
    {
      "key": "send",
      "enabled": false,
      "updatedAt": "2026-10-29T09:16:02Z",
      "updatedBy": "staff-id"
    }
  ]
}
```

### `PUT /api/staff/features/{key}`

```http
PUT /api/staff/features/send
Authorization: Bearer <staff token>
Content-Type: application/json

{ "enabled": false }
```

```json
{
  "key": "send",
  "enabled": false,
  "version": 10,
  "updatedAt": "2026-10-29T09:16:40Z"
}
```

Rules:

- Unknown `key` → `404` with the error envelope below.
- The write is persisted. A process restart must not restore the previous value.
- The write bumps the global `version` by one.
- Every connected `GET /api/features/stream` client receives one `features` event with the **full** flag map.
- `GET /api/features` reflects the change immediately.

Suggested error envelope (the same one the rest of the API uses):

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Unknown feature.",
    "details": {}
  }
}
```

## Payment check — `POST /api/me/transactions/authorize`

Called for every signed-in send, deposit, withdrawal, school-fee payment, and biller payment **before** the money endpoint. It must not move money, reserve funds, or debit a limit. It only answers whether this call would be allowed right now.

```http
POST /api/me/transactions/authorize
Authorization: Bearer <session token>
Content-Type: application/json

{
  "kind": "send",
  "amount": 15000,
  "currency": "XAF",
  "biller": "eneo",
  "mfaCode": "482193",
  "challengeId": "ch-1"
}
```

`kind` is `send`, `deposit`, `withdrawal`, or `bill`. `biller` is present for bills (`school_fees`, `eneo`, `camwater`, `canal` or `canal_plus`, `dstv`, `airtime`, `internet`, `taxes`, or a platform service id such as `council`). The same value is also sent as `serviceId`. `mfaCode` and `challengeId` are present only on the retry after `MFA_REQUIRED`.

`amount` is a major-unit number, the same shape as the wallet API (`15000` means 15 000 XAF, not centimes).

### Allowed

```json
{
  "allowed": true,
  "code": "OK",
  "message": "You can send this amount.",
  "kyc": "approved",
  "limits": {
    "currency": "XAF",
    "tier": "Tier 2",
    "perTransaction": 500000,
    "monthly": { "limit": 2000000, "used": 150000, "remaining": 1850000 },
    "quarterly": { "limit": 5000000, "used": 900000, "remaining": 4100000 },
    "annual": { "limit": 15000000, "used": 2400000, "remaining": 12600000 }
  }
}
```

### Refused

Either an HTTP 200 body with `"allowed": false`, or an HTTP 4xx error envelope. The app understands both. Prefer the 200 body so the limits can travel with the decision.

```json
{
  "allowed": false,
  "code": "LIMIT_REACHED",
  "message": "This is above your remaining limit of 20 000 FCFA.",
  "limits": {
    "currency": "XAF",
    "perTransaction": 50000,
    "monthly": { "limit": 50000, "used": 48000, "remaining": 2000 },
    "quarterly": { "limit": 150000, "used": 48000, "remaining": 102000 },
    "annual": { "limit": 600000, "used": 48000, "remaining": 552000 }
  }
}
```

| `code` | When to return it | What the app does |
| --- | --- | --- |
| `OK` | The movement may proceed | Calls the money endpoint |
| `KYC_REQUIRED` | `kyc` is not `approved` | Stops and offers identity verification. The app also stops locally, before this call, when it already knows the account is unverified |
| `LIMIT_REACHED` | Amount is over `perTransaction` or the remaining monthly, quarterly, or annual cap | Stops and shows the message |
| `FEATURE_DISABLED` | The feature key for this kind or biller is off | Stops. The service should already be hidden; this covers a tap that raced the flag |
| `NOT_ALLOWED` | Any other policy refusal (suspended product, blocked corridor, staff hold) | Stops and shows the message |
| `ACCOUNT_RESTRICTED` | The account cannot move money | Stops |
| `MFA_REQUIRED` | A second factor is required. Include `challengeId` | Asks for the code once, then calls this method again with `mfaCode` and `challengeId` |
| `AMOUNT_INVALID` | Amount is missing, not positive, or the wrong currency | Stops |

The app also blocks locally, with no network call, when:

- the feature flag is off
- the amount is not greater than zero
- the signed-in account's KYC is present and not `approved`
- a limits snapshot already on the device shows the amount is over the cap

If this route is not deployed yet, return **404**. The app then keeps the local checks above and continues to the existing money endpoint. A network failure, or any other error, **stops** the payment. The person can retry.

Production should implement this method. 404 is only a bridge so wallets keep working while it is being added.

## Limits — `GET /api/me/limits`

Authenticated. The phone calls this when Profile opens, again when the app returns to the foreground, and again immediately before every send, deposit, withdrawal, and bill. The same object is nested under `limits` in the authorize response. `404` leaves the Profile figure as `—`.

The caps that govern a payment are `perTransaction`, then `monthly`, `quarterly`, and `annual`. Each period object carries `limit`, `used`, and `remaining` in major units. Send all three periods for every account. The phone blocks when the amount is above `perTransaction` or above any period's `remaining`.

```json
{
  "currency": "XAF",
  "tier": "Tier 2",
  "perTransaction": 500000,
  "monthly": { "limit": 2000000, "used": 150000, "remaining": 1850000 },
  "quarterly": { "limit": 5000000, "used": 900000, "remaining": 4100000 },
  "annual": { "limit": 15000000, "used": 2400000, "remaining": 12600000 }
}
```

Older payloads that only send `dailyLimit`, `dailyUsed`, and `remaining` are still honored when the three period objects are absent. New deployments should send the periods and can omit the daily fields.

Compare the same periods on the server. The phone check is only an early stop, and a change to these numbers applies to the next payment without an app update. The full settlement rules are in [PLATFORM_SERVICES.md](PLATFORM_SERVICES.md).

## Security preferences — biometrics and MFA

Authenticated.

### `GET /api/me/security`

```json
{ "biometrics": true, "mfa": false }
```

### `PUT /api/me/security`

```json
{ "biometrics": true, "mfa": true }
```

Return the stored preferences. `404` means the route is not deployed: the app keeps the switch on the device and does not show an error.

These preferences do not turn the feature on. The feature keys `biometrics` and `mfa` do that. When a key is `false`, the row is removed even if the person had turned the preference on. When the key becomes `true`, the row comes back and shows the stored preference.

`mfa: true` means later `POST /api/me/transactions/authorize` calls (and sign-in, when that flow exists) may return `MFA_REQUIRED`.

## Money endpoints the check protects

The app calls authorize, and only then:

| Action | Endpoint | Body |
| --- | --- | --- |
| Send to a KumPay wallet | `POST /api/me/transfers` | `{ "phone", "amount", "currency", "note?" }` |
| Deposit or withdrawal | `POST /api/me/cash` | `{ "amount", "currency", "action": "deposit" \| "withdraw" }` |
| School fees | `POST /api/fees/payments` | Existing fee body, plus header `Idempotency-Key` |
| ENEO, CAMWATER, Canal+, DStv, and the other built-in billers | `POST /api/me/bills` | `{ "biller", "reference", "amount", "currency" }` plus header `Idempotency-Key` |
| A service created by the platform | `POST /api/me/services/{id}/pay` | `{ "serviceId", "amount", "currency", "fields" }` plus header `Idempotency-Key`. The wallet is debited in full when the balance covers the amount. The provider is contacted only when it does not. See [PLATFORM_SERVICES.md](PLATFORM_SERVICES.md) |

`POST /api/me/bills` is new. Until it exists, a signed-in payment to ENEO, CAMWATER, Canal+, or DStv is refused on the phone with “not open for payments yet” instead of a fake receipt. Turning the flag on shows the biller; the payment succeeds only after this method exists and authorize allows it.

`POST /api/me/cash` already refuses external cash movement. The withdrawal and deposit flags hide those screens so a person is not offered a rail the platform has closed. When the rail is opened, set the flag to `true` and make `/api/me/cash` perform the movement after the same authorize rules.

Every money endpoint should repeat the authorize rules on the server. A modified client must not be able to skip them.

## Suggested first values

Ship the flags explicitly rather than relying on the phone defaults:

- `send` and `school_fees`: `true` (these flows exist)
- `deposit` and `withdrawal`: `false` until `/api/me/cash` actually moves money
- `eneo`, `camwater`, `canal_plus`, `dstv`: `false` until `POST /api/me/bills` exists for that biller
- `bills`: `true` while school fees are payable
- `biometrics` and `mfa`: `false` until `PUT /api/me/security` and the MFA challenge are live

Changing any of these in the staff method updates open apps on the next stream event, or within 4 seconds if the stream is down.
