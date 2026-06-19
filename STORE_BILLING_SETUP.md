# GymSupport Store Billing setup

The mobile app sells digital Premium features. Android purchases must use
Google Play Billing and iOS purchases must use Apple In-App Purchase.

## Product identifiers

Create the same monthly subscription identifier in each store:

```text
gymsupport_premium_monthly
```

The Android application ID and iOS bundle ID are:

```text
com.gymsupport.app
```

These identifiers must match the Store Console configuration exactly.

## Google Play

1. Create the app in Play Console with package `com.gymsupport.app`.
2. Upload an Android App Bundle to an Internal testing track.
3. Create subscription `gymsupport_premium_monthly`, add and activate a base plan.
4. Add license testers and install the app from the testing link.
5. In Google Cloud, enable Google Play Android Developer API.
6. Create a service account and download its JSON key outside this repository.
7. Grant that service account access to the app in Play Console.

Configure backend User Secrets from `GymSup-BE/GymSupport.API`:

```powershell
dotnet user-secrets set "StoreBilling:PremiumPlanName" "Premium"
dotnet user-secrets set "StoreBilling:AndroidPackageName" "com.gymsupport.app"
dotnet user-secrets set "StoreBilling:AndroidProductId" "gymsupport_premium_monthly"
dotnet user-secrets set "StoreBilling:GoogleServiceAccountJsonPath" "C:\secure\gym-support-play-service-account.json"
```

Never copy the service-account JSON into Git.

## Apple App Store

1. Create the app with bundle ID `com.gymsupport.app` in App Store Connect.
2. Complete Agreements, Tax and Banking.
3. Create a subscription group and auto-renewable subscription
   `gymsupport_premium_monthly`.
4. Create an app-specific shared secret and store it in backend User Secrets.
5. Test with an App Store sandbox account/TestFlight.

```powershell
dotnet user-secrets set "StoreBilling:AppleProductId" "gymsupport_premium_monthly"
dotnet user-secrets set "StoreBilling:AppleSharedSecret" "YOUR_APP_SPECIFIC_SHARED_SECRET"
```

The current backend uses Apple's server-side receipt verification and fails
closed when the shared secret or receipt is invalid. Before long-term production
operation, migrate renewal/refund handling to App Store Server API and App Store
Server Notifications V2.

## Flutter build-time product IDs

Defaults already match the IDs above. To override them:

```powershell
flutter run --dart-define=GOOGLE_PLAY_PREMIUM_PRODUCT_ID=gymsupport_premium_monthly --dart-define=APP_STORE_PREMIUM_PRODUCT_ID=gymsupport_premium_monthly
```

Store products are not returned for an app installed directly with a normal
debug APK. For Android billing tests, install from the Play Internal testing
track using a license tester account.
