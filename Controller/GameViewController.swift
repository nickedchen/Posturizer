import SceneKit
import SwiftUI
import UIKit

struct PhysicsCategory {
    static let none = 0
    static let all = Int.max
    static let playerBall = 1 << 0
    static let obstacleBarrier = 1 << 1
}

class ScoreManager: ObservableObject {
    @Published var score: Int = 0
    
    func updateScore(with value: Int) {
        score = value
    }
}

class GameViewController: UIViewController, SCNPhysicsContactDelegate {
    // MARK: - Properties
    
    private let laneLength: Float = 10000
    private let spawnInterval: TimeInterval = 3
    private let obstacleMoveDuration: TimeInterval = 4
    private let jumpHeight: Float = 2.4
    private let jumpDuration: TimeInterval = 0.5
    private let laneSwitchDuration: TimeInterval = 0.2
    private let switchCooldownDuration: TimeInterval = 0.1
    private let headTurnThreshold: CGFloat = 24.0
    private let headGestureJumpLowerThreshold: CGFloat = 20.0
    private let headGestureJumpUpperThreshold: CGFloat = 30.0
    private var lastSwitchTime: TimeInterval = 0
    private let gameTimeDuration: TimeInterval = 60
    private var gameTimeRemaining: TimeInterval = 60
    private var gameTimer: Timer?
    private var gameHasStarted = false
    private var gameStartTime: Date?

    // MARK: - Dependencies

    var scoreManager: ScoreManager?
    var pageRouter: PageRouter?
    
    // MARK: - View Lifecycle

    private var scnView: SCNView!
    private var scnScene: SCNScene!
    private var playerBallNode: SCNNode!
    private var timer: Timer?
    private var laneNodes: [SCNNode] = []
    private var score: Int = 0 {
        didSet {
            scoreManager?.updateScore(with: score)
        }
    }
    
    private var isJumping: Bool = false
    private var cameraViewController: CameraViewController?
    private var currentLaneIndex = 0
    private var isSwitchingLane = false
    
    var currentRoll: CGFloat = 0.0 {
        didSet {
            processHeadGesture()
        }
    }
    
    // MARK: - Game Logic

    private func startGameTimer() {
        gameTimeRemaining = gameTimeDuration
        gameTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateGameTime), userInfo: nil, repeats: true)
    }
    
    @objc private func updateGameTime() {
        guard let startTime = gameStartTime else { return }
            
        let currentTime = Date()
        let elapsedTime = currentTime.timeIntervalSince(startTime)
        if elapsedTime >= gameTimeDuration {
            endGame()
        }
    }
    
    private func endGame() {
        gameStartTime = nil
        gameTimer?.invalidate()
        timer?.invalidate()
        gameHasStarted = false
        navigateToSummary()
    }
    
    private func navigateToSummary() {
        let summaryView = SummaryView(score: score)
           
        let hostingController = UIHostingController(rootView: summaryView)
        DispatchQueue.main.async { [weak self] in
            self?.present(hostingController, animated: true, completion: nil)
        }
    }

    var currentPitch: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gameStartTime = Date()
        startGameTimer()
        setupCameraViewController()
        setupViewAndScene()
        setupCameraAndEnvironment()
        startSpawningBarrier()
    }
    
    // MARK: - Camera Setup
    
    private func setupCameraViewController() {
        cameraViewController = CameraViewController(
            orientationPublisher: { [weak self] roll, pitch, yaw in
                self?.updateHeadOrientation(roll: roll, pitch: pitch, yaw: yaw)
            },
            nosePointPublisher: nil
        )
        
        if let cameraView = cameraViewController?.view {
            cameraView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(cameraView)
            NSLayoutConstraint.activate([
                cameraView.topAnchor.constraint(equalTo: view.topAnchor),
                cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
        }
        cameraViewController?.startCamera()
    }
    
    private func setupPlayerBall() {
        let ball = SCNSphere(radius: 0.5)
        ball.firstMaterial?.diffuse.contents = UIColor.systemRed
        
        playerBallNode = SCNNode(geometry: ball)
        playerBallNode.position = SCNVector3(x: 0, y: 1, z: -6)
        playerBallNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: ball, options: nil))
        playerBallNode.physicsBody?.isAffectedByGravity = false
        playerBallNode.physicsBody?.categoryBitMask = PhysicsCategory.playerBall
        playerBallNode.physicsBody?.collisionBitMask = PhysicsCategory.obstacleBarrier
        playerBallNode.physicsBody?.contactTestBitMask = PhysicsCategory.obstacleBarrier
        playerBallNode.physicsBody?.restitution = 0
        scnScene.rootNode.addChildNode(playerBallNode)
    }
    
    private func processHeadGesture() {
        guard !isSwitchingLane, isSwitchAllowed() else { return }
            
        if abs(currentRoll) > headTurnThreshold {
            let direction = currentRoll < 0 ? -1 : 1
            if direction == -1 && currentLaneIndex > -1 {
                movePlayerBall(direction: direction)
            } else if direction == 1 && currentLaneIndex < 1 {
                movePlayerBall(direction: direction)
            }
        } else if currentPitch > headGestureJumpLowerThreshold && currentPitch < headGestureJumpUpperThreshold {
            jumpPlayerBall()
        }
    }
    
    private func flashPlayerBall() {
        let hideAction = SCNAction.hide()
        let unhideAction = SCNAction.unhide()
        let waitAction = SCNAction.wait(duration: 0.1)
        let flashSequence = SCNAction.sequence([hideAction, waitAction, unhideAction, waitAction])
        let repeatFlash = SCNAction.repeat(flashSequence, count: 5)
        playerBallNode.runAction(repeatFlash)
    }
    
    private func isSwitchAllowed() -> Bool {
        return Date.timeIntervalSinceReferenceDate - lastSwitchTime >= switchCooldownDuration
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraViewController?.startCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isSwitchingLane = false
        cameraViewController?.stopCamera()
        timer?.invalidate()
    }
    
    // MARK: - Scene Setup

    private func setupViewAndScene() {
        scnView = SCNView()
        scnView.allowsCameraControl = false
        scnView.backgroundColor = UIColor.systemGray6
        view = scnView
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnScene.physicsWorld.gravity = SCNVector3(0, -9.8, 0)
        scnScene.physicsWorld.contactDelegate = self
    }
    
    private func setupCameraAndEnvironment() {
        setupCamera()
        setupLanes()
        setupPlayerBall()
        setupLighting()
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let collision = (contact.nodeA.physicsBody!.categoryBitMask, contact.nodeB.physicsBody!.categoryBitMask)
        
        if collision == (PhysicsCategory.playerBall, PhysicsCategory.obstacleBarrier) || collision == (PhysicsCategory.obstacleBarrier, PhysicsCategory.playerBall) {
            DispatchQueue.main.async { [weak self] in
                if contact.nodeA.physicsBody?.categoryBitMask == PhysicsCategory.obstacleBarrier {
                    contact.nodeA.name = "collided"
                } else if contact.nodeB.physicsBody?.categoryBitMask == PhysicsCategory.obstacleBarrier {
                    contact.nodeB.name = "collided"
                }
                self?.flashPlayerBall()
                self?.decrementScore()
            }
        }
    }
    
    private func setupCamera() {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 2.5, z: 2)
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    private func setupLanes() {
        for i in -1 ... 1 {
            let lane = SCNBox(width: 1.6, height: 0.5, length: CGFloat(laneLength), chamferRadius: 0.01)
            lane.firstMaterial?.diffuse.contents = UIColor.systemGray
            let laneNode = SCNNode(geometry: lane)
            laneNode.position = SCNVector3(x: Float(i) * 2, y: -0.1, z: -laneLength / 2)
            scnScene.rootNode.addChildNode(laneNode)
            laneNodes.append(laneNode)
            
            laneNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: lane, options: nil))
            laneNode.physicsBody?.categoryBitMask = PhysicsCategory.none
            laneNode.physicsBody?.contactTestBitMask = PhysicsCategory.none
            laneNode.physicsBody?.collisionBitMask = PhysicsCategory.playerBall
        }
    }
    
    private func setupLighting() {
        let omniLightNode = SCNNode()
        omniLightNode.light = SCNLight()
        omniLightNode.light?.type = .omni
        omniLightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scnScene.rootNode.addChildNode(omniLightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.white
        scnScene.rootNode.addChildNode(ambientLightNode)
    }
    
    // MARK: - Game Control

    private func startSpawningBarrier() {
        guard !gameHasStarted else { return }
        gameHasStarted = true
        
        timer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.spawnBarrier()
        }
    }
    
    private func spawnBarrier() {
        let barrierWidth = Float(2 * 2.0)
        let barrierHeight: Float = 0.8
        let barrierLength: Float = 0.8
        
        let barrier = SCNBox(width: CGFloat(barrierWidth), height: CGFloat(barrierHeight), length: CGFloat(barrierLength), chamferRadius: 1.0)
        barrier.firstMaterial?.diffuse.contents = UIColor.orange
        
        let barrierNode = SCNNode(geometry: barrier)
        let lanePositions: [Float] = [-1, 0, 1]
        let randomIndex = Int.random(in: 0 ..< lanePositions.count)
        barrierNode.position = SCNVector3(x: lanePositions[randomIndex], y: 1, z: -50)
        
        barrierNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        barrierNode.physicsBody?.categoryBitMask = PhysicsCategory.obstacleBarrier
        barrierNode.physicsBody?.collisionBitMask = PhysicsCategory.none
        barrierNode.physicsBody?.contactTestBitMask = PhysicsCategory.playerBall
        
        scnScene.rootNode.addChildNode(barrierNode)
        
        let moveAction = SCNAction.move(to: SCNVector3(x: lanePositions[randomIndex], y: 1, z: 50), duration: obstacleMoveDuration)
        let removeAction = SCNAction.run { [weak self] _ in
            if barrierNode.name != "collided" && barrierNode.position.z > 0 {
                self?.incrementScore()
            }
            barrierNode.removeFromParentNode()
        }
        
        let sequenceAction = SCNAction.sequence([moveAction, removeAction])
        
        barrierNode.runAction(sequenceAction)
    }
    
    private func jumpPlayerBall() {
        guard !isJumping else { return }
        
        isJumping = true
        let jumpUpAction = SCNAction.moveBy(x: 0, y: CGFloat(jumpHeight), z: 0, duration: jumpDuration)
        jumpUpAction.timingMode = .easeOut
        let jumpDownAction = SCNAction.moveBy(x: 0, y: CGFloat(-jumpHeight), z: 0, duration: jumpDuration)
        jumpDownAction.timingMode = .easeIn
        
        let resetJumpStateAction = SCNAction.run { [weak self] _ in
            self?.isJumping = false
        }
        
        let jumpSequence = SCNAction.sequence([jumpUpAction, jumpDownAction, resetJumpStateAction])
        
        playerBallNode.runAction(jumpSequence)
    }
    
    private func movePlayerBall(direction: Int) {
        guard !isSwitchingLane, !isJumping else { return }
        
        currentLaneIndex += direction
        isSwitchingLane = true
        
        let newPosX = Float(currentLaneIndex * 2)
        let moveAction = SCNAction.move(to: SCNVector3(newPosX, playerBallNode.position.y, playerBallNode.position.z), duration: laneSwitchDuration)
        moveAction.timingMode = .easeInEaseOut
        
        playerBallNode.runAction(moveAction) { [weak self] in
            self?.isSwitchingLane = false
        }
    }

    func updateHeadOrientation(roll: CGFloat, pitch: CGFloat, yaw: CGFloat) {
        DispatchQueue.main.async { [weak self] in
            self?.currentRoll = roll
            self?.currentPitch = -pitch
        }
    }
    
    // MARK: - Score Handling
    
    private func incrementScore() {
        DispatchQueue.main.async { [weak self] in
            self?.score += 8
        }
    }
    
    private func decrementScore() {
        DispatchQueue.main.async { [weak self] in
            self?.score = max(self!.score - 4, 0)
        }
    }
    
    // MARK: - Clean Up
    
    deinit {
        timer?.invalidate()
        cleanUpScene()
    }
    
    func cleanUpScene() {
        if let rootNode = scnScene?.rootNode {
            rootNode.enumerateChildNodes { node, _ in
                node.removeFromParentNode()
            }
        }
    }
}
