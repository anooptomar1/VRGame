//
//  GameUtilities.swift
//  AIExplorer
//
//  Created by Vivek Nagar on 8/4/15.
//  Copyright © 2015 Vivek Nagar. All rights reserved.
//

import SpriteKit
import SceneKit

class GameUtilities {
    class func getBoundingBox(node:SCNNode) -> SCNBox {
        
        var min:SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)
        var max:SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)
        
        node.getBoundingBoxMin(&min, max: &max)
        
        let box = SCNBox(width: CGFloat(max.x-min.x), height: CGFloat(max.y-min.y), length: CGFloat(max.z-min.z), chamferRadius: 0.0)
        return box
    }
    
    class func createDebugBox(scene:SCNScene, box:SCNBox, position:SCNVector3, color:SKColor, rotation:SCNVector4) {
        let geometry = box
        geometry.firstMaterial!.diffuse.contents = color
        let node = SCNNode(geometry: geometry)
        node.position = position
        node.rotation = rotation
        scene.rootNode.addChildNode(node)
    }


    class func getAngleFromDirection(currentPosition:SCNVector3, target:SCNVector3) -> Float
    {
        let delX = target.x - currentPosition.x;
        let delZ = target.z - currentPosition.z;
        let angleInRadians =  atan2(delX, delZ);
        
        return Float(angleInRadians)
    }

}