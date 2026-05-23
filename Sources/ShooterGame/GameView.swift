import SwiftUI
import SpriteKit

struct GameView: View {
    @StateObject private var sceneHolder = SceneHolder()

    var body: some View {
        SpriteView(scene: sceneHolder.scene)
            .ignoresSafeArea()
            .statusBarHidden()
    }
}

final class SceneHolder: ObservableObject {
    let scene: GameScene = {
        let scene = GameScene()
        scene.scaleMode = .resizeFill
        return scene
    }()
}
