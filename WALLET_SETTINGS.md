# Wallet settings

Wallet settings live in the database. The phone reads them, caches the last document on the device, and shows that cache immediately the next time the wallet opens. A later response replaces the cache. The person cannot edit the default currency. Linked devices, linked accounts, and statements can be changed. Close wallet stays hidden until the database sets `closeWalletEnabled` to `true`.

Amounts and account numbers follow the rest of the API. Currency codes are `XAF` (shown in the app as FCFA) and `USD`. `FCFA` sent by the server is stored as `XAF`.

## `GET /api/me/wallet/settings`

Authenticated. This is the document the phone caches.

```http
GET /api/me/wallet/settings
Authorization: Bearer <session token>
Cache-Control: no-store
```

```json
{
  "defaultCurrency": "XAF",
  "closeWalletEnabled": false,
  "currencies": ["XAF", "USD"],
  "accounts": [
    {
      "id": "acc-1",
      "label": "MTN Mobile Money",
      "kind": "momo",
      "detail": "+237 677 ••• 456"
    }
  ]
}
```

| Field | Rule |
| --- | --- |
| `defaultCurrency` | Required. `XAF` or `USD`. The phone displays it with a lock and does not send an update for it. There is no client method that changes it |
| `closeWalletEnabled` | Omit or `false` hides Close wallet. Only a boolean `true` shows it. Any other value hides it |
| `currencies` | Wallets this account can open. Omitting the array shows both FCFA and USD. `["XAF"]` shows only the FCFA wallet |
| `accounts` | Linked funding accounts. `kind` is `momo` or `bank`. `detail` is the masked number the phone displays. An empty array is a valid account with nothing linked |

The phone calls this when Wallet opens, when linked accounts open, and when statements open. It paints the cached copy first, then this response. A network failure leaves the cached copy on screen. With no cache yet, the phone shows FCFA, both wallets, no linked accounts, and no Close wallet.

Do not accept `defaultCurrency` from the phone on any write. Staff or account-opening logic in the database is the only writer.

## Linked accounts

The wallet screen lists `accounts` from the cached settings. Manage opens a screen that can add or remove one.

### `POST /api/me/wallet/accounts`

```json
{
  "label": "MTN Mobile Money",
  "kind": "momo",
  "detail": "+237677123456"
}
```

`kind` is `momo` or `bank`. For mobile money, `detail` is E.164. For a bank, `detail` is the account number. Persist the account, store a masked `detail` for later reads, and return the stored account:

```json
{
  "id": "acc-2",
  "label": "MTN Mobile Money",
  "kind": "momo",
  "detail": "+237 677 ••• 456"
}
```

Reject a blank label, an unknown kind, or a detail that fails validation with `422` / `VALIDATION`. The next `GET /api/me/wallet/settings` must include the new account.

### `DELETE /api/me/wallet/accounts/{id}`

Removes that account from the wallet. Unknown id is `404` / `NOT_FOUND`. The next settings read must omit it. Return `200` with `{}`.

## Statements

### `GET /api/me/wallet/statements`

```json
{
  "items": [
    {
      "id": "st-1",
      "period": "2026-05",
      "currency": "XAF",
      "status": "ready",
      "reference": "KP-STMT-2026-05",
      "downloadUrl": "https://files.example/statements/st-1.pdf"
    }
  ]
}
```

`period` is `YYYY-MM`. `status` is `pending`, `ready`, or `failed`. `downloadUrl` is optional. The phone shows the period, the currency, and the status, and opens the reference and URL when the row is tapped. `404` is treated as an empty list until the method exists.

### `POST /api/me/wallet/statements`

```json
{ "period": "2026-05", "currency": "XAF" }
```

Creates a statement for that month and wallet. The currency is which wallet the file covers. It does not change `defaultCurrency`. Return the stored statement. Generate the file on the server. The phone does not build the PDF.

Reject a period that is not a real month, a currency the account does not hold, or a duplicate of a `pending` or `ready` statement for the same period and currency.

### `DELETE /api/me/wallet/statements/{id}`

Removes the stored statement and its file. Unknown id is `404`. Return `200` with `{}`.

## Linked devices

Devices are already listed by `GET /api/auth/devices`. Each item needs an id so the phone can edit it.

```json
{
  "items": [
    {
      "id": "dev-1",
      "label": "Home phone",
      "model": "iPhone 15 Pro",
      "platform": "iOS",
      "current": true,
      "lastSeenAt": "2026-10-29T09:00:00Z"
    }
  ]
}
```

`label` is the name the person set. An empty label falls back to `model` on screen. `current: true` is the device making this request. The phone hides Remove on that row. Rename stays available.

### `PUT /api/auth/devices/{id}`

```json
{ "label": "Home phone" }
```

Stores the label and returns the device. This is the editable field. Model, platform, and `current` stay server-owned. A blank label is `422` / `VALIDATION`. Unknown id is `404`.

### `DELETE /api/auth/devices/{id}`

Signs that device out and deletes its session. Return `200` with `{}`.

Refusing the current device is required:

```json
{
  "error": {
    "code": "CURRENT_DEVICE",
    "message": "This device stays signed in. Use Log out to end it.",
    "details": {}
  }
}
```

HTTP 409. `POST /api/auth/sessions/others` still signs out every device except the current one. The devices screen calls it from "Sign out other devices".

## Close wallet

Show this only when `closeWalletEnabled` is `true` in the settings document. The phone then asks for confirmation and calls:

```http
POST /api/me/wallet/close
Authorization: Bearer <session token>
```

The body is empty. Refuse the close, with the standard error envelope, when the wallet still holds a balance, a payment is pending, or the flag is not enabled. Do not close a wallet because an old client called this method while the flag is false: return `403` / `FEATURE_DISABLED`.

On success:

```json
{
  "closed": true,
  "signedOut": true,
  "message": "Your wallet is closed."
}
```

`signedOut: true` or `closed: true` makes the phone end the session and return to sign-in. Revoke the session on the server in the same transaction as the close.

Until a staff action or an account rule sets `closeWalletEnabled` to `true` and the phone has fetched that document, the Close wallet row is not built.

## What the phone never does

- It does not offer a control that writes `defaultCurrency`.
- It does not show Close wallet from a missing field, a string, or `false`.
- It does not invent a statement file locally. Request, list, and remove go through the methods above.
- It does not keep a removed account or device after the matching DELETE has succeeded and the following GET omits it. The cached settings update from that GET.
