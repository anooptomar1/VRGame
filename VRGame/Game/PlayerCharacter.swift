//
//  PlayerCharacter.swift
//  AIExplorer
//
//  Created by Vivek Nagar on 8/6/15.
//  Copyright © 2015 Vivek Nagar. All rights reserved.
//

import SceneKit
import SpriteKit

enum PlayerAnimationState : Int {
    case Die = 0,
    Run,
    Jump,
    JumpFalling,
    JumpLand,
    Idle,
    GetHit,
    Bored,
    RunStart,
    RunStop,
    Walk,
    Unknown
}

enum PlayerStatus : Int {
    case Inactive = 0,
    Alive,
    Dead
}

class PlayerCharacter : SkinnedCharacter, MovingGameObject {
    var status = PlayerStatus.Inactive
    var health:Float = 100.0
    let mass:Float = 3.0
    let maxSpeed:Float = 10.0
    let maxForce:Float = 5.0
    let maxTurnRate:Float = 0.0
    var boundingRadius:Float = 0.0

    var velocity = SCNVector3(x:0.0, y:0.0, z:0.0)
    var heading = SCNVector3(x:0.0, y:0.0, z:0.0)
    var side = SCNVector3(x:0.0, y:0.0, z:0.0)

    let speed:Float = 0.1
    let assetDirectory = "art.scnassets/explorer/"
    let skeletonName = "Bip001_Pelvis"
    let playerCollisionSphereName = "PlayerCollideSphere"
    var currentState : PlayerAnimationState = PlayerAnimationState.Idle
    var previousState : PlayerAnimationState = PlayerAnimationState.Idle

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(characterNode:SCNNode, id:String) {
        super.init(rootNode: characterNode)
        
        self.name = id
        self.status = PlayerStatus.Alive
        self.addCollideSphere()
        
        // Load the animations and store via a lookup table.
        self.setupIdleAnimation()
        self.setupWalkAnimation()
        self.setupBoredAnimation()
        self.setupHitAnimation()
        
        self.changeAnimationState(PlayerAnimationState.Idle)
    }
    
    func addCollideSphere() {
        let scale = self.getObjectScale()
        let playerBox = GameUtilities.getBoundingBox(self)
        let capRadius = scale * Float(playerBox.width/2.0)
        let capHeight = scale * Float(playerBox.height)
        
        self.boundingRadius = Float(capRadius)
        
        print("player box width:\(playerBox.width) height:\(playerBox.height) length:\(playerBox.length)")
        
        let collideSphere = SCNNode()
        collideSphere.name = playerCollisionSphereName
        collideSphere.position = SCNVector3Make(0.0, Float(playerBox.height/2), 0.0)
        let geo = SCNCapsule(capRadius: CGFloat(capRadius), height: CGFloat(capHeight))
        let shape2 = SCNPhysicsShape(geometry: geo, options: nil)
        collideSphere.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.Kinematic, shape: shape2)
        
        // We only want to collide with walls and enemy. Ground collision is handled elsewhere.
        
        collideSphere.physicsBody!.collisionBitMask =
            ColliderType.Enemy.rawValue | ColliderType.LeftWall.rawValue | ColliderType.RightWall.rawValue | ColliderType.BackWall.rawValue | ColliderType.FrontWall.rawValue | ColliderType.Door.rawValue | ColliderType.Ground.rawValue
        
        
        // Put ourself into the player category so other objects can limit their scope of collision checks.
        collideSphere.physicsBody!.categoryBitMask = ColliderType.Player.rawValue
        
        
        self.addChildNode(collideSphere)
        
    }

    func handleContact(node:SCNNode, gameObjects:Dictionary<String, GameObject>) {
        if(node.name == "EnemyCollideSphere-Enemy0" && status == PlayerStatus.Alive) {
            print("Reducing player health")
            //self.reduceHealth()
        }
    }
    
    class func keyForAnimationType(animType:PlayerAnimationState) -> String!
    {
        switch (animType) {
        case .Bored:
            return "bored-1"
        case .Die:
            return "die-1"
        case .GetHit:
            return "hit-1"
        case .Idle:
            return "idle-1"
        case .Jump:
            return "jump_start-1"
        case .JumpFalling:
            return "jump_falling-1"
        case .JumpLand:
            return "jump_land-1"
        case .Run:
            return "run-1"
        case .RunStart:
            return "run_start-1"
        case .RunStop:
            return "run_stop-1"
        case .Walk:
            return "walk-1"
        default:
            return "unknown"
        }
    }

    func changeAnimationState(newState:PlayerAnimationState)
    {
        let newKey = PlayerCharacter.keyForAnimationType(newState)
        let currentKey = PlayerCharacter.keyForAnimationType(previousState)
        
        let runAnim = self.cachedAnimationForKey(newKey)
        runAnim.fadeInDuration = 0.15;
        self.mainSkeleton.removeAnimationForKey(currentKey, fadeOutDuration:0.15)
        self.mainSkeleton.addAnimation(runAnim, forKey:newKey)
    }

    func setupIdleAnimation()
    {
        let fileName = assetDirectory + "idle.dae"
        let idleAnimation = self.loadAndCacheAnimation(fileName, withSkeletonNode:skeletonName, forKey:PlayerCharacter.keyForAnimationType(.Idle))
        idleAnimation.repeatCount = FLT_MAX;
        idleAnimation.fadeInDuration = 0.15;
        idleAnimation.fadeOutDuration = 0.15;
    }
    
    func setupWalkAnimation()
    {
        let fileName = assetDirectory + "walk.dae"
        
        let walkAnimation = self.loadAndCacheAnimation(fileName, withSkeletonNode:skeletonName, forKey:PlayerCharacter.keyForAnimationType(.Walk))
        walkAnimation.repeatCount = FLT_MAX;
        walkAnimation.fadeInDuration = 0.15;
        walkAnimation.fadeOutDuration = 0.15;
    }
    
    func setupBoredAnimation()
    {
        let fileName = assetDirectory + "bored.dae"
        
        let boredAnimation = self.loadAndCacheAnimation(fileName, withSkeletonNode:skeletonName, forKey:PlayerCharacter.keyForAnimationType(.Bored))
        boredAnimation.repeatCount = FLT_MAX;
        boredAnimation.fadeInDuration = 0.15;
        boredAnimation.fadeOutDuration = 0.15;
    }
    
    func setupHitAnimation()
    {
        let fileName = assetDirectory + "hit.dae"
        
        let animation = self.loadAndCacheAnimation(fileName, withSkeletonNode:skeletonName, forKey:PlayerCharacter.keyForAnimationType(.GetHit))
        animation.fadeInDuration = 0.15;
        animation.fadeOutDuration = 0.15;
        animation.repeatCount = FLT_MAX;
    }

    
    func reduceHealth() {
        self.health = self.health - 10.0
        
        if(self.health <= 0.0) {
            //dead
            self.changeAnimationState(PlayerAnimationState.GetHit)
            self.status = PlayerStatus.Dead
        }
    }

    
    func updatePosition(velocity:CGPoint) {
        let delX = velocity.x * CGFloat(speed)
        let delZ = velocity.y * CGFloat(speed)
        
        #if os(iOS)
            var newPlayerPos = SCNVector3Make(self.position.x+Float(delX), self.position.y, self.position.z+Float(delZ))
        #else
            var newPlayerPos = SCNVector3Make(self.position.x+CGFloat(delX), self.position.y, self.position.z+CGFloat(delZ))
        #endif
        let angleDirection = GameUtilities.getAngleFromDirection(self.position, target:newPlayerPos)
        
        let height:Float = 0.0
        //height = self.getGroundHeight(newPlayerPos)
        //print("ground height is \(height)")
        
        newPlayerPos = SCNVector3Make(self.position.x+Float(delX), height, self.position.z+Float(delZ))
        self.rotation = SCNVector4Make(0, 1, 0, Float(angleDirection))

        self.position = newPlayerPos

    }
    
    func update(deltaTime:NSTimeInterval) {
        //update state machine
    }
    
    func isStatic() -> Bool {
        return false
    }
    
    func getID() -> String {
        return self.name!
    }
    
    func getPosition() -> SCNVector3 {
        return self.position
    }
    
    func getVelocity() -> SCNVector3 {
        return self.velocity
    }
    
    // A normalized vector describing the direction of the object
    func getHeading() -> SCNVector3 {
        return self.heading

    }
    // A vector perpendicular to the heading
    func getPerp() -> SCNVector3 {
        return self.side
    }
    
    func getMass() -> Float {
        return self.mass
    }
    func getMaxSpeed() -> Float {
        return self.maxSpeed
    }
    func getMaxForce() -> Float {
        return self.maxForce
    }
    //turn rate in radians per sec
    func getMaxTurnRate() -> Float {
        return self.maxTurnRate
    }

    func getObjectScale() -> Float {
        return 0.20
    }
    
    func getObjectPosition() -> SCNVector3 {
        return self.position
    }
    
    func getBoundingRadius() -> Float {
        return boundingRadius
    }
    
    func getHealth() -> Float {
        return self.health
    }

}
