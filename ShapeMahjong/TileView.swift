import SwiftUI

// MARK: - Custom shapes

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + 2))
        path.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.maxY - 2))
        path.addLine(to: CGPoint(x: rect.minX + 2, y: rect.maxY - 2))
        path.closeSubpath()
        return path
    }
}

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + 2))
        path.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 2))
        path.addLine(to: CGPoint(x: rect.minX + 2, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width / 2 - 2
        let ry = rect.height / 2 - 2
        for i in 0..<6 {
            let angle = Double(i) * Double.pi / 3.0 - Double.pi / 2.0
            let point = CGPoint(x: cx + CGFloat(cos(angle)) * rx, y: cy + CGFloat(sin(angle)) * ry)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        let outer = min(rect.width, rect.height) / 2 - 1
        let inner = outer * 0.45
        for i in 0..<10 {
            let radius = i % 2 == 0 ? outer : inner
            let angle = Double(i) * Double.pi / 5.0 - Double.pi / 2.0
            let point = CGPoint(x: cx + CGFloat(cos(angle)) * radius, y: cy + CGFloat(sin(angle)) * radius)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.32))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.08, y: rect.minY + h * 0.28),
            control1: CGPoint(x: rect.midX - w * 0.18, y: rect.minY + h * 0.05),
            control2: CGPoint(x: rect.minX + w * 0.02, y: rect.minY + h * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY - h * 0.05),
            control1: CGPoint(x: rect.minX - w * 0.05, y: rect.minY + h * 0.62),
            control2: CGPoint(x: rect.midX - w * 0.28, y: rect.maxY - h * 0.18)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - w * 0.08, y: rect.minY + h * 0.28),
            control1: CGPoint(x: rect.midX + w * 0.28, y: rect.maxY - h * 0.18),
            control2: CGPoint(x: rect.maxX + w * 0.05, y: rect.minY + h * 0.62)
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + h * 0.32),
            control1: CGPoint(x: rect.maxX - w * 0.02, y: rect.minY + h * 0.08),
            control2: CGPoint(x: rect.midX + w * 0.18, y: rect.minY + h * 0.05)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Shape symbol

struct ShapeSymbol: View {
    let kind: ShapeKind

    var body: some View {
        switch kind {
        case .circle:
            Circle().fill(kind.gradient)
        case .triangle:
            TriangleShape().fill(kind.gradient)
        case .square:
            RoundedRectangle(cornerRadius: 6).fill(kind.gradient)
        case .star:
            StarShape().fill(kind.gradient)
        case .heart:
            HeartShape().fill(kind.gradient)
        case .diamond:
            DiamondShape().fill(kind.gradient)
        case .hexagon:
            HexagonShape().fill(kind.gradient)
        case .crescent:
            ZStack {
                Circle().fill(kind.gradient)
                Circle()
                    .fill(AppTheme.cream)
                    .offset(x: 7, y: -4)
            }
        }
    }
}

// MARK: - Tile view

struct ShapeTileView: View {
    let tile: Tile
    let isHinted: Bool
    let isShaking: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.55, green: 0.50, blue: 0.42))
                .offset(y: 3)
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.cream)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(tile.isSelected ? Color.orange : Color.white.opacity(0.7), lineWidth: tile.isSelected ? 3 : 1)
                )
            ShapeSymbol(kind: tile.shape)
                .padding(size * 0.20)
            if isHinted {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.yellow, lineWidth: 3)
                    .shadow(color: Color.yellow.opacity(0.9), radius: 8)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
        .scaleEffect(tile.isSelected ? 1.12 : 1.0)
        .offset(x: isShaking ? -4 : 0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: tile.isSelected)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isShaking)
    }
}

// MARK: - Match particles (small bursting circles)

struct MatchParticlesView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { i in
                Circle()
                    .fill(ShapeKind.allCases[i % ShapeKind.allCases.count].colors.0)
                    .frame(width: 8, height: 8)
                    .offset(
                        x: animate ? CGFloat(cos(Double(i) * 0.628)) * 42 : 0,
                        y: animate ? CGFloat(sin(Double(i) * 0.628)) * 42 : 0
                    )
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animate = true
            }
        }
    }
}

// MARK: - Confetti (simple colored circles and rectangles falling)

struct ConfettiView: View {
    @State private var falling = false
    private let pieces = Array(0..<40)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces, id: \.self) { i in
                    let color = ShapeKind.allCases[i % ShapeKind.allCases.count].colors.0
                    let x = CGFloat((i * 37) % 100) / 100.0 * geo.size.width
                    let delay = Double(i % 10) * 0.12
                    let size = CGFloat(6 + (i % 4) * 3)
                    Group {
                        if i % 2 == 0 {
                            Circle().fill(color).frame(width: size, height: size)
                        } else {
                            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: size, height: size * 0.6)
                        }
                    }
                    .position(x: x, y: falling ? geo.size.height + 20 : -20)
                    .rotationEffect(.degrees(falling ? Double(i * 36) : 0))
                    .animation(.linear(duration: 2.6).delay(delay), value: falling)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            falling = true
        }
    }
}
