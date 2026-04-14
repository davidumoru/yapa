import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let x: CGFloat
    let delay: Double
    let drift: CGFloat
    let endRotation: Double
    let size: CGSize
    let duration: Double
}

struct ConfettiOverlay: View {
    @Binding var isActive: Bool
    @State private var pieces: [ConfettiPiece] = []

    private let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink,
        .mint, .cyan, .indigo
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    ConfettiBitView(piece: piece, screenHeight: geo.size.height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active { spawn() }
        }
    }

    private func spawn() {
        pieces = (0..<60).map { i in
            ConfettiPiece(
                color: colors[i % colors.count],
                x: CGFloat.random(in: -200...200),
                delay: Double.random(in: 0...0.7),
                drift: CGFloat.random(in: -100...100),
                endRotation: Double.random(in: 360...1080),
                size: CGSize(
                    width: CGFloat.random(in: 6...12),
                    height: CGFloat.random(in: 4...8)
                ),
                duration: Double.random(in: 2.5...4.0)
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            pieces = []
            isActive = false
        }
    }
}

private struct ConfettiBitView: View {
    let piece: ConfettiPiece
    let screenHeight: CGFloat
    @State private var fallen = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(piece.color)
            .frame(width: piece.size.width, height: piece.size.height)
            .rotationEffect(.degrees(fallen ? piece.endRotation : 0))
            .rotation3DEffect(.degrees(fallen ? 360 : 0), axis: (x: 1, y: 0, z: 0))
            .offset(
                x: piece.x + (fallen ? piece.drift : 0),
                y: fallen ? screenHeight + 50 : -20
            )
            .opacity(fallen ? 0 : 1)
            .onAppear {
                withAnimation(.easeIn(duration: piece.duration).delay(piece.delay)) {
                    fallen = true
                }
            }
    }
}
