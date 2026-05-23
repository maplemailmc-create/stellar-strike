import SwiftUI

struct ContentView: View {
    @State private var showGame = false

    var body: some View {
        if showGame {
            GameView()
        } else {
            ZStack {
                Color(red: 0.05, green: 0.02, blue: 0.1)
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    Text("☄️")
                        .font(.system(size: 70))

                    Text("STELLAR")
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundStyle(.cyan)

                    Text("STRIKE")
                        .font(.system(size: 36, weight: .thin, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))

                    VStack(spacing: 8) {
                        Label("Drag to move", systemImage: "hand.draw")
                        Label("Auto-fire enabled", systemImage: "flame")
                        Label("Survive the waves", systemImage: "bolt.shield")
                    }
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))

                    Spacer()

                    Button {
                        showGame = true
                    } label: {
                        Text("▶ PLAY")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 50)
                            .padding(.vertical, 16)
                            .background(.cyan)
                            .clipShape(Capsule())
                    }

                    Spacer()
                }
            }
        }
    }
}
