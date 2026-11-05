import SwiftUI

struct ContentView: View {
    @State private var screen: String = "home"
    @State private var gameLevel: Int = 1
    @State private var gameMode: GameMode = .classic
    @State private var gameSeed: UInt64?
    @State private var showGame: Bool = false
    @State private var gameId: UUID = UUID()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if showGame {
                GameView(
                    level: gameLevel,
                    mode: gameMode,
                    dailySeed: gameSeed,
                    onExit: { showGame = false },
                    onNextLevel: {
                        if gameMode == .classic && gameLevel < 12 {
                            gameLevel += 1
                            gameId = UUID()
                        } else {
                            showGame = false
                            screen = "levels"
                        }
                    }
                )
                .id(gameId)
            } else if screen == "levels" {
                LevelsView(
                    onBack: { screen = "home" },
                    onPlayLevel: { level in
                        gameLevel = level
                        gameMode = .classic
                        gameSeed = nil
                        gameId = UUID()
                        showGame = true
                    }
                )
            } else if screen == "challenges" {
                ChallengesView(
                    onBack: { screen = "home" },
                    onPlayMode: { mode in
                        gameMode = mode
                        if mode == .daily {
                            gameLevel = 3
                            gameSeed = DailySeed.seed()
                        } else if mode == .blitz {
                            gameLevel = 2
                            gameSeed = nil
                        } else {
                            gameLevel = 1
                            gameSeed = nil
                        }
                        gameId = UUID()
                        showGame = true
                    }
                )
            } else if screen == "howto" {
                HowToPlayView(onBack: { screen = "home" })
            } else {
                HomeView(
                    onPlay: {
                        gameLevel = min(ProgressStore.unlockedLevel(), 12)
                        gameMode = .classic
                        gameSeed = nil
                        gameId = UUID()
                        showGame = true
                    },
                    onLevels: { screen = "levels" },
                    onChallenges: { screen = "challenges" },
                    onHowTo: { screen = "howto" }
                )
            }
        }
    }
}

struct HomeView: View {
    var onPlay: () -> Void
    var onLevels: () -> Void
    var onChallenges: () -> Void
    var onHowTo: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)
                HStack(spacing: 10) {
                    ForEach(Array(ShapeKind.allCases.prefix(4)), id: \.self) { kind in
                        ShapeSymbol(kind: kind)
                            .frame(width: 28, height: 28)
                    }
                }
                VStack(spacing: 6) {
                    Text("Shape Tiles")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Mahjong Solitaire")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                    Text("Match the shapes. Clear the board. Find your calm.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Button(action: onPlay) {
                    Text("Play")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [Color.orange, Color.pink], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 32)
                VStack(spacing: 12) {
                    MenuButton(title: "Levels", detail: "12 boards, from Zen Garden to Master Temple", action: onLevels)
                    MenuButton(title: "Challenges", detail: "Daily, Blitz and Zen modes", action: onChallenges)
                    MenuButton(title: "How to Play", detail: "Free tiles, matching and boosters", action: onHowTo)
                }
                .padding(.horizontal, 32)
                HStack(spacing: 10) {
                    ForEach(Array(ShapeKind.allCases.suffix(4)), id: \.self) { kind in
                        ShapeSymbol(kind: kind)
                            .frame(width: 28, height: 28)
                    }
                }
                Spacer().frame(height: 20)
            }
        }
    }
}

struct MenuButton: View {
    let title: String
    let detail: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(detail)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.75))
                }
                Spacer()
                Text(">")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(16)
            .background(Color.white.opacity(0.14))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
        }
    }
}

struct StarRowView: View {
    let stars: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                StarShape()
                    .fill(i < stars ? Color.yellow : Color.white.opacity(0.3))
                    .frame(width: 16, height: 16)
            }
        }
    }
}

struct LevelsView: View {
    var onBack: () -> Void
    var onPlayLevel: (Int) -> Void
    private let unlocked = ProgressStore.unlockedLevel()

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onBack) {
                    Text("Back")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                }
                Spacer()
                Text("Levels")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("").frame(width: 64)
            }
            .padding(.horizontal, 20)
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(LevelDefinition.all) { def in
                        let locked = def.id > unlocked
                        Button(action: {
                            if !locked { onPlayLevel(def.id) }
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Level \(def.id)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                Text(def.name)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("\(def.tileCount) tiles")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.75))
                                if locked {
                                    Text("Locked")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.7))
                                } else {
                                    StarRowView(stars: ProgressStore.stars(for: def.id))
                                    if ProgressStore.bestScore(for: def.id) > 0 {
                                        Text("Best: \(ProgressStore.bestScore(for: def.id))")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.75))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(
                                LinearGradient(colors: [def.primary, def.secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(18)
                            .opacity(locked ? 0.55 : 1.0)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .padding(.top, 16)
    }
}

struct ChallengesView: View {
    var onBack: () -> Void
    var onPlayMode: (GameMode) -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onBack) {
                    Text("Back")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                }
                Spacer()
                Text("Challenges")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("").frame(width: 64)
            }
            .padding(.horizontal, 20)
            ScrollView {
                VStack(spacing: 14) {
                    ChallengeCard(
                        title: "Daily Challenge",
                        detail: "One board per day. Same board for everyone today: \(DailySeed.label()).",
                        button: "Play Today",
                        action: { onPlayMode(.daily) }
                    )
                    ChallengeCard(
                        title: "Blitz",
                        detail: "3 minutes on the clock. Clear board after board and chase a high score.",
                        button: "Start Blitz",
                        action: { onPlayMode(.blitz) }
                    )
                    ChallengeCard(
                        title: "Zen",
                        detail: "No timer and no score pressure. Just shapes and a quiet board.",
                        button: "Start Zen",
                        action: { onPlayMode(.zen) }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .padding(.top, 16)
    }
}

struct ChallengeCard: View {
    let title: String
    let detail: String
    let button: String
    var action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(detail)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            Button(action: action) {
                Text(button)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(14)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.14))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
}

struct HowToPlayView: View {
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onBack) {
                    Text("Back")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                }
                Spacer()
                Text("How to Play")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("").frame(width: 64)
            }
            .padding(.horizontal, 20)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HowToRow(title: "1. Tap a free tile", detail: "A tile is free when nothing is on top of it and its left or right side is open.")
                    HowToRow(title: "2. Match two of a kind", detail: "Tap a second free tile with the same shape to clear both and score 100 points.")
                    HowToRow(title: "3. Build a combo", detail: "Match quickly, within 4 seconds, to raise your combo and earn bonus points.")
                    HowToRow(title: "4. Use boosters", detail: "Hint finds a pair. Shuffle rearranges the tiles. Undo brings back your last pair. You get 3 of each per level.")
                    HowToRow(title: "5. Clear the board", detail: "Remove every tile to win the level and earn up to 3 stars.")
                    Text("The shapes")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(ShapeKind.allCases) { kind in
                            VStack(spacing: 6) {
                                ShapeSymbol(kind: kind).frame(width: 34, height: 34)
                                Text(kind.displayName).font(.system(size: 12)).foregroundColor(.white.opacity(0.85))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(14)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .padding(.top, 16)
    }
}

struct HowToRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(detail)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.12))
        .cornerRadius(16)
    }
}
