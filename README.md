# karat

A stock book for a jewellery shop. Android and iOS. Sign-in is Google only. The book is in English and Russian.

The phone talks to [karat-server](https://github.com/kal0mdin/karat-server) for the piece list, creating and editing a piece, the currency list, and piece photos.

## What you can do

- Sign in with Google. The book is kept per Google account.
- Keep a stock list. Switch between pieces still in the case and pieces already sold. Search by name.
- Add or edit a piece: kind (ring, necklace, bracelet, earrings, pendant, brooch, other), metal (gold, silver, platinum, mixed), purity, weight, cost, notes, and a photo.
- Pick the shop currency in the header. A new piece starts in that currency. An existing piece keeps its own. Dollar, ruble, and Tajik somoni come from the server. Amounts are whole units (`$50`, `₽50`, `TJS50`).
- Metal and purity are chosen on the phone: gold, silver, platinum, or mixed, and stamps 999, 916, 750, 585, or 375. The server stores the text.
- Open Gains. Choose a day, a week, a month, or your own dates. Each currency shows its gain. Tap one to see that currency’s revenue, cost, profit, and the sales in the period.
- Open the account to set the shop name. Name and email come from Google.
- Switch language in the header. The choice stays on the phone, next to the currency choice.

## What stays on the phone

Creating, editing, selling, returning, and deleting a piece are saved on karat-server first. The phone keeps the change only after the server accepts it. Opening the app replaces the local list with the server list.

Photos are uploaded through karat-server. The phone keeps a local copy so the picture still shows after the read link expires. The shop name and the header currency stay on the phone.

## Setup

Copy the example and fill it in:

```sh
cp .env.example .env
```

| Key | Meaning |
| --- | --- |
| `KARAT_API` | karat-server address. A phone on the same Wi-Fi uses this Mac’s address, such as `http://192.168.3.5:8080`. An Android emulator uses `http://10.0.2.2:8080`. |
| `GOOGLE_SERVER_CLIENT_ID` | Web client id. Android sign-in sends this. |
| `GOOGLE_IOS_CLIENT_ID` | iOS client id. The same id also stays in `ios/Runner/Info.plist`. |

`.env` is not committed. Android also needs an Android OAuth client in Google Cloud for package `com.karat.karat` and this machine’s debug SHA-1. That client id is not pasted into the app.

Start karat-server, then:

```sh
flutter run
```

A change to `.env` or the Google client ids needs a full restart. Hot reload does not pick them up.
