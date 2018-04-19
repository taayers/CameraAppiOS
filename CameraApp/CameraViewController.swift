//
//  ViewController.swift
//  CameraApp
//
//  Created by Todd on 10/13/16.
//  Copyright © 2016 Triadic Software. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation

class CameraViewController: PageItem, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    
    @IBOutlet weak var pictureButton: UIButton!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var receiptButton: UIButton!
    @IBOutlet weak var warrantyButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    
    var path: String?
    var photoData: Data?
    var capturedText: String?
    var sessionOutput = AVCapturePhotoOutput()
    var movieOutput = AVCaptureMovieFileOutput()
    var photoSettings : AVCapturePhotoSettings?
    var imageCaptured:UIImage!
    var flashOn:Bool = false
    var captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice!
    var previewLayer : AVCaptureVideoPreviewLayer?
    let container: UIView = UIView()
    let loadingView: UIView = UIView()
    let actInd: UIActivityIndicatorView = UIActivityIndicatorView()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("Camera View Controller Loaded")
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CameraViewController.takePicture(sender:)))
        let pressGesture = UILongPressGestureRecognizer(target: self, action: #selector(CameraViewController.takeVideo(sender:)))
        
        tapGesture.numberOfTapsRequired = 1
        pressGesture.minimumPressDuration = 1
        pictureButton.addGestureRecognizer(tapGesture)
        pictureButton.addGestureRecognizer(pressGesture)
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetMedium
        
        let parent = self.parent as? PageViewController
        managedObjectContext = parent?.context

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadCamera()
        if !(captureSession.isRunning){
            captureSession.startRunning()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer?.frame = cameraView.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (captureSession.isRunning){
            captureSession.stopRunning()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadCamera() {
        
        if let dualCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInDuoCamera, mediaType: AVMediaTypeVideo, position: .back) {
            backCamera = dualCameraDevice
        }else if let backCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back) {
            // If the back dual camera is not available, default to the back wide angle camera.
            backCamera = backCameraDevice
        }

        do{
            let input = try AVCaptureDeviceInput(device: backCamera)
            if(captureSession.canAddInput(input)){
                captureSession.addInput(input);
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession);
                previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill;
                previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait;
                cameraView.layer.addSublayer(previewLayer!);
                
            }
        }catch{
            print("exception!");
        }
        
    }
    
    // MARK: - Buttons
    
    func takePicture(sender: UIGestureRecognizer){
        if(captureSession.canAddOutput(sessionOutput)){
            captureSession.addOutput(sessionOutput)
        }
        photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecJPEG])

        if flashOn{
            photoSettings?.flashMode = .on
        }
        showActivityIndicatory(uiView: self.view)
        
        sessionOutput.capturePhoto(with: photoSettings!, delegate: self)
    }
    
    func takeVideo(sender: UIGestureRecognizer){
        if sender.state == .began{
            if flashOn{
                do{
                    try backCamera.lockForConfiguration()
                    backCamera.torchMode = AVCaptureTorchMode.on
                }catch let error as NSError{
                    print("Could not use torch mode. \(error), \(error.userInfo)")
                }
                backCamera.unlockForConfiguration()
            }
            if(captureSession.canAddOutput(movieOutput)){
                captureSession.addOutput(movieOutput)
            }
            let videoID = getNextID()
            
            let url = getVideoPath(index: videoID)
            
            movieOutput.startRecording(toOutputFileURL: url, recordingDelegate: self)
            
        }else if sender.state == .ended{
            if flashOn{
                do{
                    try backCamera.lockForConfiguration()
                    backCamera.torchMode = AVCaptureTorchMode.off
                }catch let error as NSError{
                    print(error)
                }
                backCamera.unlockForConfiguration()
            }
            movieOutput.stopRecording()
        }
    }
    
    @IBAction func flashBtn(_ sender: AnyObject) {
        flashOn = !flashOn
        if flashOn {
            sender.setImage(UIImage(named: "flash_on")!, for: UIControlState.normal)
        } else {
            sender.setImage(UIImage(named: "flash")!, for: UIControlState.normal)
        }
    }
    
    // MARK: - Delegate Methods
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        if let photoSampleBuffer = photoSampleBuffer{
            photoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: nil)
            if let image = UIImage(data: photoData!){
                let scaledImage = scaleImage(image: image, maxDimension: 1024)
                performImageRecognition(image: scaledImage)
            }
        }
    }
    
    func capture(_ output: AVCapturePhotoOutput, didFinishCaptureForResolvedSettings resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        hideActivityIndicator(uiView: self.view)
        segueToEditReceiptVCWithPhoto()
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("Video capture finished")
        if error == nil{
            segueToEditReceiptVCWithVideo(url: outputFileURL)
        }else{
            print(error)
        }
    }

    
    // MARK: - Activity Indicator
    
    func showActivityIndicatory(uiView: UIView) {
        container.frame = uiView.frame
        container.center = uiView.center
        container.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.50)
        
        loadingView.frame = CGRect.init(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = uiView.center
        loadingView.backgroundColor = UIColor(red: 0.27, green: 0.27, blue: 0.27, alpha: 0.70)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        
        actInd.frame = CGRect.init(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        actInd.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.whiteLarge
        actInd.center = CGPoint.init(x: loadingView.frame.width / 2, y: loadingView.frame.height / 2)
        loadingView.addSubview(actInd)
        container.addSubview(loadingView)
        uiView.addSubview(container)
        uiView.bringSubview(toFront: container)
        actInd.startAnimating()
    }
    
    func hideActivityIndicator(uiView: UIView) {
        actInd.stopAnimating()
        container.removeFromSuperview()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SettingsSegue"{
            let targetController = segue.destination as! SettingsViewController
            targetController.managedObjectContext = managedObjectContext
        }
    }
    
    func segueToEditReceiptVCWithPhoto(){
        let targetViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EditReceiptViewController") as! EditReceiptViewController
        targetViewController.managedObjectContext = managedObjectContext
        targetViewController.photoData = photoData
        targetViewController.storeName = getFirstLineFromRecipt(text: capturedText!)
        targetViewController.storeTotal = getTotalFromReceipt(text: capturedText!)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        if let date = getDateFromReceipt(text: capturedText!){
            targetViewController.storeDate = formatter.date(from: date)
        }
        self.show(targetViewController, sender: self)
    }
    
    func segueToEditReceiptVCWithVideo(url: URL){
        let targetViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EditReceiptViewController") as! EditReceiptViewController
        targetViewController.managedObjectContext = managedObjectContext
        targetViewController.videoFile = path
        self.show(targetViewController, sender: self)
    }
    

    @IBAction func goToReceiptsListBtn(_ sender: Any) {
        let vcparent = self.parent as? PageViewController
        vcparent?.showReceiptsListViewController()
    }

    @IBAction func goToWarrantyListBtn(_ sender: Any) {
        let vcparent = self.parent as? PageViewController
        vcparent?.showWarrantyListViewController()
    }
    
    // MARK: - Image Processing
    
    func getVideoPath(index: Int) -> URL{
        let filename = "Video-\(index).mp4"
        path = filename
        let filePath = URL(fileURLWithPath: getPathForFileName(fileName: filename))
        return filePath
    }
    
    func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor: CGFloat
        
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        image.draw(in: CGRect(x:0, y:0, width:scaledSize.width, height:scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
    
    func performImageRecognition(image: UIImage) {
        // 1
        let tesseract = G8Tesseract()
        // 2
        tesseract.language = "eng"
        // 3
        tesseract.engineMode = .tesseractCubeCombined
        // 4
        tesseract.pageSegmentationMode = .auto
        // 5
        tesseract.maximumRecognitionTime = 60.0
        // 6
        tesseract.image = image.g8_blackAndWhite()
        tesseract.recognize()
        // 7
        capturedText = tesseract.recognizedText
        print(tesseract.recognizedText)
        // 8
    }
    
    func getDateFromReceipt(text: String) -> String?{
        var result: String?
        let datePattern = "\\b(\\d{1,2})[/-](\\d{1,2})[/-](\\d+)\\b"
        let dateRegex = try! NSRegularExpression(pattern: datePattern, options: [])
        let nsString = text as NSString
        
        let match = dateRegex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.characters.count))
        if let matching = match{
            result = nsString.substring(with: (matching.range))
        }
        return result
    }
    
    func getTotalFromReceipt(text: String) -> String?{
        var result: String?
        let totalPattern = "Total:?\\s*?(Sale)?\\s*?\\$?(\\d+\\.\\d{2})"
        let totalRegex = try! NSRegularExpression(pattern: totalPattern, options: [])
        let nsString = text as NSString
        
        let match  = totalRegex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.characters.count))
        if let matching = match{
            result = nsString.substring(with: (matching.rangeAt(2)))
        }
        return result
    }
    
    func getFirstLineFromRecipt(text: String) -> String?{
        var result: String?
        let linePattern = "^\\w+"
        let lineRegex = try! NSRegularExpression(pattern: linePattern, options: [])
        let nsString = text as NSString
        
        let match  = lineRegex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.characters.count))
        if let matching  = match{
            result = nsString.substring(with: (matching.range))
        }

        return result
    }
}
