# Shape Tiles - Mahjong Solitaire (iOS)

A SwiftUI remake of classic Mahjong Solitaire in the style of Double Tile!
(Hungry Studio Mahjong Solitaire). Tiles are bright shapes, not traditional
mahjong characters: circle, triangle, square, star, heart, diamond, hexagon
and crescent.

## What is in the game

- Classic Mahjong Solitaire: tap two identical free tiles to clear the board.
  A tile is free when nothing is on top of it and its left or right side is open.
- 12 levels: Zen Garden (36 tiles) through Master Temple (144 tiles), with
  themes, stars and best scores saved on device.
- Challenges: Daily Challenge (one seeded board per day), Blitz (3 minute
  score attack, endless boards) and Zen (no timer, no score pressure).
- Boosters: Hint, Shuffle and Undo, 3 of each per level.
- Score, combo (Good / Great / Excellent / Perfect), timer, pause and restart.
- Spring animations, deal-in stagger, match particles, combo pop and
  confetti on the win screen.
- System fonts only, SwiftUI only, no third-party libraries.

## Project layout

- `project.yml` - XcodeGen definition. Do not hand-write the .xcodeproj.
- `ShapeMahjong/ShapeMahjongApp.swift` - app entry point.
- `ShapeMahjong/Models.swift` - shapes, tiles, levels, modes, progress storage.
- `ShapeMahjong/GameEngine.swift` - board generation, free-tile rule,
  solvability solver, matching, combo, boosters, timer.
- `ShapeMahjong/TileView.swift` - shape drawing, tile view, particles, confetti.
- `ShapeMahjong/HomeView.swift` - home, levels, challenges and how to play.
- `ShapeMahjong/GameView.swift` - game board, HUD, boosters and end screens.
- `.github/workflows/ios.yml` - CI build that produces the IPA.

## How to build the IPA (GitHub Actions)

1. Push this folder to a GitHub repo.
2. Open the Actions tab and run "Build iOS IPA" (it also runs on push to main).
3. The workflow runs on macOS 15, installs XcodeGen, generates the Xcode
   project, archives with `CODE_SIGNING_ALLOWED=NO`, packages
   `Payload/ShapeMahjong.app` into `ShapeMahjong-unsigned.ipa`, and uploads
   it as an artifact.
4. Download the artifact from the completed run.

## Installing the IPA

This builds an UNSIGNED IPA. It is not App Store signed.

- Sideload it with AltStore or Sideloadly. Those tools sign the app with
  your own Apple ID on your device.
- For App Store distribution you need an Apple Developer account
  ($99 per year), a signing certificate and a provisioning profile, and a
  signed archive. That signing is not set up in this project.

## Build locally (Mac with Xcode 16)

```
brew install xcodegen
xcodegen generate
open ShapeMahjong.xcodeproj
```

Then run on a simulator or a connected iPhone. Deployment target is
iOS 17.0. This project cannot be built on Linux or Windows, because Xcode
only runs on macOS.
