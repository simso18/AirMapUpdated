//
//  ViewController.swift
//  AirMapUpdated
//
//  Created by laptop on 12/04/2022.
//

// restart ar kit sound
// start writing -> diagram
// THURSDAY

import SwiftUI
import UIKit
import CoreHaptics
import CoreMotion
import CoreGraphics
import ARKit
import RealityKit
import Foundation
import Combine
import CoreLocation
import MapKit
import AVFoundation
import AVKit
import Speech


class ViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate, CLLocationManagerDelegate, SFSpeechRecognizerDelegate{
    var engine: CHHapticEngine!
    private var colorState: UIColor?
    var audioEngine = AVAudioEngine()
    var finResults : Response!
    var player: CHHapticAdvancedPatternPlayer!
    var supportsHaptics:Bool = false
    var supportsAR: Bool = false
    var supportsSpeech: Bool = false
    var extractor : PixelExtractor!
    var imgSaver = ImageSaveObject()
    var locX : Int = 0
    var locY : Int = 0
    var imgWidth : CGFloat!
    var imgHeight : CGFloat!
    var imgWidthScale : CGFloat!
    var imgHeightScale : CGFloat!
//    var cameraOffsetX : Float = 0
//    var cameraOffsetY : Float = 0
    var camPosition : simd_float4!
    let locationManager = CLLocationManager()
    private let speechRec = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recTask: SFSpeechRecognitionTask?
    let motion = CMMotionManager()
    var timer = 0
    var zoom : Double = 1
    var zoomLevel : Int = 1
    var currLocLat : CLLocationDegrees = 51.48972
    var currLocLon : CLLocationDegrees = -0.13034
    var currHeading : CLLocationDegrees = 0
    var explore : Bool = false
    var currentLandmark : String = "Nothing"
    var oldPoint : CGPoint = CGPoint(x: 0, y: 0)
    var lonConstant : Double = 0.0036
    var latConstant : Double = 0.002
    var speechInput : String = ""
    var transport : Bool = true
    var roads : Bool = true
    var pointsOfInterest : Bool = true
    var park : Bool = true
    var zoomLocX : Int = 0
    var zoomLocY : Int = 0
    var homeBool : Bool = false
    var welcomeBool: Bool = true
    let synth = AVSpeechSynthesizer()
    var nextFeatureState: Int = 0
    //var coordConverter : CLGeocoder
//    var speechDemandMode : Bool = true
    var ori : String = "north"
    //var track : []
    @IBOutlet weak var newView: ARView!
    @IBOutlet var drawView: UIImageView!
    var checkAR = ARPositionalTrackingConfiguration()
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 863, height: 863))
    let zoomHash = [1 : [200, 5],
                    2 : [100, 2],
                    3 : [50 , 1]
    ]
    var colorHash = [UIColor(red: 0, green: 0, blue: 0, alpha: 1): "Black",
                     UIColor(red: 0, green: 0, blue: 0, alpha: 0): "White",
                     UIColor(red: 255, green: 255, blue: 255, alpha: 1): "White",
                     UIColor(red: 255, green: 255, blue: 0, alpha: 1): "Yellow",
                     UIColor(red: 255, green: 192, blue: 0, alpha: 1): "Orange",
                     UIColor(red: 0, green: 176, blue: 240, alpha: 1): "Blue",
                     UIColor(red: 255, green: 0, blue: 1, alpha: 1): "Red",
                     UIColor(red: 146, green: 208, blue: 80, alpha: 1): "Green",
                     UIColor(red: 112, green: 48, blue: 160, alpha: 1): "Purple",
    ]
    var nameColour : [String : UIColor] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        let newImg = UIImage(named: "AirMapTitle")!
        drawView.image = newImg
        //let newImg = drawMap()
        imgWidthScale = newImg.size.width / 0.4
        imgHeightScale = newImg.size.height / 0.4
        imgWidth = newImg.size.width
        imgHeight = newImg.size.height
        extractor = PixelExtractor(img: newImg.cgImage!)
        
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressView(_:)))
        longPress.minimumPressDuration = 2.0
        view.addGestureRecognizer(longPress)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(didSingleTapView(_:)))
        view.addGestureRecognizer(singleTap)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(didDoubleTapView(_:)))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        let pinchScreen = UIPinchGestureRecognizer(target: self, action: #selector(didPinchView(_:)))
        view.addGestureRecognizer(pinchScreen)
        singleTap.require(toFail: doubleTap)
        newView.session.delegate = self
        supportsAR = ARConfiguration.isSupported
        checkAR.planeDetection = [.horizontal, .vertical]
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            locationManager.headingFilter = 30.0
            locationManager.startUpdatingHeading()
        }
        speechRec.delegate = self
        welcome()
    }
    
    func welcome(){
        if nextFeatureState == 0{
            let welcomeString = """
            Welcome to the Air Map Application. I will now take you through the verbal user guide.  First, let's go through the basic app use and a key for the different vibrations you can experience. To move onto the next feature or page, please double tap anywhere on the screen.
            """
            speech(inputString: welcomeString)
        }
        if nextFeatureState == 1{
            newView.session.run(checkAR)
            drawBoundary()
            let boundaryString = """
            Move your smartphone up and down then side to side in the space in front of you. At the furthest point of your movement, you will feel a vibration. This can be felt all the way round and is the boundary or frame of the map. When you double tap the screen, all vibrations will stop while a new map loads around your current position. When the new map is available, you will feel the boundary vibration pattern again.
            """
            speech(inputString: boundaryString)
        }
        if nextFeatureState == 2{
            let basicRoadString = """
            Move your smartphone up and you should feel a different but continuous vibration. This represents a road. Follow this road vibration upwards until you feel a new vibration. This represents a junction of roads. Move your smartphone around this area to find and trace the other roads. You can tap once on the screen while hovering over a feature vibration to hear its name. Try it.
            """
            drawBasicMap(roadBasic: true, transportBasic: false, tourBasic: false, parkBasic: false)
            speech(inputString: basicRoadString)
        }
        if nextFeatureState == 3{
            let basicTransportString = """
            Move your smartphone to the top left corner. You should feel a new vibration that is different to the boundary. This represents a transport hub such as a train station or bus stop. You can tap once on the screen while hovering over a feature vibration to hear its name. Try it.
            """
            drawBasicMap(roadBasic: false, transportBasic: true, tourBasic: false, parkBasic: false)
            speech(inputString: basicTransportString)
        }
        if nextFeatureState == 4{
            let basicTourString = """
            Move your smartphone to the top right corner. You should feel a new vibration that is different to the boundary. This represents a point of interest such as a museum. You can tap once on the screen while hovering over a feature vibration to hear its name. Try it.
            """
            drawBasicMap(roadBasic: false, transportBasic: false, tourBasic: true, parkBasic: false)
            speech(inputString: basicTourString)
        }
        if nextFeatureState == 5{
            let basicParkString = """
            Move your smartphone to the bottom left corner. You should feel a new vibration that is different to the boundary. This represents a green space such as a park. You can tap once on the screen while hovering over a feature vibration to hear its name. Try it.
            """
            drawBasicMap(roadBasic: false, transportBasic: false, tourBasic: false, parkBasic: true)
            speech(inputString: basicParkString)
        }
        if nextFeatureState == 6{
            let finalString = """
            When you're ready to start exploring the map around you, double tap the screen.
            """
            drawBasicMap(roadBasic: true, transportBasic: true, tourBasic: true, parkBasic: true)
            speech(inputString: finalString)
            welcomeBool = false
            
        }

    }
    
    func drawBoundary(){
        newView.session.pause()
        let imgNew = renderer.image { (context) in
            UIColor.white.setFill()
            context.fill(CGRect(x: 1, y: 1, width: renderer.format.bounds.width, height: renderer.format.bounds.height), blendMode: .destinationAtop)
            UIColor.yellow.setStroke()
            context.cgContext.setLineWidth(20.0)
              context.stroke(renderer.format.bounds)
        }
        drawView.image = imgNew
        //let imgNew = UIImage(named: "bitmap1")!
        extractor = PixelExtractor(img: imgNew.cgImage!)
        imgWidthScale = CGFloat(imgNew.cgImage!.width) / 0.3
        imgHeightScale = (CGFloat(imgNew.cgImage!.height) - 1) / 0.2
        imgWidth = CGFloat(imgNew.cgImage!.width)
        imgHeight = CGFloat(imgNew.cgImage!.height) - 1
        newView.session.run(checkAR, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func drawBasicMap(roadBasic : Bool, transportBasic: Bool, tourBasic: Bool, parkBasic : Bool){
        newView.session.pause()
        let imgNew = renderer.image { (context) in
            var rgbRoad = 0.004
            var rgbTransport = 0.004
            var rgbTour = 0.004
            var rgbPark = 0.004
            nameColour = [:]
            if roadBasic == true{
                var counter = 1
                let basicRoads : [[CGPoint]] = [[CGPoint(x: 0, y:431), CGPoint(x: 862, y:431)], [CGPoint(x: 431, y:0), CGPoint(x: 431, y:862)]]
                for element in basicRoads{
                    let roadCol = UIColor(red: rgbRoad, green: rgbRoad, blue: rgbRoad, alpha: 1.0)
                        //col = UIColor.ora
                    nameColour["Example Road " + String(counter)] = roadCol
                    rgbRoad = rgbRoad + 0.004

                    //context.cgContext.setBlendMode(CGBlendMode.destinationAtop)
                    context.cgContext.setBlendMode(CGBlendMode.multiply)
                    context.cgContext.addLines(between: element)
                    context.cgContext.setLineWidth(50.0)
                    roadCol.setStroke()
                    context.cgContext.strokePath()
                    counter = counter + 1
                }
            }

            if transportBasic == true{
                let busCol = UIColor(red: 1.0, green: rgbTransport, blue: 0, alpha: 1.0)
                nameColour["Example Bus Stop"] = busCol
                let rect = CGRect(x: 0, y: 0, width: 420, height: 420)
                busCol.setFill()
                context.fill(rect)
            }
            if tourBasic == true{
                let tourCol = UIColor(red: rgbTour, green: 0, blue: 1, alpha: 1.0)
                nameColour["Example Point of Interest"] = tourCol
                let rect = CGRect(x: 440, y: 0, width: 420, height: 420)
                tourCol.setFill()
                context.fill(rect)
            }
            if parkBasic == true{
                let parkCol = UIColor(red: 0, green: 1, blue: rgbPark, alpha: 1.0)
                nameColour["Example Green Space"] = parkCol
                let rect = CGRect(x: 0, y: 440, width: 420, height: 420)
                parkCol.setFill()
                context.fill(rect)
            }
            UIColor.white.setFill()
            context.fill(CGRect(x: 1, y: 1, width: renderer.format.bounds.width, height: renderer.format.bounds.height), blendMode: .destinationAtop)
            UIColor.yellow.setStroke()
            context.cgContext.setLineWidth(20.0)
            context.stroke(renderer.format.bounds)
        }
        drawView.image = imgNew
        //let imgNew = UIImage(named: "bitmap1")!
        extractor = PixelExtractor(img: imgNew.cgImage!)
        imgWidthScale = CGFloat(imgNew.cgImage!.width) / 0.3
        imgHeightScale = (CGFloat(imgNew.cgImage!.height) - 1) / 0.2
        imgWidth = CGFloat(imgNew.cgImage!.width)
        imgHeight = CGFloat(imgNew.cgImage!.height) - 1
        newView.session.run(checkAR, options: [.resetTracking, .removeExistingAnchors])
    }
    
    
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if nextFeatureState != 0{
            camPosition = newView.session.currentFrame?.camera.transform.columns.3
            if ori == "north"{
                locX = Int(CGFloat(camPosition!.x)*imgWidthScale + imgWidth/2)
                locY = Int(imgHeight - (CGFloat(camPosition!.y)*imgHeightScale))
            }
            else if ori == "south"{
                locX = Int(CGFloat(camPosition!.x)*imgWidthScale + imgWidth/2)
                locY = -1 * Int(CGFloat(camPosition!.y)*imgHeightScale)
            }
            else if ori == "west"{
                locX = Int(imgWidth + CGFloat(camPosition!.x)*imgWidthScale)
                locY = Int(imgHeight/2 - (CGFloat(camPosition!.y)*imgHeightScale))
            }
            else if ori == "east"{
                locX = Int(CGFloat(camPosition!.x)*imgWidthScale)
                locY = Int(imgHeight/2 - (CGFloat(camPosition!.y)*imgHeightScale))
            }

            if (locY < 0){
                locY = 0
            }
            else if (locY > Int(imgHeight)){
                locY = Int(imgHeight)
            }
            if (locX < 0){
                locX = 0
            }
            else if (locX > Int(imgWidth)){
                locX = Int(imgWidth)
            }
            
            if timer == 50{
                let outImage = drawOnMap(inputImg: drawView.image!, newPoint: CGPoint(x: Int(locX/3), y: Int(863 - locY/3)), line : true)
                drawView.image = outImage
                oldPoint = CGPoint(x: locX/3, y: 863 - locY/3)
                timer = 0
            }
            timer = timer + 1
            let color = extractor.color_at(x:locX, y:locY)
            print(color)
            if (color != colorState){
                colorState = color
                hapticFeedback(color: color)
            }
            if welcomeBool == false{
                if ori == "north" && locX < 1300 && locX > 1290 && locY <= 2588 && locY > 2578{
                    if homeBool == false {
                        speech(inputString: "Home")
                        homeBool = true
                    }
                }
                else if ori == "south" && locX < 1300 && locX > 1290 && locY < 10 && locY >= 0{
                    if homeBool == false {
                        speech(inputString: "Home")
                        homeBool = true
                    }
                }
                else if ori == "west" && locX <= 2588 && locX > 2578 && locY < 1300 && locY > 1290{
                    if homeBool == false {
                        speech(inputString: "Home")
                        homeBool = true
                    }
                }
                else if ori == "east" && locX < 10 && locX >= 0 && locY < 1300 && locY > 1290{
                    if homeBool == false {
                        speech(inputString: "Home")
                        homeBool = true
                    }
                }
                else if homeBool == true {
                    homeBool = false
                }
            }
        }
    }
    
    
    func startListen(){
        recTask?.cancel()
        recTask = nil
        let audioSession = AVAudioSession.sharedInstance()
        do{
            try audioSession.setCategory(.playAndRecord)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch{
            print("failed to load audio session: \(error.localizedDescription)")
        }
        let inputNode = audioEngine.inputNode

        recRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recRequestNew = recRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recRequestNew.shouldReportPartialResults = true
        recTask = speechRec.recognitionTask(with: recRequestNew) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.speechInput = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recRequest = nil
                self.recTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recRequest?.append(buffer)
        }

        audioEngine.prepare()
        do{
            speech(inputString: "Listening")
            print("listening")
            try audioEngine.start()
        } catch{
            print("failed to start audio engine: \(error.localizedDescription)")
        }
        
        
    }
    
    func stopListen(){
        audioEngine.stop()
        recRequest?.endAudio()
        speech(inputString: "Stopped Listening")
        print(speechInput)
        voiceCommands(inputString: speechInput)
    }
    
    func voiceCommands (inputString : String){
        if inputString == "Remove transport"{
            transport = false
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
        }
        else if inputString == "Add transport"{
            transport = true
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
        }
        else if inputString == "Remove road"{
            roads = false
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
        }
        else if inputString == "Add road"{
            transport = true
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
        }
        else if inputString == "Remove park"{
            park = false
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
        }
        else if inputString == "Add park"{
            park = true
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
        }
        else if inputString == "Remove interest"{
            pointsOfInterest = false
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
        }
        else if inputString == "Add interest"{
            pointsOfInterest = true
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
        }
        else if inputString == "Zoom in"{
            zoomIn()
        }
        else if inputString == "Zoom out"{
            zoomOut()
        }
        else if inputString == "Home"{
            zoom = 1
            zoomLevel = 1
            ori = "north"
            currHeading = locationManager.heading!.trueHeading
//            guard let locValue: CLLocationCoordinate2D = self.locationManager.location?.coordinate else { return }
//            self.currLocLat = locValue.latitude
//            self.currLocLon = locValue.longitude
            self.currLocLat = 51.4948
            self.currLocLon = -0.174
            postAuth()
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
        }
//        else if inputString.contains("address"){
//            let addressString = inputString.replacingOccurrences(of: "address ", with: "")
//            coordConverter.geocodeAddressString(addressString, completionHandler: CLGeocodeCompletionHandler)
//        }
    }
    
    
    func speech(inputString : String){
        let utterance = AVSpeechUtterance(string: inputString)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        if synth.isSpeaking{
            let tempBool = synth.stopSpeaking(at: .word)
        }
        synth.speak(utterance)

    }
    
    func xyRotation(inLon: Double, inLat: Double, theta: CLLocationDegrees)-> (Double, Double){
            var outLon = inLon * CoreGraphics.cos(theta * Double.pi / 180) - inLat * CoreGraphics.sin(theta * Double.pi / 180)
            var outLat = inLon * CoreGraphics.sin(theta * Double.pi / 180) + inLat * CoreGraphics.cos(theta * Double.pi / 180)
            return (outLon, outLat)
    }
    
    func postAuth(){
//        let latSouth = self.currLocLat
//        let latNorth = self.currLocLat + latConstant
//        let lonEast = self.currLocLon + lonConstant/2
//        let lonWest = self.currLocLon - lonConstant/2
        let updatedHeading = 360 - currHeading
        var (pointAx, pointAy) = xyRotation(inLon: (-1 * lonConstant/2), inLat: 0.0, theta: updatedHeading)
        var (pointBx, pointBy) = xyRotation(inLon: (-1 * lonConstant/2), inLat: latConstant, theta: updatedHeading)
        var (pointCx, pointCy) = xyRotation(inLon: lonConstant/2, inLat: latConstant, theta: updatedHeading)
        var (pointDx, pointDy) = xyRotation(inLon: lonConstant/2, inLat: 0.0, theta: updatedHeading)
        
        var longSide = lonConstant / (abs(latConstant*CoreGraphics.sin(updatedHeading * Double.pi / 180) + lonConstant * CoreGraphics.cos(updatedHeading * Double.pi / 180)))
        var shortSide = latConstant / (abs(latConstant*CoreGraphics.cos(updatedHeading * Double.pi / 180) + lonConstant * CoreGraphics.sin(updatedHeading * Double.pi / 180)))
        print(updatedHeading)

        pointBx = pointAx + ((pointBx-pointAx) * longSide)
        pointBy = pointAy + ((pointBy-pointAy) * longSide)
        pointCx = pointDx + ((pointCx-pointDx) * longSide)
        pointCy = pointDy + ((pointCy-pointDy) * longSide)
//
//
        let pointBxTemp = 0.5 * ((pointCx+pointBx) - (pointCx-pointBx) * shortSide)
        let pointByTemp = 0.5 * ((pointCy+pointBy) - (pointCy-pointBy) * shortSide)
        let pointCxTemp = 0.5 * ((pointCx+pointBx) + (pointCx-pointBx) * shortSide)
        let pointCyTemp = 0.5 * ((pointCy+pointBy) + (pointCy-pointBy) * shortSide)
        let pointDxTemp = 0.5 * ((pointDx+pointAx) + (pointDx-pointAx) * shortSide)
        let pointDyTemp = 0.5 * ((pointDy+pointAy) + (pointDy-pointAy) * shortSide)
        let pointAxTemp = 0.5 * ((pointDx+pointAx) - (pointDx-pointAx) * shortSide)
        let pointAyTemp = 0.5 * ((pointDy+pointAy) - (pointDy-pointAy) * shortSide)
        
        pointBx = pointBxTemp + currLocLon
        pointBy = pointByTemp + currLocLat
        pointCx = pointCxTemp + currLocLon
        pointCy = pointCyTemp + currLocLat
        pointDx = pointDxTemp + currLocLon
        pointDy = pointDyTemp + currLocLat
        pointAx = pointAxTemp + currLocLon
        pointAy = pointAyTemp + currLocLat
        
//        let bbox = "(" + String(latSouth) + "," + String(lonWest) + "," + String(latNorth) + "," + String(lonEast) + ");"
        let poly = "(poly:\"" + String(pointAy) + " " + String(pointAx) + " " + String(pointBy) + " " + String(pointBx) + " " + String(pointCy) + " " + String(pointCx) + " " + String(pointDy) + " " + String(pointDx) + "\");"
        //let bbox = "(51.4935985386003,-0.17555862665176392,51.494687332271795,-0.1736730337142944)"
        //print(bbox)
        let bodyStart = """
                [out:json][timeout:25];(
        """
        let bodyRoad = """
            way[highway~"^(motorway|motorway_link|trunk|trunk_link|primary|secondary|tertiary|unclassified|residential|living_street)$"]["name"]
        """
        let bodyBus = """
            node["highway"="bus_stop"]["name"]
        """
        let bodyTourism = """
            way[tourism~"^(attraction|museum|gallery|aquarium|theme_park|zoo)$"]["leisure"!="park"]["name"]
        """
        let bodyTrain = """
            node["railway"="station"]["name"]
        """
        let bodyPark = """
            way["leisure"="park"]["name"]
        """
        let bodyEnd = """
            );out geom;
        """
        
        let body = bodyStart + bodyBus + poly + bodyRoad + poly + bodyTourism + poly + bodyTrain + poly + bodyPark + poly + bodyEnd
        var components = URLComponents()
        let sem = DispatchSemaphore.init(value: 0)
        newView.session.pause()
        components.scheme = "https"
        components.host = "overpass-api.de"
        components.path = "/api/interpreter"
        components.queryItems = [URLQueryItem(name: "data", value: body)]
        print(body)
        print(components.url)
        let task = URLSession.shared.dataTask(with: components.url!) { (data, response, error) in
            //defer { sem.signal() }
            guard let data = data else { return }
            do {
                let resData = try JSONDecoder().decode(Response.self, from: data)
                self.finResults = resData
               } catch let DecodingError.dataCorrupted(context) {
                   print(context)
               } catch let DecodingError.keyNotFound(key, context) {
                   print("Key '\(key)' not found:", context.debugDescription)
                   print("codingPath:", context.codingPath)
               } catch let DecodingError.valueNotFound(value, context) {
                   print("Value '\(value)' not found:", context.debugDescription)
                   print("codingPath:", context.codingPath)
               } catch let DecodingError.typeMismatch(type, context)  {
                   print("Type '\(type)' mismatch:", context.debugDescription)
                   print("codingPath:", context.codingPath)
               } catch {
                   print("error: ", error)
               }

        }
        
        task.resume()
        sem.wait()
        newView.session.run(checkAR, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func zoomIn(){
        if zoomLevel == 3{
            zoom = 4
            let zoomString = "Zoom Level " + String(3) + ", Distance" + String(200) + "meters, " + "Walking Time" + String(5) + "minutes"
            speech(inputString: zoomString)
        }
        else{
            //imgSaver.saveImage(image: drawView.image!)
            zoom = zoom*2
            zoomLevel = zoomLevel + 1
            let zoomString = "Zoom Level " + String(zoomLevel) + ", Distance" + String(zoomHash[zoomLevel]![0]) + "meters, " + "Walking Time" + String(zoomHash[zoomLevel]![1]) + "minutes"
            zoomLocX = locX
            zoomLocY = locY
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
            speech(inputString: zoomString)
        }
    }
    
    func zoomOut(){
        if zoomLevel == 1{
            zoom = 1
            let zoomString = "Zoom Level " + String(1) + ", Distance" + String(50) + "meters, " + "Walking Time" + String(1) + "minutes"
            speech(inputString: zoomString)

        }
        else{
            //imgSaver.saveImage(image: drawView.image!)
            zoom = zoom/2
            zoomLevel = zoomLevel - 1
            let zoomString = "Zoom Level " + String(zoomLevel) + ", Distance" + String(zoomHash[zoomLevel]![0]) + "meters, " + "Walking Time" + String(zoomHash[zoomLevel]![1]) + "minutes"
            zoomLocX = locX
            zoomLocY = locY
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
            speech(inputString: zoomString)
        }

    }
    
    func drawOnMap(inputImg : UIImage, newPoint : CGPoint, line : Bool) -> UIImage{
        let image = renderer.image { (context) in
            let cgImage = inputImg.cgImage!
            let rect = CGRect(x: 0, y: 0, width: 863, height: 863)
            context.cgContext.concatenate(.flipVertical(863))
            context.cgContext.draw(cgImage, in: rect)
            if line == true{
                context.cgContext.move(to: oldPoint)
                context.cgContext.addLine(to: newPoint)
                context.cgContext.setLineWidth(5.0)
                UIColor.blue.setStroke()
                context.cgContext.strokePath()
            }
            else{
                let rect = CGRect(x: newPoint.x - 20, y: newPoint.y - 20, width: 40, height: 40)
                UIColor.purple.setFill()
                context.cgContext.addEllipse(in: rect)
                context.cgContext.drawPath(using: .fill)
            }
        }
        return image
    }
        
    func drawMap() -> UIImage{
        let image = renderer.image { (context) in
            var rgbRoad = 0.004
            var rgbTransport = 0.004
            var rgbTour = 0.004
            var rgbPark = 0.004
            nameColour = [:]
            if roads == true{
                for element in self.finResults.elementsRoad {
                    var roadCol = nameColour[element.tags.name]
                    if (roadCol == nil){
                        roadCol = UIColor(red: rgbRoad, green: rgbRoad, blue: rgbRoad, alpha: 1.0)
                        //col = UIColor.ora
                        nameColour[element.tags.name] = roadCol
                        rgbRoad = rgbRoad + 0.004
                    }
                    var linePoints : [CGPoint] = []
                    for coordPair in element.geometry{
                        let (finX, finY) = drawConversion(inputLon: coordPair.lon, inputLat: coordPair.lat)
                        //if (finx >= 0) && (finy >= 0) && (finx <= 863) && (finy <= 1293){
                            linePoints.append(CGPoint(x: finX, y:finY))
                        //}
                    }
                    //context.cgContext.setBlendMode(CGBlendMode.destinationAtop)
                    context.cgContext.setBlendMode(CGBlendMode.multiply)
                    context.cgContext.addLines(between: linePoints)
                    context.cgContext.setLineWidth(50.0)
                    roadCol!.setStroke()
                    context.cgContext.strokePath()
                }
            }
            if transport == true{
                for element in self.finResults.elementsBus {
                    let newBusLabel = element.tags.name + "Bus Stop"
                    var busCol = nameColour[newBusLabel]
                    if (busCol == nil){
                        busCol = UIColor(red: 1.0, green: rgbTransport, blue: 0, alpha: 1.0)
                        nameColour[newBusLabel] = busCol
                        rgbTransport = rgbTransport + 0.004
                    }
                    let (finX, finY) = drawConversion(inputLon: element.lon, inputLat: element.lat)
                    let rect = CGRect(x: finX - 40, y: finY - 40, width: 80, height: 80)
                    //UIColor.red.setFill()
                    //context.cgContext.setBlendMode(CGBlendMode.sourceAtop)
                    busCol!.setFill()
                    context.cgContext.addEllipse(in: rect)
                    context.cgContext.drawPath(using: .fill)
                }
                for element in self.finResults.elementsTrain{
                    let newTrainLabel = element.tags.name + "Train Station"
                    var trainCol = nameColour[newTrainLabel]
                    if (trainCol == nil){
                        trainCol = UIColor(red: 1, green: rgbTransport, blue: 0, alpha: 1.0)
                        nameColour[newTrainLabel] = trainCol
                        rgbTransport = rgbTransport + 0.004
                    }
                    let (finX, finY) = drawConversion(inputLon: element.lon, inputLat: element.lat)
                    let rect = CGRect(x: finX - 60, y: finY - 60, width: 120, height: 120)
                    //UIColor.red.setFill()
                    //context.cgContext.setBlendMode(CGBlendMode.sourceAtop)
                    trainCol!.setFill()
                    context.cgContext.addEllipse(in: rect)
                    context.cgContext.drawPath(using: .fill)
                }
            }
            if pointsOfInterest == true{
                for element in self.finResults.elementsTourism {
                    var tourCol = nameColour[element.tags.name]
                    if (tourCol == nil){
                        tourCol = UIColor(red: rgbTour, green: 0, blue: 1, alpha: 1.0)
                        //col = UIColor.ora
                        nameColour[element.tags.name] = tourCol
                        rgbTour = rgbTour + 0.004
                    }
                    var linePoints : [CGPoint] = []
                    for coordPair in element.geometry{
                        let (finX, finY) = drawConversion(inputLon: coordPair.lon, inputLat: coordPair.lat)
                        
                        //if (finx >= 0) && (finy >= 0) && (finx <= 863) && (finy <= 1293){
                            linePoints.append(CGPoint(x: finX, y:finY))
                        //}
                    }
                    //context.cgContext.setBlendMode(CGBlendMode.sourceAtop)
                    context.cgContext.addLines(between: linePoints)
                    //context.cgContext.setLineWidth(50.0)
                    tourCol!.setFill()
                    context.cgContext.fillPath()
                }
            }
            if park == true{
                for element in self.finResults.elementsPark{
                    let newParkLabel = element.tags.name + "Green Space"
                    var parkCol = nameColour[newParkLabel]
                    if (parkCol == nil){
                        parkCol = UIColor(red: 0, green: 1, blue: rgbPark, alpha: 1.0)
                        //col = UIColor.ora
                        nameColour[newParkLabel] = parkCol
                        rgbPark = rgbPark + 0.004
                    }
                    var linePoints : [CGPoint] = []
                    for coordPair in element.geometry{
                        let (finX, finY) = drawConversion(inputLon: coordPair.lon, inputLat: coordPair.lat)
                        
                        //if (finx >= 0) && (finy >= 0) && (finx <= 863) && (finy <= 1293){
                            linePoints.append(CGPoint(x: finX, y:finY))
                        //}
                    }
                    //context.cgContext.setBlendMode(CGBlendMode.sourceAtop)
                    context.cgContext.addLines(between: linePoints)
                    //context.cgContext.setLineWidth(50.0)
                    parkCol!.setFill()
                    context.cgContext.fillPath()
                }
            }
            UIColor.white.setFill()
            context.fill(CGRect(x: 1, y: 1, width: renderer.format.bounds.width, height: renderer.format.bounds.height), blendMode: .destinationAtop)
            UIColor.yellow.setStroke()
            context.cgContext.setLineWidth(20.0)
              context.stroke(renderer.format.bounds)
        }
        print(nameColour)
        return image

    }
        
    func drawConversion(inputLon : Float, inputLat: Float) -> (Double, Double){
        let updatedHeading = 360 - currHeading
        var longSide = lonConstant / (abs(latConstant*CoreGraphics.sin(updatedHeading * Double.pi / 180) + lonConstant * CoreGraphics.cos(updatedHeading * Double.pi / 180)))
        var shortSide = latConstant / (abs(latConstant*CoreGraphics.cos(updatedHeading * Double.pi / 180) + lonConstant * CoreGraphics.sin(updatedHeading * Double.pi / 180)))
        let (rotatedLon, rotatedLat) = xyRotation(inLon: Double(inputLon) - currLocLon, inLat: Double(inputLat) - currLocLat, theta: currHeading)
        var finx = zoom * (rotatedLon + lonConstant*shortSide/2) * (863/(lonConstant*shortSide))
        var finy = zoom * (863 - (rotatedLat) * (863/(latConstant*longSide)))
        if zoom > 1 {
            finx = finx + 432 - zoom * Double(zoomLocX/3)
            finy = finy + 863 - zoom * Double(zoomLocY/3)
        }
        return (finx, finy)
    }
    
    @objc func didDoubleTapView(_ sender: UITapGestureRecognizer){

        if welcomeBool == true{
            nextFeatureState = nextFeatureState + 1
            welcome()
        }
        else{
            engine.stop(completionHandler: { (_) -> Void in
            })
            currHeading = locationManager.heading!.trueHeading

            imgSaver.saveImage(image: drawView.image!)
            //cameraOffsetX = camPosition.x
            //cameraOffsetY = camPosition.z
            guard let locValue: CLLocationCoordinate2D = self.locationManager.location?.coordinate else { return }
            if (Int(self.currLocLat*100) != Int(locValue.latitude*100)) || (Int(self.currLocLon*100) != Int(locValue.longitude*100)) {
                //currLocLat = locValue.latitude
                //currLocLon = locValue.longitude
                //postAuth()
            }
            if ori == "north"{
                oldPoint = CGPoint(x: 431, y: 0)
            }
            else if ori == "south"{
                oldPoint = CGPoint(x: 431, y: 863)
            }
            else if ori == "east"{
                oldPoint = CGPoint(x: 863, y: 431)
            }
            else if ori == "west"{
                oldPoint = CGPoint(x: 0, y: 431)
            }
            postAuth()
            let imgNew = drawMap()
            drawView.image = imgNew
            //let imgNew = UIImage(named: "bitmap1")!
            extractor = PixelExtractor(img: imgNew.cgImage!)
            imgWidthScale = CGFloat(imgNew.cgImage!.width) / 0.3
            imgHeightScale = (CGFloat(imgNew.cgImage!.height) - 1) / 0.2
            imgWidth = CGFloat(imgNew.cgImage!.width)
            imgHeight = CGFloat(imgNew.cgImage!.height) - 1
        }
    }
    

    
    @objc func didLongPressView(_ sender: UILongPressGestureRecognizer){
        if sender.state.rawValue == 1{
            startListen()
        }
        else if sender.state.rawValue == 3{
            stopListen()
        }

    }
    
    @objc func didSingleTapView(_ sender: UITapGestureRecognizer){
        let updatedHeading = 360 - currHeading
        var longSide = lonConstant / (abs(latConstant*CoreGraphics.sin(updatedHeading * Double.pi / 180) + lonConstant * CoreGraphics.cos(updatedHeading * Double.pi / 180)))
        var shortSide = latConstant / (abs(latConstant*CoreGraphics.cos(updatedHeading * Double.pi / 180) + lonConstant * CoreGraphics.sin(updatedHeading * Double.pi / 180)))
        if (locX == 0){
            let tempLocY = locY
            engine.stop(completionHandler: { (_) -> Void in
            })
            imgSaver.saveImage(image: drawView.image!)
            ori = "west"
            oldPoint.x = 863 - oldPoint.x
            let tempLon = lonConstant * shortSide/zoom
            let tempLat = (latConstant * longSide * (2589 - Double(tempLocY))/2589 - latConstant*longSide/2)/zoom
            currLocLon = currLocLon - tempLon * CoreGraphics.cos(currHeading * Double.pi / 180) + tempLat * CoreGraphics.sin(currHeading * Double.pi / 180)
            currLocLat = currLocLat + tempLon * CoreGraphics.sin(currHeading * Double.pi / 180) + tempLat * CoreGraphics.cos(currHeading * Double.pi / 180)
            postAuth()
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
        }
        else if (locX >= 2588){
            let tempLocY = locY
            engine.stop(completionHandler: { (_) -> Void in
            })
            imgSaver.saveImage(image: drawView.image!)
            ori = "east"
            oldPoint.x = 863 - oldPoint.x
            let tempLon = lonConstant * shortSide/zoom
            let tempLat = (latConstant * longSide * (2589 - Double(tempLocY))/2589 - latConstant*longSide/2)/zoom
            currLocLon = currLocLon + tempLon * CoreGraphics.cos(currHeading * Double.pi / 180) + tempLat * CoreGraphics.sin(currHeading * Double.pi / 180)
            currLocLat = currLocLat - tempLon * CoreGraphics.sin(currHeading * Double.pi / 180) + tempLat * CoreGraphics.cos(currHeading * Double.pi / 180)
            postAuth()
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
        }
        else if (locY == 0){
            let tempLocX = locX
            engine.stop(completionHandler: { (_) -> Void in
            })
            imgSaver.saveImage(image: drawView.image!)
            ori = "north"
            oldPoint.y = 863 - oldPoint.y
            let tempLon = (lonConstant * shortSide * (Double(tempLocX)-1294)/2589)/zoom
            let tempLat = latConstant * longSide/zoom
            currLocLat = currLocLat + tempLat * CoreGraphics.cos(currHeading * Double.pi / 180) - tempLon * CoreGraphics.sin(currHeading * Double.pi / 180)
            currLocLon = currLocLon + tempLon * CoreGraphics.cos(currHeading * Double.pi / 180) + tempLat * CoreGraphics.sin(currHeading * Double.pi / 180)
            postAuth()
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
        }
        else if (locY >= 2588){
            let tempLocX = locX
            engine.stop(completionHandler: { (_) -> Void in
            })
            imgSaver.saveImage(image: drawView.image!)
            ori = "south"
            oldPoint.y = 863 - oldPoint.y
            let tempLon = (lonConstant * shortSide * (Double(tempLocX)-1294)/2589)/zoom
            let tempLat = latConstant * longSide/zoom
            currLocLat = currLocLat - tempLat * CoreGraphics.cos(currHeading * Double.pi / 180) - tempLon * CoreGraphics.sin(currHeading * Double.pi / 180)
            currLocLon = currLocLon - tempLat * CoreGraphics.sin(currHeading * Double.pi / 180) + tempLon * CoreGraphics.cos(currHeading * Double.pi / 180)
            postAuth()
            let imgNew = drawMap()
            drawView.image = imgNew
            extractor = PixelExtractor(img: imgNew.cgImage!)
        }
        else {
            var red:CGFloat = 0.0
            var green:CGFloat = 0.0
            var blue:CGFloat = 0.0
            var alpha:CGFloat = 0.0
            colorState!.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            red = CGFloat(red)*0.004
            green = CGFloat(green)*0.004
            blue = CGFloat(blue)*0.004
            if red > 1 {
                red = 1
            }
            if blue > 1{
                blue = 1
            }
            if green > 1 {
                green = 1
            }
            let newCol = UIColor(red: red, green: green, blue: blue, alpha: alpha)

            if colorState == UIColor(red: 255, green: 255, blue: 255, alpha: 1){
                currentLandmark = "Nothing"
            }
            if let key = nameColour.someKey(forValue: newCol){
                    currentLandmark = key
                    //speak
                    speech(inputString: currentLandmark)
            }
            let outImage = drawOnMap(inputImg: drawView.image!, newPoint: CGPoint(x: Int(locX/3), y: Int(863 - locY/3)), line : false)
            drawView.image = outImage
        }

    }
    
    @objc func didPinchView(_ sender: UIPinchGestureRecognizer){
        if (sender.scale > 1) && (sender.state.rawValue == 3){
            zoomIn()
        }
        else if (sender.scale < 1) && (sender.state.rawValue == 3){
            zoomOut()
        }
    }
    
    
//


    func prepareHaptics(){
        let hapticCap = CHHapticEngine.capabilitiesForHardware()
        supportsHaptics = hapticCap.supportsHaptics
        do{
            engine = try CHHapticEngine()
        } catch {
            print("Error creating engine: \(error.localizedDescription)")
        }
    }
    


    func complexHapBlack(){
        var events = [CHHapticEvent]()
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let continuousEvent = CHHapticEvent(eventType: .hapticContinuous, parameters:[intensity, sharpness], relativeTime: 0.0, duration: 100)
        events.append(continuousEvent)

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            player = try engine.makeAdvancedPlayer(with: pattern)
            try engine.start()
            try player.start(atTime: 0.0)
        } catch{
            print("failed to play pattern: \(error.localizedDescription)")
        }
    }

    func complexHapYellow(){
        //var events = [CHHapticEvent]()
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let short1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        let short2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.2)
        let short3 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.4)
        let short4 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.6)

        //let continuousEvent = CHHapticEvent(eventType: .hapticContinuous, parameters:[intensity, sharpness], relativeTime: 0.0, duration: 100)
        //events.append([short1, short2, short3, short4])

        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: [short1, short2, short3, short4], parameters: [])
            player = try engine.makeAdvancedPlayer(with: pattern)
            player.loopEnabled = true
            //player.playbackRate = 2
            player.loopEnd = 1.2
            try player.start(atTime: 0.0)


        } catch{
            print("failed to play pattern: \(error.localizedDescription)")
        }
    }

    func complexHapPurple(){
        //var events = [CHHapticEvent]()
        let intensity1 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
        let intensity2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let short1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity1, sharpness], relativeTime: 0)
        let long1 = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity2], relativeTime: 0.2, duration: 0.5)

        //let continuousEvent = CHHapticEvent(eventType: .hapticContinuous, parameters:[intensity, sharpness], relativeTime: 0.0, duration: 100)
        //events.append([short1, short2, short3, short4])

        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: [short1, long1], parameters: [])
            player = try engine.makeAdvancedPlayer(with: pattern)
            player.loopEnabled = true
            //player.playbackRate = 2
            player.loopEnd = 1.2
            try player.start(atTime: 0.0)

        } catch{
            print("failed to play pattern: \(error.localizedDescription)")
        }
    }

    func complexHapGreen(){
        //var events = [CHHapticEvent]()
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        //let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let long1 = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity], relativeTime: 0, duration: 0.5)
        let long2 = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity], relativeTime: 0.6, duration: 0.5)

        //let continuousEvent = CHHapticEvent(eventType: .hapticContinuous, parameters:[intensity, sharpness], relativeTime: 0.0, duration: 100)
        //events.append([short1, short2, short3, short4])

        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: [long1, long2], parameters: [])
            player = try engine.makeAdvancedPlayer(with: pattern)
            player.loopEnabled = true
            //player.playbackRate = 2
            player.loopEnd = 1.2
            try player.start(atTime: 0.0)

        } catch{
            print("failed to play pattern: \(error.localizedDescription)")
        }
    }

    func complexHapRed(){
        //var events = [CHHapticEvent]()
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let short1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        let short2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.2)

        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: [short1, short2], parameters: [])
            player = try engine.makeAdvancedPlayer(with: pattern)
            player.loopEnabled = true
            //player.playbackRate = 2
            player.loopEnd = 0.21
            try player.start(atTime: 0.0)

        } catch{
            print("failed to play pattern: \(error.localizedDescription)")
        }
    }

    func complexHapOrange(){
        //var events = [CHHapticEvent]()
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let short1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        let short2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.1)
        //let short4 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.6)

        //let continuousEvent = CHHapticEvent(eventType: .hapticContinuous, parameters:[intensity, sharpness], relativeTime: 0.0, duration: 100)
        //events.append([short1, short2, short3, short4])

        do {
            try engine.start()
            let pattern = try CHHapticPattern(events: [short1, short2], parameters: [])
            player = try engine.makeAdvancedPlayer(with: pattern)
            player.loopEnabled = true
            //player.playbackRate = 2
            player.loopEnd = 0.6
            try player.start(atTime: 0.0)

        } catch{
            print("failed to play pattern: \(error.localizedDescription)")
        }
    }

    func complexHapBlue(){
        var events = [CHHapticEvent]()
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
        let continuousEvent = CHHapticEvent(eventType: .hapticContinuous, parameters:[intensity, sharpness], relativeTime: 0.0, duration: 100)
        events.append(continuousEvent)

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            player = try engine.makeAdvancedPlayer(with: pattern)
            try engine.start()
            try player.start(atTime: 0.0)
        } catch{
            print("failed to play pattern: \(error.localizedDescription)")
        }
    }

    func hapticFeedback(color: UIColor){
        prepareHaptics()
        var red:CGFloat = 0.0
        var green:CGFloat = 0.0
        var blue:CGFloat = 0.0
        var alpha:CGFloat = 0.0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        if (red == green) && (green == blue) && (blue != 255) && (blue != 0){
            complexHapBlack() //good
        }
        else if (red == 255) && (green != 255) && (blue == 0){
            complexHapOrange() // good
        }
        else if (colorHash[color] == "Yellow"){
            complexHapRed() //good
        }
        else if (red != 255) && (green == 0) && (blue == 255){
            complexHapPurple()
        }
        else if (red == green) && (green == blue) && (blue == 0){
            complexHapGreen() //good
        }
        else if (red == 0) && (green == 255) && (blue != 255){
            complexHapBlue()
        }
        else if color == UIColor.white{
            engine.stop(completionHandler: { (_) -> Void in
            })
        }
    }

}

extension CGAffineTransform {
    static func flipVertical(_ height: CGFloat) -> CGAffineTransform {
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -height)
        return transform
    }
}




struct Response {
    var elementsBus : [BusGeom]
    var elementsRoad : [RoadGeom]
    var elementsTourism : [TourismGeom]
    var elementsTrain : [TrainGeom]
    var elementsPark : [ParkGeom]
}

struct BusGeom : Codable {
    var lat : Float
    var lon : Float
    var tags : Tag
}

struct TourismGeom : Codable {
    var geometry: [Coord]
    var tags: TagTourism
}

struct TrainGeom : Codable {
    var lat : Float
    var lon : Float
    var tags: TagTrain
}

struct RoadGeom : Codable {
    var geometry: [Coord]
    var tags: Tag
}

struct ParkGeom : Codable {
    var geometry: [Coord]
    var tags: TagPark
}


struct Coord: Codable {
    var lat : Float
    var lon : Float
}

struct Tag :  Codable {
    var name : String
    var highway : String
}

struct TagTourism :  Codable {
    var name : String
    var tourism : String
}

struct TagTrain :  Codable {
    var name : String
    var public_transport : String
}

struct TagPark : Codable {
    var name : String
    var leisure : String
}

extension Response: Decodable {
    enum data {
        case bus(BusGeom)
        case road(RoadGeom)
        case tourism(TourismGeom)
        case train(TrainGeom)
        case park(ParkGeom)
    }
    
    enum CodingKeys: String, CodingKey {
        case elements
    }
    
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var unkeyedContainer = try container.nestedUnkeyedContainer(forKey: .elements)
        var labelsBus = [BusGeom]()
        var labelsRoad = [RoadGeom]()
        var labelsTourism = [TourismGeom]()
        var labelsTrain = [TrainGeom]()
        var labelsPark = [ParkGeom]()
        while !unkeyedContainer.isAtEnd {
            do {
                let road = try unkeyedContainer.decode(RoadGeom.self)
                labelsRoad.append(road)
            }catch DecodingError.keyNotFound{
                do{
                    let bus = try unkeyedContainer.decode(BusGeom.self)
                    labelsBus.append(bus)
                }catch DecodingError.keyNotFound{
                    do {
                        let park = try unkeyedContainer.decode(ParkGeom.self)
                        labelsPark.append(park)
                    }catch DecodingError.keyNotFound{
                        do{
                            let tourism = try unkeyedContainer.decode(TourismGeom.self)
                            labelsTourism.append(tourism)
                        }catch DecodingError.keyNotFound{
                            let train = try unkeyedContainer.decode(TrainGeom.self)
                            labelsTrain.append(train)
                        }
                    }
                }
            }
        }
        elementsTourism = labelsTourism
        elementsBus = labelsBus
        elementsRoad = labelsRoad
        elementsTrain = labelsTrain
        elementsPark = labelsPark
    }
}

class ImageSaveObject: NSObject {
    func saveImage(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveFinished), nil)
    }

    @objc func saveFinished(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        print("Save finished!")
    }
}

class PixelExtractor {
    let image: CGImage
    let context: CGContext
    var width: Int {
        get {
            return image.width
        }
    }

    var height: Int {
        get {
            return image.height
        }
    }

    init(img: CGImage) {
        image = img
        context = PixelExtractor.create_bitmap_context(img: img)
    }

    private class func create_bitmap_context(img: CGImage )->CGContext {

        let pixelsWide = img.width
        let pixelsHigh = img.height

        let bitmapBytesPerRow = pixelsWide * 4
        let bitmapByteCount = bitmapBytesPerRow * Int(pixelsHigh)

        let colorSpace = CGColorSpaceCreateDeviceRGB()


        let bitmapData = malloc(bitmapByteCount)
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context: CGContext = CGContext(data: bitmapData, width: pixelsWide, height: pixelsHigh, bitsPerComponent: 8,
                                      bytesPerRow: bitmapBytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!

        let rect = CGRect(x: 0, y: 0, width: pixelsWide, height: pixelsHigh)
        context.draw(img, in: rect)
        return context
    }


    func color_at(x: Int, y: Int)->UIColor {
        assert(0<=x && x<=width)
        assert(0<=y && y<=height)

        let uncasted_data = context.data!
        let data: UnsafeMutablePointer<UInt8> = uncasted_data.bindMemory(to: UInt8.self, capacity: width * height)

        let offset = 4 * (y * width + x)
        //let offset = 4 * (3 * width + 3)
        let alpha = data[offset]
        let red = data[offset+1]
        let green = data[offset+2]
        let blue = data[offset+3]

        let color = UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
        return color
    }

}
extension Dictionary where Value: Equatable {
    func someKey(forValue val: Value) -> Key? {
        return first(where: { $1 == val })?.key
    }
}





//    @objc func didPanView(_ sender: UIPanGestureRecognizer){
//        let finger = sender.location(in: sender.view)
//        self.location = finger
//        let x = Int(finger.x)
//        let y = Int(finger.y)
//        let color = extractor.color_at(x:x, y:y)
//        if (color != colorState){
//            colorState = color
//            hapticFeedback(color: color)
//        }
//        if sender.state == .ended{
//            colorState = UIColor(red: 255, green: 255, blue: 255, alpha: 1)
//            hapticFeedback(color: UIColor(red: 255, green: 255, blue: 255, alpha: 1))
//        }
//    }



    


//    func startDeviceMotion() {
//        //if motion.isDeviceMotionAvailable {
//            self.motion.deviceMotionUpdateInterval = 1.0 / 60.0
//            self.motion.showsDeviceMovementDisplay = true
//            self.motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)
//
//            // Configure a timer to fetch the motion data.
//            self.timer = Timer(fire: Date(), interval: (1.0 / 60.0), repeats: true,
//                               block: { (timer) in
//                                if let data = self.motion.deviceMotion {
//                                    // Get the attitude relative to the magnetic north reference frame.
//                                    let x = data.attitude.pitch
//                                    let y = data.attitude.roll
//                                    let z = data.attitude.yaw
//
//
//                                    // Use the motion data in your app.
//                                }
//            })
//
//            // Add the timer to the current run loop.
//        RunLoop.main.add(self.timer, forMode: RunLoop.Mode.default)
//        //}
//    }


