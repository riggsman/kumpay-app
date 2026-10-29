# Platform services and account limits

The phone does not ship a fixed list of extra services, and it does not decide a person's monthly, quarterly, or annual cap. Both come from the platform at run time.

A service is shown when the snapshot includes a name, a logo, and at least one of `amount`, `receiver`, and `type`. Paying it uses the same checks as every other wallet movement, then one pay method. The phone debits nothing itself. The server debits the KumPay balance when that balance covers the amount, and starts a provider request only when it does not.

Read [FEATURE_FLAGS.md](FEATURE_FLAGS.md) for the feature keys, the live stream, and `POST /api/me/transactions/authorize`. This document is the part the backend adds on top of that.

## What the phone already does

1. It reads `services` from `GET /api/features` and from each `GET /api/features/stream` event. The same `version` rule applies: a new or edited service must bump `version`, or a slower poll can hide it again.
2. While `bills` is `true`, Home shows up to three services under **New services**, and Pay bills shows every service under **Services**. `bills: false` hides the catalog. `enabled: false` on one service drops that service only.
3. The pay screen shows the service name, the logo, and the fields the platform sent, in that order, with the platform's labels. At most three inputs are shown.
4. On pay, the phone loads `GET /api/me/limits`, stops locally if a period or the per-payment cap is exceeded, then calls `POST /api/me/transactions/authorize`, then `POST /api/me/services/{id}/pay`.
5. It displays the `message` from the pay response. It never calls the provider.

Until the first successful features response, the catalog is empty. Flags still default to on, as in FEATURE_FLAGS.md.

## Account limits

`GET /api/me/limits` is authenticated. Return this object at the top level, and nest the same object under `limits` in the authorize response. Amounts are major units (`5000` means 5 000 XAF).

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

| Field | Meaning |
| --- | --- |
| `perTransaction` | Largest single payment |
| `monthly.limit` / `used` / `remaining` | Calendar month |
| `quarterly.limit` / `used` / `remaining` | Calendar quarter |
| `annual.limit` / `used` / `remaining` | Calendar year |

Send all three periods for every account. `remaining` must be `limit - used`, and it must not be negative. The phone blocks, before authorize, in this order:

1. Amount above `perTransaction`.
2. Amount above `monthly.remaining`.
3. Amount above `quarterly.remaining`.
4. Amount above `annual.remaining`.

A period object that is missing is skipped. A period with only `limit` and `used`, and no `remaining`, does not block on the phone, so always send `remaining`.

`dailyLimit`, `dailyUsed`, and a top-level `remaining` are a legacy shape. They are applied only when all three period objects are absent. New accounts should send the periods and omit the daily fields.

The phone refetches this method when Profile opens and when the app returns to the foreground, and again at the start of every payment. Changing a cap in the backoffice applies to the next payment with no app release. Authorize and the pay method must repeat the check. A modified client must not be able to skip it.

`404` means the method is not deployed. Profile shows `—`, and the payment continues to authorize, which remains responsible for the cap.

## Service catalog

Put the catalog on the same snapshot as the flags.

```json
{
  "version": 12,
  "updatedAt": "2026-10-29T10:00:00Z",
  "flags": { "bills": true },
  "services": [
    {
      "id": "council",
      "serviceName": "council",
      "logo": "council.png",
      "enabled": true,
      "currency": "XAF",
      "fields": ["amount", "type"]
    }
  ]
}
```

That example is the council levy. The phone renders:

- the name **council**
- the logo from `{API_BASE}/media/services/council.png`
- two inputs, labeled **Amount** and **Type**
- no Receiver row, because that field was not sent

### Identity

| JSON field | Required | Rule |
| --- | --- | --- |
| `serviceName` or `name` | yes | Text shown on Home, Pay bills, and the pay screen. `serviceName` is the name used in the example above |
| `id` | no | Stable id used in the pay URL. When omitted, the phone uses `serviceName`, then `name`. Do not change it after payments exist |
| `enabled` | no | Defaults to on. `false` removes the service from the phone until a later snapshot turns it back on |
| `currency` | no | Defaults to `XAF` |
| `logo` | no | File name, absolute `http`/`https` URL, or a path beginning with `/` |
| `fixedAmount` | when there is no `amount` field | Major-unit number the wallet will debit |
| `fields` | yes | One to three entries. Zero recognized fields and the phone drops the whole service |

### Fields

The only keys the phone renders are `amount`, `receiver`, and `type`. Any other key is ignored. Duplicate keys are ignored. More than three recognized fields are cut to the first three. If nothing recognized remains, the service is not shown.

Two shapes are accepted. A string uses the default label. An object supplies the label the platform wants on screen, and optional choices.

```json
"fields": ["amount", "type"]
```

```json
"fields": [
  { "key": "amount", "label": "Levy" },
  { "key": "receiver", "label": "Taxpayer" },
  { "key": "type", "label": "Levy type", "options": ["Market", "Property"] }
]
```

`key` may also be sent as `name`. Default labels are **Amount**, **Receiver**, and **Type**. `options` turns `type` into a choice list. Without `options`, `type` is a text input. `amount` is a numeric input. `receiver` is a text input.

`amount` is how the person states what to debit. When `amount` is not one of the fields, send `fixedAmount`. If neither is present the phone refuses to pay, because there is no number to debit. Prefer a fixed amount over inventing an amount field the person should not edit.

### Logo

A bare file name is loaded from `{API_BASE}/media/services/{file}`. Serve `GET /media/services/council.png` without authentication, with `Content-Type: image/png` or `image/jpeg`. A failed image falls back to a generic icon, so a missing file does not hide the service.

Replace the art by publishing a new file name (`council-2.png`) or an absolute URL. The phone caches by URL, so overwriting `council.png` in place will not refresh open apps reliably.

### Staff methods

The phone does not call these. Require a staff bearer token for an admin or super-admin. Every successful write persists, bumps the global features `version` by one, and pushes one full snapshot (flags and services) to every `GET /api/features/stream` client. `GET /api/features` must show the change immediately. `Cache-Control: no-store` on the public read.

#### `POST /api/staff/services`

```json
{
  "serviceName": "council",
  "logo": "council.png",
  "enabled": true,
  "currency": "XAF",
  "fields": [
    { "key": "amount", "label": "Amount" },
    { "key": "type", "label": "Type", "options": ["Market", "Property"] }
  ]
}
```

`"fields": ["amount", "type"]` is the same service with the default labels and a free-text type.

Reject the write, with the standard error envelope, when:

| Condition | HTTP | `code` |
| --- | --- | --- |
| `serviceName` is blank, or `id` is already in use | 422 | `VALIDATION` |
| `fields` is missing, empty, or has no key in `amount`, `receiver`, `type` | 422 | `VALIDATION` |
| A key is repeated, or more than three fields were sent | 422 | `VALIDATION` |
| `amount` is absent and `fixedAmount` is missing or not greater than zero | 422 | `VALIDATION` |
| `type.options` is present and empty | 422 | `VALIDATION` |

Store the service even if this app version would ignore an extra future key. Return the stored service plus the new `version`.

```json
{
  "id": "council",
  "serviceName": "council",
  "logo": "council.png",
  "enabled": true,
  "currency": "XAF",
  "fields": [
    { "key": "amount", "label": "Amount" },
    { "key": "type", "label": "Type", "options": ["Market", "Property"] }
  ],
  "version": 13
}
```

#### `PUT /api/staff/services/{id}`

Replaces the name, logo, currency, fixed amount, enabled flag, and fields. The id in the path does not change. Unknown id is `404` / `NOT_FOUND`. The same validation as create applies. Bump `version` and push the stream.

To take a service off the phone without deleting its payments, send `"enabled": false`. The next snapshot removes the row. Sending `"enabled": true` puts it back.

Do not hard-delete a service that already has payments. If a delete method exists, implement it as `enabled: false`.

## Paying a service

```http
POST /api/me/services/council/pay
Authorization: Bearer <session token>
Content-Type: application/json
Idempotency-Key: svc-1730188800000000-42

{
  "serviceId": "council",
  "amount": 5000,
  "currency": "XAF",
  "fields": {
    "amount": "5000",
    "type": "Market"
  }
}
```

`Idempotency-Key` is required. The same key for the same account returns the original response and must not debit twice or open a second provider request.

`fields` contains one entry per input the service defined. Values are strings. The numeric `amount` is the major-unit number the phone resolved: the amount the person typed, or `fixedAmount` when the service has no amount input.

### Checks, in order

The phone has already called authorize. Repeat the rules here so a client that skips authorize still cannot pay.

1. Authenticate. Missing or expired session: `401`.
2. Load the service. Missing, or `enabled: false`: `404` with `FEATURE_DISABLED` or `NOT_FOUND`.
3. If the `bills` flag is off: `403` with `FEATURE_DISABLED`.
4. KYC must be `approved`, or return `KYC_REQUIRED`.
5. Reject the amount when it exceeds `perTransaction` or any of `monthly.remaining`, `quarterly.remaining`, `annual.remaining`. Use `LIMIT_REACHED` and include the `limits` object. Do this against the balance you are willing to commit, not against a stale phone copy.
6. Every field the service defined is present and non-blank. No extra keys. A `type` with `options` must be one of those options. When the service has an amount field, the numeric `amount` must match that field. When it has `fixedAmount` and no amount field, `amount` must equal `fixedAmount`. Otherwise `422` / `VALIDATION`.
7. Resolve `Idempotency-Key` before moving money.

### Settlement

This is the backend's decision. The phone does not branch.

**Balance covers the amount.** In one database transaction, debit the full amount from the wallet, write the payment, and add the amount to `used` on the monthly, quarterly, and annual periods (and reduce each `remaining`). Do not call the provider.

```json
{
  "status": "debited",
  "providerRequested": false,
  "reference": "KP-SVC-1001",
  "message": "Paid from your KumPay balance.",
  "amount": 5000,
  "currency": "XAF"
}
```

**Balance is lower than the amount.** Do not debit the wallet. Do not take a partial debit. Start exactly one provider request for the full amount, with the service id, the fields, and the payment reference. Count the amount against the three periods when the provider accepts the request, so unpaid requests cannot be stacked past the cap. If the provider later fails, release that usage. Return:

```json
{
  "status": "provider_pending",
  "providerRequested": true,
  "reference": "KP-SVC-1002",
  "message": "Your balance did not cover this, so the provider request was started.",
  "amount": 5000,
  "currency": "XAF"
}
```

`providerRequested: true` or `status: "provider_pending"` is how the phone knows the provider path was used. `message` is shown as the receipt. When `message` is empty, the phone uses the two sentences above.

The phone stops after this response. It does not poll the provider, retry the debit, or call any provider URL. A person who taps Pay again generates a new `Idempotency-Key`. Reject that second payment if a `provider_pending` request for the same account and service is still open, with `NOT_ALLOWED` and a message that names the open reference.

Use the error envelope from FEATURE_FLAGS.md for every refusal. A network error on the phone already stops the payment; do not leave an uncommitted debit behind a failed response. Commit the debit only when the `debited` response is what you will return.

## Authorize

`POST /api/me/transactions/authorize` stays a dry run: no debit, no limit consumption, no provider call. For a platform service the body has `kind: "bill"`, `biller: "council"`, and `serviceId: "council"`. Built-in billers also send `serviceId` equal to `biller`; ignore `serviceId` for those and keep using `POST /api/me/bills` or `POST /api/fees/payments`.

Apply the same four limit checks as above. Return the period object inside `limits` so the phone can show the cap that refused the payment.

## Worked example

Staff creates the council levy:

```http
POST /api/staff/services
Authorization: Bearer <staff token>

{
  "serviceName": "council",
  "logo": "council.png",
  "fields": ["amount", "type"]
}
```

The server stores id `council`, bumps `version`, and emits one stream event whose `services` array contains that object. Within the same frame, or within 4 seconds when the stream is down, Home and Pay bills show **council**.

The person enters an amount and a type and taps Pay. The phone calls limits, authorize, then:

```http
POST /api/me/services/council/pay
```

If the wallet holds at least that amount, the response is `debited` and no provider is contacted. If the wallet is short, the response is `provider_pending` and the provider request is the server's. The phone shows the message and does not start a request of its own.

Turning the service off is `PUT /api/staff/services/council` with `"enabled": false`. The row disappears. Opening the pay screen after that shows that council is turned off, and pay is not offered.
