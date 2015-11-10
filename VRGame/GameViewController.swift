//
//  GameViewController.swift
//  VRGame
//
//  Created by Vivek Nagar on 11/9/15.
//  Copyright (c) 2015 Vivek Nagar. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import SpriteKit
import CoreMotion

enum ColliderType: Int {
    case Ground = 1024
    case Bullet = 4
    case Player = 8
    case Enemy = 16
    case LeftWall = 32
    case RightWall = 64
    case BackWall = 128
    case FrontWall = 256
    case Door = 512
    
}

func degreesToRadians(degrees: Float) -> Float {
    return (degrees * Float(M_PI)) / 180.0
}

func radiansToDegrees(radians: Float) -> Float {
    return (180.0/Float(M_PI)) * radians
}

class GameViewController: UIViewController, SCNSceneRendererDelegate {

    @IBOutlet var leftSceneView : SCNView?
    @IBOutlet var rightSceneView : SCNView?
    
    var motionManager : CMMotionManager?
    var cameraRollNode : SCNNode?
    var cameraPitchNode : SCNNode?
    var cameraYawNode : SCNNode?
    var scene : SCNScene?
    var overlay: SKScene?
    var myLabel: SKLabelNode?
    
    var player:PlayerCharacter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        scene = SCNScene(named: "art.scnassets/ship.scn")!

        leftSceneView?.backgroundColor = UIColor.blackColor()
        rightSceneView?.backgroundColor = UIColor.blackColor()
        
        // Create cameras
        let leftCamera = SCNCamera()
        let rightCamera = SCNCamera()
        
        let leftCameraNode = SCNNode()
        leftCameraNode.camera = leftCamera
        leftCameraNode.camera!.zFar = 500.0
        //leftCameraNode.position = SCNVector3(x: -0.5, y: 0.0, z: 0.0)
        leftCameraNode.position = SCNVector3(x:0.25, y:0.0, z:0.0)
        
        let rightCameraNode = SCNNode()
        rightCameraNode.camera = rightCamera
        rightCameraNode.camera!.zFar = 500.0
        //rightCameraNode.position = SCNVector3(x: 0.5, y: 0.0, z: 0.0)
        rightCameraNode.position = SCNVector3(x:0.75, y:0.0, z:0.0)
        
        let camerasNode = SCNNode()
        camerasNode.position = SCNVector3(x: 0.0, y:0.0, z:-10.0)
        camerasNode.addChildNode(leftCameraNode)
        camerasNode.addChildNode(rightCameraNode)
        
        // The user will be holding their device up (i.e. 90 degrees roll from a flat orientation)
        // so roll the cameras by -90 degrees to orient the view correctly.
        camerasNode.eulerAngles = SCNVector3Make(degreesToRadians(-90.0), 0, 0)

        cameraRollNode = SCNNode()
        cameraRollNode!.addChildNode(camerasNode)
        
        cameraPitchNode = SCNNode()
        cameraPitchNode!.addChildNode(cameraRollNode!)
        
        cameraYawNode = SCNNode()
        cameraYawNode!.addChildNode(cameraPitchNode!)
        
        scene?.rootNode.addChildNode(cameraYawNode!)

        leftSceneView?.pointOfView = leftCameraNode
        rightSceneView?.pointOfView = rightCameraNode

        // Make the camera move back and forth
        let camera_anim = CABasicAnimation(keyPath: "position.y")
        camera_anim.byValue = 5.0
        camera_anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        camera_anim.autoreverses = true
        camera_anim.repeatCount = Float.infinity
        camera_anim.duration = 2.0
        
        camerasNode.addAnimation(camera_anim, forKey: "camera_motion")
        
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene?.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene?.rootNode.addChildNode(ambientLightNode)
        
        self.addFloorAndWalls()
        self.addPlayer()
        
        // retrieve the ship node
        let ship = scene?.rootNode.childNodeWithName("ship", recursively: true)!
        ship?.position = SCNVector3(x:0.0, y:20.0, z:-25.0)
        
        // animate the 3d object
        ship!.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: 1, z: 0, duration: 1)))
        
        // set the scene to the view
        leftSceneView?.scene = scene
        rightSceneView?.scene = scene
        
        leftSceneView?.delegate = self
        
        leftSceneView?.playing = true
        rightSceneView?.playing = true

        // Respond to user head movement
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager?.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XArbitraryZVertical)
        
        //Create overlay scene
        overlay = SKScene(size:(leftSceneView?.bounds.size)!)
        leftSceneView?.overlaySKScene = overlay
        rightSceneView?.overlaySKScene = overlay
        myLabel = SKLabelNode(text: "")
        myLabel?.text = "";
        myLabel?.position = CGPointMake(100, 100)
        overlay!.addChild(myLabel!)

     }
    
    func addPlayer() {
        let skinnedModelName = "art.scnassets/explorer/explorer_skinned.dae"
            
        let modelScene = SCNScene(named:skinnedModelName)
            
        let rootNode = modelScene!.rootNode
            
        rootNode.enumerateChildNodesUsingBlock({
            child, stop in
            // do something with node or stop
            if(child.name == "group") {
                self.player = PlayerCharacter(characterNode:child, id:"Player")
                self.player.scale = SCNVector3Make(self.player.getObjectScale(), self.player.getObjectScale(), self.player.getObjectScale())
                self.player.position = SCNVector3Make(-20, 0, -50)
                    
                self.scene!.rootNode.addChildNode(self.player)
            }
        })

    }

    func addFloorAndWalls() {
        //add floor
        let floorNode = SCNNode()
        let floor = SCNFloor()
        floor.reflectionFalloffEnd = 2.0
        floorNode.geometry = floor
        floorNode.geometry?.firstMaterial?.diffuse.contents = "art.scnassets/wood.png"
        floorNode.geometry?.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(2, 2, 1); //scale the wood texture
        floorNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = true
        floorNode.physicsBody = SCNPhysicsBody.staticBody()
        scene?.rootNode.addChildNode(floorNode)
        
        //add walls
        var wall = SCNNode(geometry:SCNBox(width:400, height:100, length:4, chamferRadius:0))
        wall.geometry!.firstMaterial!.diffuse.contents = "art.scnassets/wall.jpg"
        wall.geometry!.firstMaterial!.diffuse.contentsTransform = SCNMatrix4Mult(SCNMatrix4MakeScale(24, 2, 1), SCNMatrix4MakeTranslation(0, 1, 0));
        wall.geometry!.firstMaterial!.diffuse.wrapS = SCNWrapMode.Repeat;
        wall.geometry!.firstMaterial!.diffuse.wrapT = SCNWrapMode.Mirror;
        wall.geometry!.firstMaterial!.doubleSided = false;
        wall.castsShadow = false;
        wall.geometry!.firstMaterial!.locksAmbientWithDiffuse = true;
        
        wall.position = SCNVector3Make(0, 50, -198);
        wall.name = "FrontWall"
        wall.physicsBody = SCNPhysicsBody.staticBody()
        scene?.rootNode.addChildNode(wall)
        
        wall = wall.clone()
        wall.position = SCNVector3Make(-202, 50, 0);
        wall.name = "LeftWall"
        wall.rotation = SCNVector4Make(0.0, 1.0, 0.0, Float(M_PI_2));
        wall.physicsBody = SCNPhysicsBody.staticBody()
        scene?.rootNode.addChildNode(wall)
        
        wall = wall.clone()
        wall.position = SCNVector3Make(202, 50, 0);
        wall.name = "RightWall"
        wall.rotation = SCNVector4Make(0.0, 1.0, 0.0, -Float(M_PI_2));
        wall.physicsBody = SCNPhysicsBody.staticBody()
        scene?.rootNode.addChildNode(wall)
        
        let backWall = SCNNode(geometry:SCNPlane(width:400, height:100))
        backWall.name = "BackWall"
        backWall.geometry!.firstMaterial = wall.geometry!.firstMaterial;
        backWall.position = SCNVector3Make(0, 50, 198);
        backWall.rotation = SCNVector4Make(0.0, 1.0, 0.0, Float(M_PI));
        backWall.castsShadow = false;
        backWall.physicsBody = SCNPhysicsBody.staticBody()
        scene?.rootNode.addChildNode(backWall)
        
        // add ceiling
        let ceilNode = SCNNode(geometry:SCNPlane(width:400, height:400))
        ceilNode.position = SCNVector3Make(0, 100, 0);
        ceilNode.rotation = SCNVector4Make(1.0, 0.0, 0.0, Float(M_PI_2));
        ceilNode.geometry!.firstMaterial!.doubleSided = false;
        ceilNode.castsShadow = false
        ceilNode.geometry!.firstMaterial!.locksAmbientWithDiffuse = true;
        scene?.rootNode.addChildNode(ceilNode)
    }

    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval)
    {
        if let mm = motionManager, let motion = mm.deviceMotion {
            let currentAttitude = motion.attitude
            
            cameraRollNode!.eulerAngles.x = Float(currentAttitude.roll)
            cameraPitchNode!.eulerAngles.z = Float(currentAttitude.pitch)
            cameraYawNode!.eulerAngles.y = Float(currentAttitude.yaw)
            
            myLabel!.text = String(format: "Pitch %0.1f, Roll:%0.1f, Yaw:%0.1f", currentAttitude.pitch, currentAttitude.roll, currentAttitude.yaw)
            
        }
    }

    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
