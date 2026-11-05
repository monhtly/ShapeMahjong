import SwiftUI
import Combine

struct UndoEntry {
    let tiles: [Tile]
    let score: Int
    let combo: Int
}

final class GameEngine: ObservableObject {
    @Published var tiles: [Tile] = []
    @Published var selectedTileId: UUID?
    @Published var score: Int = 0
    @Published var combo: Int = 0
    @Published var bestCombo: Int = 0
    @Published var moves: Int = 0
    @Published var hintsLeft: Int = 3
    @Published var shufflesLeft: Int = 3
    @Published var undosLeft: Int = 3
    @Published var timeElapsed: Int = 0
    @Published var timeRemaining: Int = 180
    @Published var isPaused: Bool = false
    @Published var isWon: Bool = false
    @Published var isLost: Bool = false
    @Published var showWin: Bool = false
    @Published var showNoMoves: Bool = false
    @Published var comboMessage: String?
    @Published var lastPoints: Int = 0
    @Published var lastPointsId: UUID = UUID()
    @Published var hintPairIds: Set<UUID> = []
    @Published var shakeTileId: UUID?
    @Published var isDealing: Bool = false

    let level: Int
    let mode: GameMode
    let levelDef: LevelDefinition
    private let dailySeed: UInt64?
    private var timer: Timer?
    private var lastMatchDate: Date?
    private var undoStack: [UndoEntry] = []

    var pairsRemaining: Int {
        tiles.filter { !$0.isRemoved }.count / 2
    }

    var totalPairs: Int {
        levelDef.tileCount / 2
    }

    var timeText: String {
        if mode == .blitz {
            return GameEngine.formatTime(timeRemaining)
        }
        return GameEngine.formatTime(timeElapsed)
    }

    static func formatTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    init(level: Int = 1, mode: GameMode = .classic, dailySeed: UInt64? = nil) {
        self.level = level
        self.mode = mode
        self.levelDef = LevelDefinition.forLevel(level)
        self.dailySeed = dailySeed
        startLevel()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Setup

    func startLevel() {
        stopTimer()
        score = 0
        combo = 0
        bestCombo = 0
        moves = 0
        hintsLeft = 3
        shufflesLeft = 3
        undosLeft = 3
        timeElapsed = 0
        timeRemaining = 180
        isPaused = false
        isWon = false
        isLost = false
        showWin = false
        showNoMoves = false
        comboMessage = nil
        lastPoints = 0
        selectedTileId = nil
        hintPairIds = []
        shakeTileId = nil
        undoStack = []
        lastMatchDate = nil
        tiles = generateBoard(level: level, seed: dailySeed)
        isDealing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.isDealing = false
        }
        startTimer()
    }

    func restart() {
        startLevel()
    }

    func togglePause() {
        guard !isWon && !isLost else { return }
        isPaused.toggle()
        if isPaused {
            stopTimer()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard !self.isPaused, !self.isWon, !self.isLost else { return }
            if self.mode == .blitz {
                self.timeRemaining -= 1
                if self.timeRemaining <= 0 {
                    self.timeRemaining = 0
                    self.isLost = true
                    self.stopTimer()
                }
            } else {
                self.timeElapsed += 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Free tile rule

    static func isFree(_ tile: Tile, in tiles: [Tile]) -> Bool {
        if tile.isRemoved { return false }
        let above = tiles.contains { other in
            !other.isRemoved && other.gridX == tile.gridX && other.gridY == tile.gridY && other.layer > tile.layer
        }
        if above { return false }
        let left = tiles.contains { other in
            !other.isRemoved && other.layer == tile.layer && other.gridY == tile.gridY && other.gridX == tile.gridX - 1
        }
        let right = tiles.contains { other in
            !other.isRemoved && other.layer == tile.layer && other.gridY == tile.gridY && other.gridX == tile.gridX + 1
        }
        return !left || !right
    }

    func freeTiles() -> [Tile] {
        tiles.filter { GameEngine.isFree($0, in: tiles) }
    }

    // MARK: - Board generation

    static func positionsForLevel(_ def: LevelDefinition) -> [(Int, Int, Int)] {
        var positions: [(Int, Int, Int)] = []
        for y in 0..<def.rows {
            for x in 0..<def.cols {
                positions.append((x, y, 0))
            }
        }
        if def.upperLayers >= 1, def.cols > 2, def.rows > 2 {
            for y in 1..<(def.rows - 1) {
                for x in 1..<(def.cols - 1) {
                    positions.append((x, y, 1))
                }
            }
        }
        if def.upperLayers >= 2, def.cols > 4, def.rows > 4 {
            for y in 2..<(def.rows - 2) {
                for x in 2..<(def.cols - 2) {
                    positions.append((x, y, 2))
                }
            }
        }
        while positions.count > def.tileCount {
            positions.removeLast()
            if positions.count > def.tileCount {
                positions.removeLast()
            }
        }
        return positions
    }

    private func makeRNG(seed: UInt64?, salt: UInt64) -> SeededRNG {
        if let seed = seed {
            return SeededRNG(seed: seed &+ salt &+ 1)
        }
        return SeededRNG(seed: UInt64.random(in: 1...UInt64.max))
    }

    func generateBoard(level: Int, seed: UInt64?) -> [Tile] {
        let def = LevelDefinition.forLevel(level)
        let positions = GameEngine.positionsForLevel(def)
        // Try random pair assignment, keep it only if the greedy solver clears it.
        for attempt in 0..<200 {
            var rng = makeRNG(seed: seed, salt: UInt64(attempt))
            var pairShapes: [ShapeKind] = []
            let pairCount = positions.count / 2
            for i in 0..<pairCount {
                pairShapes.append(ShapeKind.allCases[i % ShapeKind.allCases.count])
            }
            pairShapes.shuffle(using: &rng)
            var shapes: [ShapeKind] = []
            for shape in pairShapes {
                shapes.append(shape)
                shapes.append(shape)
            }
            var shuffledPositions = positions
            shuffledPositions.shuffle(using: &rng)
            shapes.shuffle(using: &rng)
            var tiles: [Tile] = []
            for (index, pos) in shuffledPositions.enumerated() {
                tiles.append(Tile(shape: shapes[index], gridX: pos.0, gridY: pos.1, layer: pos.2))
            }
            if GameEngine.isSolvable(tiles) {
                return tiles
            }
        }
        return constructSolvableBoard(positions: positions, seed: seed)
    }

    static func isSolvable(_ tiles: [Tile]) -> Bool {
        var remaining = tiles
        while !remaining.filter({ !$0.isRemoved }).isEmpty {
            let free = remaining.filter { isFree($0, in: remaining) }
            var found = false
            for shape in ShapeKind.allCases {
                let matching = free.filter { $0.shape == shape }
                if matching.count >= 2 {
                    if let i1 = remaining.firstIndex(where: { $0.id == matching[0].id }),
                       let i2 = remaining.firstIndex(where: { $0.id == matching[1].id }) {
                        remaining[i1].isRemoved = true
                        remaining[i2].isRemoved = true
                        found = true
                        break
                    }
                }
            }
            if !found { return false }
        }
        return true
    }

    // Reverse-construction fallback: pick a free pair, assign it a shape,
    // remove it, repeat. The pick order is itself a valid solution.
    func constructSolvableBoard(positions: [(Int, Int, Int)], seed: UInt64?) -> [Tile] {
        for restart in 0..<50 {
            var rng = makeRNG(seed: seed, salt: UInt64(restart * 1000 + 7))
            var remainingPositions = positions
            var assigned: [Tile] = []
            var shapeIndex = 0
            var ok = true
            while !remainingPositions.isEmpty {
                let pseudoTiles = remainingPositions.map { Tile(shape: .circle, gridX: $0.0, gridY: $0.1, layer: $0.2) }
                let freePositions = remainingPositions.filter { pos in
                    let probe = Tile(shape: .circle, gridX: pos.0, gridY: pos.1, layer: pos.2)
                    return GameEngine.isFree(probe, in: pseudoTiles)
                }
                if freePositions.count < 2 {
                    ok = false
                    break
                }
                let shuffledFree = freePositions.shuffled(using: &rng)
                let p1 = shuffledFree[0]
                let p2 = shuffledFree[1]
                let shape = ShapeKind.allCases[shapeIndex % ShapeKind.allCases.count]
                shapeIndex += 1
                assigned.append(Tile(shape: shape, gridX: p1.0, gridY: p1.1, layer: p1.2))
                assigned.append(Tile(shape: shape, gridX: p2.0, gridY: p2.1, layer: p2.2))
                remainingPositions.removeAll(where: { $0.0 == p1.0 && $0.1 == p1.1 && $0.2 == p1.2 })
                remainingPositions.removeAll(where: { $0.0 == p2.0 && $0.1 == p2.1 && $0.2 == p2.2 })
            }
            if ok {
                return assigned
            }
        }
        // Last resort: pair positions in order. Playable even if not proven solvable.
        var tiles: [Tile] = []
        var index = 0
        while index + 1 < positions.count {
            let shape = ShapeKind.allCases[(index / 2) % ShapeKind.allCases.count]
            tiles.append(Tile(shape: shape, gridX: positions[index].0, gridY: positions[index].1, layer: positions[index].2))
            tiles.append(Tile(shape: shape, gridX: positions[index + 1].0, gridY: positions[index + 1].1, layer: positions[index + 1].2))
            index += 2
        }
        return tiles
    }

    // MARK: - Matching

    func tapTile(_ tile: Tile) {
        guard !isPaused && !isWon && !isLost else { return }
        guard let idx = tiles.firstIndex(where: { $0.id == tile.id }) else { return }
        guard !tiles[idx].isRemoved else { return }
        guard GameEngine.isFree(tiles[idx], in: tiles) else {
            shakeTileId = tile.id
            let tappedId = tile.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                if self?.shakeTileId == tappedId { self?.shakeTileId = nil }
            }
            return
        }
        if selectedTileId == tile.id {
            tiles[idx].isSelected = false
            selectedTileId = nil
            return
        }
        if let selectedId = selectedTileId,
           let selIdx = tiles.firstIndex(where: { $0.id == selectedId }) {
            if tiles[selIdx].shape == tile.shape {
                let pair = [tiles[selIdx], tiles[idx]]
                undoStack.append(UndoEntry(tiles: pair, score: score, combo: combo))
                let now = Date()
                if let last = lastMatchDate, now.timeIntervalSince(last) <= 4 {
                    combo += 1
                } else {
                    combo = 1
                }
                lastMatchDate = now
                bestCombo = max(bestCombo, combo)
                let points = 100 + (combo - 1) * 20
                score += points
                lastPoints = points
                lastPointsId = UUID()
                comboMessage = messageForCombo(combo)
                moves += 1
                tiles[selIdx].isRemoved = true
                tiles[idx].isRemoved = true
                tiles[selIdx].isSelected = false
                tiles[idx].isSelected = false
                selectedTileId = nil
                hintPairIds = []
                checkEnd()
            } else {
                tiles[selIdx].isSelected = false
                tiles[idx].isSelected = true
                selectedTileId = tile.id
                combo = 0
                comboMessage = nil
                moves += 1
                shakeTileId = tile.id
                let tappedId = tile.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                    if self?.shakeTileId == tappedId { self?.shakeTileId = nil }
                }
            }
        } else {
            tiles[idx].isSelected = true
            selectedTileId = tile.id
        }
    }

    private func messageForCombo(_ value: Int) -> String? {
        switch value {
        case 3...4: return "Good"
        case 5...7: return "Great"
        case 8...11: return "Excellent"
        case 12...: return "Perfect"
        default: return nil
        }
    }

    // MARK: - Boosters

    func findHintPair() -> (Tile, Tile)? {
        let free = freeTiles()
        for shape in ShapeKind.allCases {
            let matching = free.filter { $0.shape == shape }
            if matching.count >= 2 {
                return (matching[0], matching[1])
            }
        }
        return nil
    }

    func useHint() {
        guard hintsLeft > 0, !isWon, !isLost, !isPaused else { return }
        guard let pair = findHintPair() else { return }
        hintsLeft -= 1
        hintPairIds = [pair.0.id, pair.1.id]
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.hintPairIds = []
        }
    }

    func shuffleTiles() {
        guard shufflesLeft > 0, !isWon, !isLost, !isPaused else { return }
        shufflesLeft -= 1
        selectedTileId = nil
        hintPairIds = []
        let remainingIndices = tiles.indices.filter { !tiles[$0].isRemoved }
        guard !remainingIndices.isEmpty else { return }
        let remainingPositions = remainingIndices.map { (tiles[$0].gridX, tiles[$0].gridY, tiles[$0].layer) }
        let shapes = remainingIndices.map { tiles[$0].shape }
        for _ in 0..<100 {
            var trial = tiles
            let shuffledShapes = shapes.shuffled()
            for (i, idx) in remainingIndices.enumerated() {
                trial[idx].shape = shuffledShapes[i]
                trial[idx].isSelected = false
            }
            if GameEngine.isSolvable(trial) {
                tiles = trial
                checkEnd()
                return
            }
        }
        let constructed = constructSolvableBoard(positions: remainingPositions, seed: nil)
        var newTiles = tiles
        for (i, idx) in remainingIndices.enumerated() {
            if i < constructed.count {
                newTiles[idx].shape = constructed[i].shape
                newTiles[idx].isSelected = false
            }
        }
        tiles = newTiles
        checkEnd()
    }

    func undoLast() {
        guard undosLeft > 0, let entry = undoStack.popLast() else { return }
        undosLeft -= 1
        score = entry.score
        combo = entry.combo
        for saved in entry.tiles {
            if let idx = tiles.firstIndex(where: { $0.id == saved.id }) {
                tiles[idx].isRemoved = false
                tiles[idx].isSelected = false
            }
        }
        selectedTileId = nil
        hintPairIds = []
        isWon = false
        showWin = false
        showNoMoves = false
    }

    // MARK: - End states

    private func checkEnd() {
        if tiles.filter({ !$0.isRemoved }).isEmpty {
            if mode == .blitz {
                score += 500
                tiles = generateBoard(level: level, seed: nil)
                undoStack = []
                selectedTileId = nil
                return
            }
            isWon = true
            showWin = true
            stopTimer()
            if mode == .classic {
                ProgressStore.saveWin(level: level, stars: starsEarned(), score: score)
            }
            return
        }
        if findHintPair() == nil {
            showNoMoves = true
        }
    }

    func starsEarned() -> Int {
        if mode == .zen { return 3 }
        if hintsLeft == 3 && shufflesLeft == 3 && timeElapsed <= 240 { return 3 }
        if hintsLeft >= 1 && timeElapsed <= 420 { return 2 }
        return 1
    }

    func dismissNoMoves() {
        showNoMoves = false
    }
}
