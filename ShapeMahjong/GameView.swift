import SwiftUI

struct GameView: View {
    let level: Int
    let mode: GameMode
    let dailySeed: UInt64?
    var onExit: () -> Void
    var onNextLevel: () -> Void

    @StateObject private var engine: GameEngine

    init(level: Int, mode: GameMode, dailySeed: UInt64?, onExit: @escaping () -> Void, onNextLevel: @escaping () -> Void) {
        self.level = level
        self.mode = mode
        self.dailySeed = dailySeed
        self.onExit = onExit
        self.onNextLevel = onNextLevel
        _engine = StateObject(wrappedValue: GameEngine(level: level, mode: mode, dailySeed: dailySeed))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [engine.levelDef.primary.opacity(0.55), AppTheme.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 10) {
                topBar
                hudRow
                boosterRow
                boardArea
                Spacer()
            }
            .padding(.top, 8)

            if let message = engine.comboMessage, engine.combo >= 3 {
                VStack {
                    Spacer().frame(height: 170)
                    Text(message)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.yellow)
                        .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                        .scaleEffect(1.0)
                    Text("Combo x\(engine.combo)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .allowsHitTesting(false)
            }

            if engine.lastPoints > 0 {
                VStack {
                    Spacer().frame(height: 220)
                    Text("+\(engine.lastPoints)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                    MatchParticlesView()
                        .id(engine.lastPointsId)
                    Spacer()
                }
                .allowsHitTesting(false)
            }

            if engine.showWin {
                winOverlay
            } else if engine.isLost {
                loseOverlay
            } else if engine.showNoMoves {
                noMovesOverlay
            } else if engine.isPaused {
                pauseOverlay
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onExit) {
                Text("Exit")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(10)
            }
            Spacer()
            VStack(spacing: 2) {
                Text(mode == .classic ? "Level \(level): \(engine.levelDef.name)" : mode.displayName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                if mode == .daily {
                    Text(DailySeed.label())
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.75))
                }
            }
            Spacer()
            Button(action: { engine.togglePause() }) {
                Text(engine.isPaused ? "Resume" : "Pause")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.18))
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 16)
    }

    private var hudRow: some View {
        HStack(spacing: 10) {
            HUDChip(label: "Score", value: "\(engine.score)")
            HUDChip(label: "Pairs", value: "\(engine.pairsRemaining)/\(engine.totalPairs)")
            if mode == .zen {
                HUDChip(label: "Mode", value: "Zen")
            } else {
                HUDChip(label: mode == .blitz ? "Time Left" : "Time", value: engine.timeText)
            }
            HUDChip(label: "Combo", value: "x\(engine.combo)")
        }
        .padding(.horizontal, 16)
    }

    private var boosterRow: some View {
        HStack(spacing: 10) {
            BoosterButton(title: "Hint", count: engine.hintsLeft, disabled: engine.hintsLeft == 0) {
                engine.useHint()
            }
            BoosterButton(title: "Shuffle", count: engine.shufflesLeft, disabled: engine.shufflesLeft == 0) {
                engine.shuffleTiles()
            }
            BoosterButton(title: "Undo", count: engine.undosLeft, disabled: engine.undosLeft == 0) {
                engine.undoLast()
            }
            BoosterButton(title: "Restart", count: nil, disabled: false) {
                engine.restart()
            }
        }
        .padding(.horizontal, 16)
    }

    private var boardArea: some View {
        GeometryReader { geo in
            let cols = CGFloat(engine.levelDef.cols)
            let rows = CGFloat(engine.levelDef.rows)
            let tileSize = min((geo.size.width - 16) / cols, (geo.size.height - 8) / rows)
            let boardWidth = tileSize * cols
            let boardHeight = tileSize * rows
            let originX = (geo.size.width - boardWidth) / 2
            let originY = (geo.size.height - boardHeight) / 2
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.10))
                    .frame(width: boardWidth + 12, height: boardHeight + 12)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                ForEach(Array(engine.tiles.enumerated()), id: \.element.id) { index, tile in
                    if !tile.isRemoved {
                        let free = GameEngine.isFree(tile, in: engine.tiles)
                        ShapeTileView(
                            tile: tile,
                            isHinted: engine.hintPairIds.contains(tile.id),
                            isShaking: engine.shakeTileId == tile.id,
                            size: tileSize - 3
                        )
                        .opacity(engine.isDealing ? 0 : (free ? 1.0 : 0.55))
                        .scaleEffect(engine.isDealing ? 0.5 : 1.0)
                        .position(
                            x: originX + CGFloat(tile.gridX) * tileSize + tileSize / 2 - CGFloat(tile.layer) * 4,
                            y: originY + CGFloat(tile.gridY) * tileSize + tileSize / 2 - CGFloat(tile.layer) * 4
                        )
                        .zIndex(Double(tile.layer))
                        .animation(.spring(response: 0.35, dampingFraction: 0.7).delay(engine.isDealing ? Double(index % 24) * 0.015 : 0), value: engine.isDealing)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                                engine.tapTile(tile)
                            }
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .padding(.horizontal, 8)
    }

    private var winOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            ConfettiView()
            VStack(spacing: 16) {
                Text("Level Complete")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                StarRowView(stars: engine.starsEarned())
                Text("Score: \(engine.score)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Time: \(GameEngine.formatTime(engine.timeElapsed))  Best combo: x\(engine.bestCombo)")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.85))
                Button(action: onNextLevel) {
                    Text(mode == .classic && level < 12 ? "Next Level" : "Done")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .cornerRadius(16)
                }
                Button(action: onExit) {
                    Text("Back to Home")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(24)
            .background(Color(red: 0.12, green: 0.20, blue: 0.32))
            .cornerRadius(24)
            .padding(.horizontal, 32)
        }
    }

    private var loseOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Time Up")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("Blitz score: \(engine.score)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("Best combo: x\(engine.bestCombo)")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.85))
                Button(action: { engine.restart() }) {
                    Text("Play Again")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .cornerRadius(16)
                }
                Button(action: onExit) {
                    Text("Back to Home")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(24)
            .background(Color(red: 0.12, green: 0.20, blue: 0.32))
            .cornerRadius(24)
            .padding(.horizontal, 32)
        }
    }

    private var noMovesOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("No Moves Left")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("No free matching pair is left. Shuffle the tiles or restart the level.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                Button(action: {
                    engine.dismissNoMoves()
                    engine.shuffleTiles()
                }) {
                    Text("Shuffle (\(engine.shufflesLeft) left)")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .cornerRadius(16)
                }
                .disabled(engine.shufflesLeft == 0)
                .opacity(engine.shufflesLeft == 0 ? 0.5 : 1.0)
                Button(action: { engine.restart() }) {
                    Text("Restart Level")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.18))
                        .cornerRadius(14)
                }
                Button(action: onExit) {
                    Text("Back to Home")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(24)
            .background(Color(red: 0.12, green: 0.20, blue: 0.32))
            .cornerRadius(24)
            .padding(.horizontal, 32)
        }
    }

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Paused")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Button(action: { engine.togglePause() }) {
                    Text("Resume")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .cornerRadius(16)
                }
                Button(action: { engine.restart() }) {
                    Text("Restart Level")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.18))
                        .cornerRadius(14)
                }
                Button(action: onExit) {
                    Text("Back to Home")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(24)
            .background(Color(red: 0.12, green: 0.20, blue: 0.32))
            .cornerRadius(24)
            .padding(.horizontal, 32)
        }
    }
}

struct HUDChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.75))
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.14))
        .cornerRadius(12)
    }
}

struct BoosterButton: View {
    let title: String
    let count: Int?
    let disabled: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                if let count = count {
                    Text("\(count) left")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.75))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.16))
            .cornerRadius(12)
        }
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1.0)
    }
}
