//
//  MovingGameObject.swift
//  AIExplorer
//
//  Created by Vivek Nagar on 8/8/15.
//  Copyright © 2015 Vivek Nagar. All rights reserved.
//

import SceneKit

protocol MovingGameObject : GameObject  {
    func getPosition() -> SCNVector3
    func getVelocity() -> SCNVector3
    // A normalized vector describing the direction of the object
    func getHeading() -> SCNVector3
    // A vector perpendicular to the heading
    func getPerp() -> SCNVector3
    
    func getMass() -> Float
    func getMaxSpeed() -> Float
    func getMaxForce() -> Float
    //turn rate in radians per sec
    func getMaxTurnRate() -> Float
    
    func getHealth() -> Float
    
}
