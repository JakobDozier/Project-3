//
//  Line.swift
//  MeasureApp
//
//  Created by Jakob Dozier on 4/27/18.
//  Copyright © 2018 Jakob Dozier. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import LBTAComponents

final class Line {
    var startNode: SCNNode!
    var endNode: SCNNode!
    var lineNode: SCNNode?
    
    let sceneView: ARSCNView!
    let startVector: SCNVector3!
    
    init(sceneView: ARSCNView, startVector: SCNVector3) {
        self.sceneView = sceneView
        self.startVector = startVector
        
        let sphere = SCNNode()
        sphere.geometry = SCNSphere(radius: 0.0015)
        sphere.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        sphere.geometry?.firstMaterial?.lightingModel = .constant
        sphere.geometry?.firstMaterial?.isDoubleSided = true
        
        startNode = SCNNode(geometry: sphere.geometry)
        startNode.position = startVector
        sceneView.scene.rootNode.addChildNode(startNode)
        
        endNode = SCNNode(geometry: sphere.geometry)
    }
    
    func update(to vector: SCNVector3) {
        lineNode?.removeFromParentNode()
        lineNode = startVector.line(to: vector, color: UIColor.red)
        sceneView.scene.rootNode.addChildNode(lineNode!)
        
        endNode.position = vector
        if endNode.parent == nil {
            sceneView?.scene.rootNode.addChildNode(endNode)
        }
    }
    
    // Converts the distance from meters to inches
    func inchDistance(to vector: SCNVector3) -> String {
        return String(format: "Distance: %.2f inches", startVector.distance(from: vector) * 39.37007874)
    }
    
    // Converts the distance from meters to centimeters
    func centimeterDistance(to vector: SCNVector3) -> String {
        return String(format: "Distance: %.2f centimeters", startVector.distance(from: vector) * 100.0)
    }
    
    // Normal meter distance
    func meterDistance(to vector: SCNVector3) -> String {
        return String(format: "Distance %.2f meters", startVector.distance(from: vector))
    }
    
    // Removes the starting and ending sphere and the line connecting them 
    func removeFromParentNode() {
        startNode.removeFromParentNode()
        lineNode?.removeFromParentNode()
        endNode.removeFromParentNode()
    }
}


































