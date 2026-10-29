# Autopay

Autopay is off for everyone until that account holder turns it on in **Profile → Autopay**. The phone does not show the Pay bills autopay card, and it does not schedule anything, while the switch is off.

When the holder turns it on, they add each service themselves:

- the service (ENEO, CAMWATER, Canal+, DStv, while that biller is enabled)
- the amount to pay, in major units (FCFA)
- when to pay, using the same two schedules the app already had:
  - `monthly` — a day of the month, `1`–`28` (for example Canal+ on the 5th)
  - `below` — pay once the balance falls under a threshold (for example ENEO under 5 000 FCFA)

One service has one rule. Saving the same service again replaces the amount and the schedule. Removing it stops that payment. Turning the switch off keeps the rules but stops them from running and hides them on Pay bills.

## `GET /api/me/autopay`

Authenticated. Returns the holder's plan.

```json
{
  "enabled": true,
  "rules": [
    {
      "id": "ap_canal",
      "serviceId": "canal",
      "serviceName": "Canal+ Premium",
      "amount": 18000,
      "currency": "XAF",
      "when": "monthly",
      "dayOfMonth": 5
    },
    {
      "id": "ap_eneo",
      "serviceId": "eneo",
      "serviceName": "ENEO prepaid",
      "amount": 5000,
      "currency": "XAF",
      "when": "below",
      "threshold": 5000
    }
  ]
}
```

`enabled` must be boolean `true` or the phone treats the plan as off. A rule is dropped when the amount is missing or not positive, the service id or name is blank, `when` is neither `monthly` nor `below`, a monthly rule has no day in `1`–`28`, or a below rule has no positive `threshold`.

`404` means the method is not deployed. The phone keeps the plan the holder already saved on the device and does not wipe it.

## `PUT /api/me/autopay`

Authenticated. Body is the same object. Replace the stored plan with it. Return the saved plan, or an empty body.

The phone sends this whenever the holder flips the switch, adds a service, or removes one. A `404`, or a failure to reach KumPay at all, leaves the on-device plan in place. Any other response restores the previous plan on the phone and shows the message.

Running the payment is the backend's job. On the chosen day, or when the service balance falls below `threshold`, debit `amount` from the KumPay wallet with the same checks used for a manual bill payment (the holder is allowed, within limits, and verified). Do not start a provider request unless the wallet cannot cover the amount.
