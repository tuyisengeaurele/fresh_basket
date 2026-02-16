# FreshBasket

A full-stack mobile application for fresh fruit and vegetable delivery in Rwanda, built with Flutter and Firebase.

## Features

- **Multi-role authentication** — Customer, Seller, Driver, Admin
- **Product catalog** — Browse, search, and filter fresh produce
- **Cart & Checkout** — Offline-persistent cart with GPS delivery location
- **Order management** — Real-time status tracking for all roles
- **Seller dashboard** — Product management, order processing, analytics
- **Driver app** — GPS navigation, delivery confirmation, earnings tracker
- **Admin panel** — User management, seller approval, platform analytics
- **Push notifications** — FCM v1 with deep-link routing
- **Dark mode** — Full adaptive theming

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Flutter 3.x |
| State | Riverpod 2.x |
| Backend | Firebase (Auth, Firestore, Storage, FCM) |
| Maps | Google Maps Flutter |
| Local storage | Hive |
| Routing | GoRouter |

## Getting Started

```bash
# Clone the repo
git clone https://github.com/tuyisengeaurele/fresh_basket.git
cd fresh_basket

# Install dependencies
flutter pub get

# Copy environment file
cp .env.example .env
# Fill in your Firebase and API keys

# Run the app
flutter run
```

## iOS Testing (Windows)

Use [Codemagic](https://codemagic.io) — the included `codemagic.yaml` builds an iOS `.app` for simulator or `.ipa` for device testing. See [ALTSTORE_GUIDE.md](docs/ALTSTORE_GUIDE.md) for sideloading instructions.

## Project Structure

```
lib/
├── core/           # Constants, services, routing, theme
├── features/       # Feature modules (auth, products, cart, orders, seller, driver, admin)
├── shared/         # Shared models, widgets, providers
└── main.dart
```

## License

MIT
