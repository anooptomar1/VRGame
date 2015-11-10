//
//  Created by Vivek Nagar on 8/15/14.
//  Copyright (c) 2014 Vivek Nagar. All rights reserved.
//

import SceneKit
import QuartzCore

class SkinnedCharacter : SCNNode {
    var mainSkeleton:SCNNode!
    var animationsDict = Dictionary<String, CAAnimation>()

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(rootNode:SCNNode) {
        super.init()

        //print("Root node name in scene:\(rootNode.name)")

        rootNode.enumerateChildNodesUsingBlock({
            child, stop in
            // do something with node or stop
            print("Child node name:\(child.name)")
            if let _ = child.skinner {
                self.mainSkeleton = child.skinner!.skeleton
                //print("Main skeleton name: \(self.mainSkeleton.name)")
                stop.memory = true
                self.addChildNode(child.skinner!.skeleton!)
            }
        })

        rootNode.enumerateChildNodesUsingBlock({
            child, stop in
            // do something with node or stop
            if let _ = child.geometry {
                //print("Child node with geometry name:\(child.name)")
                self.addChildNode(child)
            }
        })

    }

    func cachedAnimationForKey(key:String) -> CAAnimation! {
        return animationsDict[key]
    }

    class func loadAnimationNamed(animationName:String, fromSceneNamed sceneName:String, withSkeletonNode skeletonNode:String) -> CAAnimation!
    {
        var animation:CAAnimation!

        //Load the animation
        let scene = SCNScene(named: sceneName)

        //Grab the node and its animation
        if let node = scene!.rootNode.childNodeWithName(skeletonNode, recursively: true) {
            animation = node.animationForKey(animationName)
            if(animation == nil) {
                print("No animation for key \(animationName)", terminator: "")
                return nil
            }
        } else {
            return nil
        }
   
        // Blend animations for smoother transitions
        animation.fadeInDuration = 0.3
        animation.fadeOutDuration = 0.3

        return animation;


    }
    func loadAndCacheAnimation(daeFile:String, withSkeletonNode skeletonNode:String, withName name:String, forKey key:String) -> CAAnimation
    {

        let anim = self.dynamicType.loadAnimationNamed(name, fromSceneNamed:daeFile, withSkeletonNode:skeletonNode)

        if ((anim) != nil) {
            self.animationsDict[key] = anim
            anim.delegate = self;
        }
        return anim;
    }
   
    func loadAndCacheAnimation(daeFile:String, withSkeletonNode skeletonNode:String, forKey key:String) -> CAAnimation
    {
        return loadAndCacheAnimation(daeFile, withSkeletonNode:skeletonNode, withName:key, forKey:key)
    }
   
    func chainAnimation(firstKey:String, secondKey:String)
    {
        chainAnimation(firstKey, secondKey: secondKey, fadeTime: 0.85)
    }
   
    func chainAnimation(firstKey:String, secondKey:String, fadeTime:CGFloat)
    {
        let firstAnim = self.cachedAnimationForKey(firstKey)
        let secondAnim = self.cachedAnimationForKey(secondKey)
        if (firstAnim == nil || secondAnim == nil) {
            return
        }

        //Need to fill in rest of logic
    }
    
    /*
    func update(deltaTime: NSTimeInterval) {
        print("Subclasses need to implement update", appendNewline: false)
    }
    
    func isStatic() -> Bool {
        return false
    }
    
    func getID() -> String {
        return "SkinnedCharacter"
    }
    */
}

