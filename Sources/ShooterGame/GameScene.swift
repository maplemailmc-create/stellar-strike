import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Categories
    private enum Category: UInt32 {
        case player  = 1
        case bullet  = 2
        case enemy   = 4
    }

    // MARK: - Nodes
    private var player: SKSpriteNode!
    private var scoreLabel: SKLabelNode!
    private var livesLabel: SKLabelNode!

    // MARK: - State
    private var score = 0
    private var lives = 3
    private var isGameOver = false
    private var enemySpawnTimer: TimeInterval = 0
    private var enemySpawnInterval: TimeInterval = 1.2
    private var bulletFireTimer: TimeInterval = 0

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = .zero
        backgroundColor = SKColor(red: 0.05, green: 0.02, blue: 0.1, alpha: 1)

        buildPlayer()
        buildHUD()
        startStarfield()
    }

    // MARK: - Build
    private func buildPlayer() {
        player = SKSpriteNode(color: .cyan, size: CGSize(width: 40, height: 40))
        player.position = CGPoint(x: size.width / 2, y: 100)
        player.name = "player"

        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.categoryBitMask = Category.player.rawValue
        player.physicsBody?.contactTestBitMask = Category.enemy.rawValue
        player.physicsBody?.collisionBitMask = 0
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = false

        // Glow
        let glow = SKShapeNode(rectOf: player.size, cornerRadius: 4)
        glow.fillColor = .cyan.withAlphaComponent(0.3)
        glow.strokeColor = .cyan
        glow.lineWidth = 2
        glow.glowWidth = 6
        player.addChild(glow)

        addChild(player)
    }

    private func buildHUD() {
        scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        scoreLabel.fontSize = 20
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width - 20, y: size.height - 50)
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.text = "SCORE: 0"
        addChild(scoreLabel)

        livesLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        livesLabel.fontSize = 20
        livesLabel.fontColor = .cyan
        livesLabel.position = CGPoint(x: 20, y: size.height - 50)
        livesLabel.horizontalAlignmentMode = .left
        livesLabel.text = "♥♥♥"
        addChild(livesLabel)
    }

    private func startStarfield() {
        // Tiny drifting dots
        let stars = SKAction.run { [weak self] in
            guard let self = self else { return }
            let star = SKShapeNode(circleOfRadius: 1.5)
            star.fillColor = .white.withAlphaComponent(.random(in: 0.3...0.9))
            star.strokeColor = .clear
            star.position = CGPoint(x: .random(in: 0...self.size.width), y: self.size.height + 10)
            let move = SKAction.moveBy(x: .random(in: -20...20), y: -self.size.height - 40, duration: .random(in: 3...7))
            let remove = SKAction.removeFromParent()
            star.run(SKAction.sequence([move, remove]))
            self.addChild(star)
        }
        run(SKAction.repeatForever(SKAction.sequence([stars, SKAction.wait(forDuration: 0.15)])))
    }

    // MARK: - Game Loop
    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }

        // Fire bullets
        bulletFireTimer += deltaTime(currentTime)
        if bulletFireTimer > 0.25 {
            bulletFireTimer = 0
            fireBullet()
        }

        // Spawn enemies
        enemySpawnTimer += deltaTime(currentTime)
        if enemySpawnTimer > enemySpawnInterval {
            enemySpawnTimer = 0
            spawnEnemy()
            // Ramp difficulty
            enemySpawnInterval = max(0.3, enemySpawnInterval - 0.01)
        }

        // Clean offscreen
        enumerateChildNodes(withName: "bullet") { node, _ in
            if node.position.y > self.size.height + 20 { node.removeFromParent() }
        }
        enumerateChildNodes(withName: "enemy") { node, _ in
            if node.position.y < -20 { node.removeFromParent() }
        }
    }

    private var lastUpdateTime: TimeInterval = 0
    private func deltaTime(_ currentTime: TimeInterval) -> TimeInterval {
        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        return min(dt, 0.1) // cap to avoid burst after pause
    }

    // MARK: - Actions
    private func fireBullet() {
        let bullet = SKSpriteNode(color: .yellow, size: CGSize(width: 6, height: 16))
        bullet.position = CGPoint(x: player.position.x, y: player.position.y + 24)
        bullet.name = "bullet"

        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.categoryBitMask = Category.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask = Category.enemy.rawValue
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.isDynamic = true
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.velocity = CGVector(dx: 0, dy: 600)

        addChild(bullet)
    }

    private func spawnEnemy() {
        let colors: [SKColor] = [.red, .orange, .magenta, .systemPink]
        let color = colors.randomElement()!

        let enemy = SKSpriteNode(color: color, size: CGSize(width: 32, height: 32))
        enemy.position = CGPoint(x: .random(in: 40...(size.width - 40)), y: size.height + 20)
        enemy.name = "enemy"

        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.categoryBitMask = Category.enemy.rawValue
        enemy.physicsBody?.contactTestBitMask = Category.bullet.rawValue | Category.player.rawValue
        enemy.physicsBody?.collisionBitMask = 0
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.velocity = CGVector(dx: .random(in: -30...30), dy: -200)

        // Pulsing glow
        let glow = SKShapeNode(rectOf: enemy.size, cornerRadius: 4)
        glow.fillColor = color.withAlphaComponent(0.2)
        glow.strokeColor = color
        glow.lineWidth = 1.5
        glow.glowWidth = 4
        enemy.addChild(glow)

        addChild(enemy)
    }

    // MARK: - Explosions
    private func explode(at position: CGPoint, color: SKColor) {
        if let emitter = SKEmitterNode(fileNamed: "Explosion") {
            emitter.position = position
            emitter.particleColor = color
            addChild(emitter)
            emitter.run(SKAction.sequence([SKAction.wait(forDuration: 0.3), SKAction.removeFromParent()]))
        } else {
            // Fallback: simple burst of circles
            for _ in 0..<8 {
                let p = SKShapeNode(circleOfRadius: 3)
                p.fillColor = color
                p.strokeColor = .clear
                p.position = position
                let dx = CGFloat.random(in: -60...60)
                let dy = CGFloat.random(in: -60...60)
                let move = SKAction.move(by: CGVector(dx: dx, dy: dy), duration: 0.3)
                let fade = SKAction.fadeOut(withDuration: 0.3)
                let remove = SKAction.removeFromParent()
                p.run(SKAction.sequence([SKAction.group([move, fade]), remove]))
                addChild(p)
            }
        }
    }

    // MARK: - Contact
    func didBegin(_ contact: SKPhysicsContact) {
        guard !isGameOver else { return }

        let a = contact.bodyA
        let b = contact.bodyB

        // Bullet hits enemy
        if (a.categoryBitMask == Category.bullet.rawValue && b.categoryBitMask == Category.enemy.rawValue) ||
           (a.categoryBitMask == Category.enemy.rawValue && b.categoryBitMask == Category.bullet.rawValue) {
            let bullet = a.categoryBitMask == Category.bullet.rawValue ? a.node : b.node
            let enemy  = a.categoryBitMask == Category.enemy.rawValue  ? a.node : b.node

            if let e = enemy {
                explode(at: e.position, color: (e as? SKSpriteNode)?.color ?? .orange)
                e.removeFromParent()
            }
            bullet?.removeFromParent()
            score += 10
            scoreLabel.text = "SCORE: \(score)"
        }

        // Enemy hits player
        if (a.categoryBitMask == Category.player.rawValue && b.categoryBitMask == Category.enemy.rawValue) ||
           (a.categoryBitMask == Category.enemy.rawValue && b.categoryBitMask == Category.player.rawValue) {
            let enemyNode  = a.categoryBitMask == Category.enemy.rawValue  ? a.node : b.node

            if let e = enemyNode {
                explode(at: e.position, color: (e as? SKSpriteNode)?.color ?? .red)
                e.removeFromParent()
            }

            lives -= 1
            livesLabel.text = String(repeating: "♥", count: lives)

            // Flash player red
            let flash = SKAction.sequence([
                SKAction.colorize(with: .red, colorBlendFactor: 1, duration: 0.05),
                SKAction.colorize(with: .cyan, colorBlendFactor: 1, duration: 0.05)
            ])
            player.run(SKAction.repeat(flash, count: 3))

            if lives <= 0 {
                gameOver()
            }
        }
    }

    // MARK: - Game Over
    private func gameOver() {
        isGameOver = true
        physicsWorld.speed = 0

        let overlay = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        overlay.fillColor = .black.withAlphaComponent(0.7)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 10
        overlay.name = "gameOverOverlay"
        addChild(overlay)

        let gameOverLabel = SKLabelNode(fontNamed: "Orbitron-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 42
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: 0, y: 40)
        gameOverLabel.zPosition = 11
        overlay.addChild(gameOverLabel)

        let finalScore = SKLabelNode(fontNamed: "Menlo-Bold")
        finalScore.text = "Score: \(score)"
        finalScore.fontSize = 24
        finalScore.fontColor = .white
        finalScore.position = CGPoint(x: 0, y: -10)
        finalScore.zPosition = 11
        overlay.addChild(finalScore)

        let restartLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        restartLabel.text = "▶ TAP TO RESTART"
        restartLabel.fontSize = 18
        restartLabel.fontColor = .cyan
        restartLabel.position = CGPoint(x: 0, y: -60)
        restartLabel.zPosition = 11
        overlay.addChild(restartLabel)

        // Blink restart
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.5),
            SKAction.fadeAlpha(to: 1, duration: 0.5)
        ])
        restartLabel.run(SKAction.repeatForever(blink))
    }

    private func restart() {
        isGameOver = false
        score = 0
        lives = 3
        enemySpawnInterval = 1.2
        physicsWorld.speed = 1
        removeAllChildren()
        removeAllActions()
        lastUpdateTime = 0
        buildPlayer()
        buildHUD()
        startStarfield()
    }

    // MARK: - Touch
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        if let touch = touches.first {
            let loc = touch.location(in: self)
            player.position.x = loc.x.clamped(to: 30...(size.width - 30))
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else {
            restart()
            return
        }
        if let touch = touches.first {
            let loc = touch.location(in: self)
            player.position.x = loc.x.clamped(to: 30...(size.width - 30))
        }
    }
}

extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
