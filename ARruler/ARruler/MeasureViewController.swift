//
//  MeasureViewController.swift
//  ARruler
//
//  Created by Jakob Dozier on 5/7/18.
//  Copyright © 2018 Jakob Dozier. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import LBTAComponents

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // Main storyboard connections
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var updateUserLabel: UILabel!
    
    var session = ARSession()
    
    var configuration = ARWorldTrackingConfiguration()
    
    var vectorZero = SCNVector3()
    var startSphere = SCNVector3()
    var endSphere = SCNVector3()
    
    var lines: [Line] = []
    var currentLine: Line?
    
    var tempInch: String = ""
    var tempCenti: String = ""
    var tempMeter: String = ""
    
    var isMeasuring = false
    var firstTap = false
    var secondTap = false
    var isFirst = true
    
    // Overrides the viewDidLoad function ViewController inherits from UIViewController
    override func viewDidLoad() {
        // Calls UIViewController's viewDidLoad function
        super.viewDidLoad()
        // Runs the setupScene
        setUpScene()
        // Enables yellow dots while running the application
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        // Detects horizontal planes
        configuration.planeDetection = .horizontal
    }
    
    // Overrides the viewWillAppear function ViewController inherits from UIViewController
    override func viewWillAppear(_ animated: Bool) {
        // Calls UIViewController's viewWillAppear function
        super.viewWillAppear(animated)
        //
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    // Overrides the viewWillDisappear function ViewController inherits from UIViewController
    override func viewWillDisappear(_ animated: Bool) {
        // Calls UIViewController's viewWillDisappear function
        super.viewWillDisappear(animated)
        // Pauses the current session
        session.pause()
    }
    
    // Creates the start button
    let startButtonWidth = ScreenSize.width * 0.1
    lazy var startButton: UIButton = {
        var button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "startButton").withRenderingMode(.alwaysTemplate) ,for: .normal)
        button.tintColor = UIColor.green
        button.layer.cornerRadius = startButtonWidth * 0.5
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(handleStartButtonTapped), for: .touchUpInside)
        button.isHidden = false
        return button
    }()
    
    // Creates the start button text
    let startButtonTextWidth = ScreenSize.width * 0.1
    lazy var startButtonText: UIButton = {
        var button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "startButtonText").withRenderingMode(.alwaysTemplate) ,for: .normal)
        button.tintColor = UIColor.black
        button.layer.cornerRadius = startButtonWidth * 0.5
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(handleStartButtonTapped), for: .touchUpInside)
        button.isHidden = false
        return button
    }()
    
    // Tracks when the start button is tapped
    @objc func handleStartButtonTapped() {
        print("Start button tapped")
        resetValues()
        startButton.isHidden = true
        startButtonText.isHidden = true
        stopButton.isHidden = false
        stopButtonText.isHidden = false
        print("first tap")
        isMeasuring = true
        //
        for line in (self.lines) {
            print("remove parent node")
            line.removeFromParentNode()
        }
        lines.removeAll()
        firstTap = true
        isFirst = false
        updateUserLabel.text = "Tap red button to stop measuring"
    }
    
    // Creates the stop button
    let stopButtonWidth = ScreenSize.width * 0.1
    lazy var stopButton: UIButton = {
        var button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "stopButton").withRenderingMode(.alwaysTemplate) ,for: .normal)
        button.tintColor = UIColor.red
        button.layer.cornerRadius = stopButtonWidth * 0.5
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(handleStopButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    // Creates the stop button text
    let stopButtonTextWidth = ScreenSize.width * 0.1
    lazy var stopButtonText: UIButton = {
        var button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "stopButtonText").withRenderingMode(.alwaysTemplate) ,for: .normal)
        button.tintColor = UIColor.black
        button.layer.cornerRadius = stopButtonTextWidth * 0.5
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(handleStopButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    // Tracks when the stop button is tapped
    @objc func handleStopButtonTapped() {
        print("Stop button tapped")
        startButton.isHidden = false
        startButtonText.isHidden = false
        stopButton.isHidden = true
        stopButtonText.isHidden = true
        print("second tap")
        isMeasuring = true
        //
        if let line = currentLine {
            lines.append(line)
            currentLine = nil
        }
        secondTap = true
        self.updateUserLabel.text = "Tap green button to start measuring"
    }
    
    // Creates the plus in the center of the screen
    let centerImageView: UIImageView = {
        let view = UIImageView()
        view.image = #imageLiteral(resourceName: "center")
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    // Creates the distance label for inches
    let distanceInchLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = UIColor.black
        label.text = "Distance: 0.00 inches"
        return label
    }()
    
    // Creates the distance label for centimeters
    let distanceCentiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = UIColor.black
        label.text = "Distance: 0.00 centimeters"
        return label
    }()
    
    // Creates the distance label for meters
    let distanceMeterLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = UIColor.black
        label.text = "Distance: 0.00 meters"
        return label
    }()
    
    //
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        DispatchQueue.main.async {
            // Sets the variable worldPosition to the position in the real world
            guard let worldPosition = self.sceneView.realWorldVector(screenPosition: self.view.center) else {return}
            
            if self.lines.isEmpty {
                if self.isFirst == true {
                    self.updateUserLabel.text = "Tap green button to start measuring"
                }
                self.loading.isHidden = true
            }
            self.loading.stopAnimating()
            if self.isMeasuring {
                if self.startSphere == self.vectorZero {
                    self.startSphere = worldPosition
                    self.currentLine = Line(sceneView: self.sceneView, startVector: self.startSphere)
                }
                self.endSphere = worldPosition
                self.currentLine?.update(to: self.endSphere)
            }
            // Gets the distance in inches from the line class and updates the distance in the inches label
            self.tempInch = (self.currentLine?.inchDistance(to: self.endSphere) ?? self.distanceInchLabel.text!)
            self.distanceInchLabel.text = self.tempInch
            
            // Gets the distance in centimeters from the line class and updates the distance in the centimeters label
            self.tempCenti = (self.currentLine?.centimeterDistance(to: self.endSphere) ?? self.distanceCentiLabel.text!)
            self.distanceCentiLabel.text = self.tempCenti
            
            // Gets the distance in meters from the line class and updates the distance in the meters label
            self.tempMeter = (self.currentLine?.meterDistance(to: self.endSphere) ?? self.distanceMeterLabel.text!)
            self.distanceMeterLabel.text = self.tempMeter
        }
    }
    
    // Initializes the scene when the app is opened
    func setUpScene() {
        sceneView?.delegate = self
        sceneView?.session = session
        loading?.startAnimating()
        updateUserLabel?.text = "Detecting the world..."
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        resetValues()
        
        // Adds the plus to the scene and places it in the middle of the screen
        view.addSubview(centerImageView)
        centerImageView.anchorCenterSuperview()
        centerImageView.anchor(nil, left: nil, bottom: nil, right: nil, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
        
        // Adds the distance in inches label to the scene and places it to the top of the screen
        view.addSubview(distanceInchLabel)
        distanceInchLabel.anchorCenterXToSuperview(constant: 0)
        distanceInchLabel.anchorCenterYToSuperview(constant: -625)
        
        // Adds the distance in centimeters label to the scene and places it below the distance in inches label
        view.addSubview(distanceCentiLabel)
        distanceCentiLabel.anchorCenterXToSuperview(constant: 0)
        distanceCentiLabel.anchorCenterYToSuperview(constant: -605)
        
        // Adds the distance in meters label to the scene and places it below the distance in centimeters label
        view.addSubview(distanceMeterLabel)
        distanceMeterLabel.anchorCenterXToSuperview(constant: 0)
        distanceMeterLabel.anchorCenterYToSuperview(constant: -585)
        
        // Adds the start button to the scene and places it in the bottom right corner of the screen
        view.addSubview(startButton)
        startButton.anchor(nil, left: nil, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.safeAreaLayoutGuide.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 24, rightConstant: 48, widthConstant: startButtonWidth, heightConstant: startButtonWidth)
        
        // Adds the start button text to the scene and places it in the bottom right corner of the screen
        view.addSubview(startButtonText)
        startButtonText.anchor(nil, left: nil, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.safeAreaLayoutGuide.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 24, rightConstant: 48, widthConstant: startButtonTextWidth, heightConstant: startButtonTextWidth)
        
        // Adds the stop button to the scene and places it in the bottom right corner of the screen
        view.addSubview(stopButton)
        stopButton.anchor(nil, left: nil, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.safeAreaLayoutGuide.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 24, rightConstant: 48, widthConstant: stopButtonWidth, heightConstant: stopButtonWidth)
        
        // Adds the stop button text to the scene and places it in the bottom right corner of the screen
        view.addSubview(stopButtonText)
        stopButtonText.anchor(nil, left: nil, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.safeAreaLayoutGuide.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 24, rightConstant: 48, widthConstant: stopButtonTextWidth, heightConstant: stopButtonTextWidth)
    }
    
    // Resets values when a new measurment has started
    func resetValues() {
        isMeasuring = false
        startSphere = SCNVector3()
        endSphere = SCNVector3()
        firstTap = false
        secondTap = false
    }
}

// Adds a new function to the ARSCNView
extension ARSCNView {
    // Allows a sphere to be placed on a detected plane
    func realWorldVector(screenPosition: CGPoint) -> SCNVector3? {
        let results = self.hitTest(screenPosition, types: [.featurePoint])
        guard let result = results.first else {return nil}
        return SCNVector3.positionFromTransform(result.worldTransform)
    }
}















