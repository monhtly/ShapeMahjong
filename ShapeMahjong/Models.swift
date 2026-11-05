import SwiftUI

// MARK: - Shape kinds (tiles are shapes, not traditional mahjong characters)

enum ShapeKind: String, CaseIterable, Identifiable, Hashable {
    case circle
    case triangle
    case square
    case star
    case heart
    case diamond
    case hexagon
    case crescent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .circle: return "Circle"
        case .triangle: return "Triangle"
        case .square: return "Square"
        case .star: return "Star"
        case .heart: return "Heart"
        case .diamond: return "Diamond"
        case .hexagon: return "Hexagon"
        case .crescent: return "Crescent"
        }
    }

    // Distinct bright gradient for each shape.
    var colors: (Color, Color) {
        switch self {
        case .circle: return (Color(red: 0.99, green: 0.45, blue: 0.35), Color(red: 0.95, green: 0.20, blue: 0.35))
        case .triangle: return (Color(red: 1.0, green: 0.75, blue: 0.25), Color(red: 0.98, green: 0.50, blue: 0.10))
        case .square: return (Color(red: 0.35, green: 0.80, blue: 0.45), Color(red: 0.10, green: 0.60, blue: 0.35))
        case .star: return (Color(red: 1.0, green: 0.85, blue: 0.30), Color(red: 1.0, green: 0.65, blue: 0.05))
        case .heart: return (Color(red: 1.0, green: 0.45, blue: 0.65), Color(red: 0.90, green: 0.15, blue: 0.45))
        case .diamond: return (Color(red: 0.45, green: 0.75, blue: 1.0), Color(red: 0.20, green: 0.45, blue: 0.95))
        case .hexagon: return (Color(red: 0.70, green: 0.55, blue: 1.0), Color(red: 0.45, green: 0.25, blue: 0.90))
        case .crescent: return (Color(red: 0.55, green: 0.90, blue: 0.95), Color(red: 0.15, green: 0.60, blue: 0.85))
        }
    }

    var gradient: LinearGradient {
        let pair = colors
        return LinearGradient(colors: [pair.0, pair.1], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Tile

struct Tile: Identifiable, Equatable, Hashable {
    let id: UUID
    var shape: ShapeKind
    var gridX: Int
    var gridY: Int
    var layer: Int
    var isRemoved: Bool = false
    var isSelected: Bool = false

    init(id: UUID = UUID(), shape: ShapeKind, gridX: Int, gridY: Int, layer: Int) {
        self.id = id
        self.shape = shape
        self.gridX = gridX
        self.gridY = gridY
        self.layer = layer
    }

    static func == (lhs: Tile, rhs: Tile) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Game mode

enum GameMode: String, CaseIterable, Identifiable {
    case classic
    case daily
    case blitz
    case zen

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .daily: return "Daily Challenge"
        case .blitz: return "Blitz"
        case .zen: return "Zen"
        }
    }

    var detail: String {
        switch self {
        case .classic: return "Play through 12 levels"
        case .daily: return "One board per day"
        case .blitz: return "3 minutes, score attack"
        case .zen: return "No timer, no pressure"
        }
    }
}

// MARK: - Level definition

struct LevelDefinition: Identifiable {
    let id: Int
    let name: String
    let tileCount: Int
    let cols: Int
    let rows: Int
    let upperLayers: Int
    let primary: Color
    let secondary: Color

    static let all: [LevelDefinition] = [
        LevelDefinition(id: 1, name: "Zen Garden", tileCount: 36, cols: 6, rows: 6, upperLayers: 0, primary: Color(red: 0.25, green: 0.70, blue: 0.55), secondary: Color(red: 0.15, green: 0.45, blue: 0.55)),
        LevelDefinition(id: 2, name: "Coral Reef", tileCount: 48, cols: 8, rows: 6, upperLayers: 0, primary: Color(red: 0.95, green: 0.50, blue: 0.45), secondary: Color(red: 0.95, green: 0.35, blue: 0.60)),
        LevelDefinition(id: 3, name: "Turtle Bay", tileCount: 72, cols: 8, rows: 7, upperLayers: 1, primary: Color(red: 0.30, green: 0.65, blue: 0.85), secondary: Color(red: 0.20, green: 0.45, blue: 0.70)),
        LevelDefinition(id: 4, name: "Bamboo Forest", tileCount: 72, cols: 9, rows: 8, upperLayers: 0, primary: Color(red: 0.35, green: 0.75, blue: 0.40), secondary: Color(red: 0.20, green: 0.55, blue: 0.35)),
        LevelDefinition(id: 5, name: "Dragon Peak", tileCount: 96, cols: 10, rows: 8, upperLayers: 1, primary: Color(red: 0.90, green: 0.40, blue: 0.30), secondary: Color(red: 0.75, green: 0.25, blue: 0.35)),
        LevelDefinition(id: 6, name: "Neon City", tileCount: 96, cols: 12, rows: 8, upperLayers: 0, primary: Color(red: 0.65, green: 0.45, blue: 0.95), secondary: Color(red: 0.35, green: 0.35, blue: 0.90)),
        LevelDefinition(id: 7, name: "Crystal Cave", tileCount: 108, cols: 11, rows: 8, upperLayers: 1, primary: Color(red: 0.45, green: 0.75, blue: 0.95), secondary: Color(red: 0.30, green: 0.50, blue: 0.85)),
        LevelDefinition(id: 8, name: "Sunset Dunes", tileCount: 108, cols: 12, rows: 9, upperLayers: 0, primary: Color(red: 0.98, green: 0.60, blue: 0.25), secondary: Color(red: 0.90, green: 0.35, blue: 0.45)),
        LevelDefinition(id: 9, name: "Frost Palace", tileCount: 120, cols: 12, rows: 9, upperLayers: 1, primary: Color(red: 0.65, green: 0.85, blue: 0.95), secondary: Color(red: 0.45, green: 0.65, blue: 0.90)),
        LevelDefinition(id: 10, name: "Volcano", tileCount: 120, cols: 12, rows: 10, upperLayers: 0, primary: Color(red: 0.95, green: 0.35, blue: 0.20), secondary: Color(red: 0.65, green: 0.15, blue: 0.25)),
        LevelDefinition(id: 11, name: "Galaxy", tileCount: 144, cols: 12, rows: 10, upperLayers: 1, primary: Color(red: 0.55, green: 0.45, blue: 0.95), secondary: Color(red: 0.25, green: 0.20, blue: 0.60)),
        LevelDefinition(id: 12, name: "Master Temple", tileCount: 144, cols: 12, rows: 12, upperLayers: 0, primary: Color(red: 0.95, green: 0.75, blue: 0.30), secondary: Color(red: 0.75, green: 0.45, blue: 0.15))
    ]

    static func forLevel(_ level: Int) -> LevelDefinition {
        all.first(where: { $0.id == level }) ?? all[0]
    }
}

// MARK: - Persistence (UserDefaults)

enum ProgressStore {
    static func unlockedLevel() -> Int {
        let saved = UserDefaults.standard.integer(forKey: "unlockedLevel")
        return saved == 0 ? 1 : max(1, saved)
    }

    static func stars(for level: Int) -> Int {
        UserDefaults.standard.integer(forKey: "stars_\(level)")
    }

    static func bestScore(for level: Int) -> Int {
        UserDefaults.standard.integer(forKey: "bestScore_\(level)")
    }

    static func saveWin(level: Int, stars: Int, score: Int) {
        let oldStars = self.stars(for: level)
        if stars > oldStars {
            UserDefaults.standard.set(stars, forKey: "stars_\(level)")
        }
        if score > bestScore(for: level) {
            UserDefaults.standard.set(score, forKey: "bestScore_\(level)")
        }
        if level < 12 {
            let unlocked = unlockedLevel()
            if level + 1 > unlocked {
                UserDefaults.standard.set(level + 1, forKey: "unlockedLevel")
            }
        }
    }
}

// MARK: - Deterministic RNG for Daily Challenge

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

enum DailySeed {
    static func seed(for date: Date = Date()) -> UInt64 {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .dayOfYear], from: date)
        let year = UInt64(comps.year ?? 2026)
        let day = UInt64(comps.dayOfYear ?? 1)
        return year * 1000 + day
    }

    static func label(for date: Date = Date()) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: date)
    }
}

// MARK: - Theme

enum AppTheme {
    static let backgroundTop = Color(red: 0.05, green: 0.25, blue: 0.35)
    static let backgroundBottom = Color(red: 0.25, green: 0.15, blue: 0.45)
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.90)
    static let tileEdge = Color(red: 0.75, green: 0.70, blue: 0.60)
}
