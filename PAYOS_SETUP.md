# GymSupport PayOS setup

The public homepage (`gym_homepage/`, separate from the mobile app) sells the
same subscription plans via PayOS — a QR/bank-transfer gateway. This is a
website purchase, not an in-app purchase, so it is not subject to Google
Play/App Store billing rules.

## PayOS merchant account

1. Create a merchant account at https://payos.vn and a payment channel.
2. Note the **Client ID**, **API Key**, and **Checksum Key** from the channel's
   integration settings.

## Backend configuration

Configure backend User Secrets from `GymSup-BE/GymSupport.API`:

```powershell
dotnet user-secrets set "PayOs:ClientId" "YOUR_CLIENT_ID"
dotnet user-secrets set "PayOs:ApiKey" "YOUR_API_KEY"
dotnet user-secrets set "PayOs:ChecksumKey" "YOUR_CHECKSUM_KEY"
dotnet user-secrets set "PayOs:ReturnUrl" "https://homepage.gsfitness.id.vn/checkout?status=success"
dotnet user-secrets set "PayOs:CancelUrl" "https://homepage.gsfitness.id.vn/checkout?status=cancel"
```

In production (VPS/EC2, systemd `EnvironmentFile=/etc/gymsupport.env`), mirror
the existing `StoreBilling__*` convention:

```text
PayOs__ClientId=YOUR_CLIENT_ID
PayOs__ApiKey=YOUR_API_KEY
PayOs__ChecksumKey=YOUR_CHECKSUM_KEY
PayOs__ReturnUrl=https://homepage.gsfitness.id.vn/checkout?status=success
PayOs__CancelUrl=https://homepage.gsfitness.id.vn/checkout?status=cancel
```

Never commit these values to Git.

## Webhook registration (manual, one-time)

PayOS confirms payments by calling a webhook URL you register in their
merchant dashboard — this cannot be automated from code:

```text
https://api.gsfitness.id.vn/api/payments/payos/webhook
```

The endpoint is `[AllowAnonymous]` (PayOS calls it unauthenticated); the only
thing verifying authenticity is the HMAC-SHA256 signature check against the
Checksum Key, done in `PayOsService.HandleWebhookAsync`. If the endpoint isn't
reachable from the public internet (e.g. still behind a dev tunnel), payments
will get confirmed by the status-polling fallback instead (slower, but still
correct) until the webhook URL is registered.

## API surface added

- `POST /api/payments/payos/checkout` (auth) — body `{ planId }`, returns
  `{ orderCode, checkoutUrl, qrCode, amount, planName, status }`. Render
  `qrCode` client-side as a QR code (it's a raw EMV string, not an image URL).
- `GET /api/payments/payos/status/{orderCode}` (auth) — poll this from the
  checkout page until `status` becomes `Paid`.
- `POST /api/payments/payos/webhook` (anonymous, PayOS → backend only).

## Verifying end-to-end without a real bank transfer

PayOS sandbox/test channels can be paid with a real small transfer, or you can
manually POST a correctly-signed webhook payload to
`/api/payments/payos/webhook` to simulate a payment during development —
compute the HMAC-SHA256 signature over the sorted `data` fields using the same
Checksum Key configured above.
