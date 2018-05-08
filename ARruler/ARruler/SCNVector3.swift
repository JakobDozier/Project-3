//
//  SCNVector3.swift
//  ARruler
//
//  Created by Jakob Dozier on 5/7/18.
//  Copyright © 2018 Jakob Dozier. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import LBTAComponents

extension SCNVector3 {
    
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    // Calculates the distance between two points
    func distance(from vector: SCNVector3) -> Float {
        let distanceX = self.x - vector.x
        let distanceY = self.y - vector.y
        let distanceZ = self.z - vector.z
        
        return sqrt((distanceX * distanceX) + (distanceY * distanceY) + (distanceZ * distanceZ))
    }
    
    // Creates the line that is between the two spheres
    func line(to vector: SCNVector3) -> SCNNode {
        let indices: [Int32] = [0, 1]
        let geometry = SCNGeometry(sources: [SCNGeometrySource(vertices: [self, vector])], elements: [SCNGeometryElement(indices: indices, primitiveType: .line)])
        geometry.firstMaterial?.diffuse.contents = UIColor.red
        let lineNode = SCNNode(geometry: geometry)
        return lineNode
    }
}
// Allows two SCNVector3 operands to be compared with Binary operator '=='
extension SCNVector3: Equatable {
    public static func ==(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return(lhs.x == rhs.x) && (lhs.y == rhs.y) && (lhs.z == rhs.z)
    }
}


