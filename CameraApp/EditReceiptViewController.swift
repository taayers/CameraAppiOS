//
//  EditReceiptViewController.swift
//  CameraApp
//
//  Created by Todd on 11/18/16.
//  Copyright © 2016 Triadic Software. All rights reserved.
//

import CoreData
import UIKit
import MessageUI
import AVKit
import AVFoundation

class EditReceiptViewController: UIViewController, MFMailComposeViewControllerDelegate,
                                    UITextFieldDelegate, UIImagePickerControllerDelegate,
                                    UINavigationControllerDelegate{
    
    
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var topConstraintMargin: NSLayoutConstraint!
    @IBOutlet weak var editImageBtn: UIButton!
    @IBOutlet weak var receiptImage: UIImageView!
    @IBOutlet weak var storeTextField: UITextField!
    @IBOutlet weak var totalTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var viewPicBtn: UIButton!
    
    let defaults = UserDefaults.standard
    let fileMgr = FileManager.default
    
    var originalTopMargin: CGFloat!
    
    var imagePicker: UIImagePickerController!
    var photoPath = ""
    var photoID: Int?
    var editPhotoData: Data?
    
    var isNewReceipt: Bool?
    var isPictureTaken: Bool?
    var isPhotoReceipt: Bool?
    var isSaved: Bool?
    
    var managedObjectContext: NSManagedObjectContext?
    var image: UIImage?
    var receiptImageString: String?
    var storeTextFieldText: String?
    var totalTextFieldText: String?
    var date: Date?
    var currentEmailAddress: String?
    var emailReceiptToggleState: Bool = false
    
    var storeName: String?{
        didSet{
            if let tempName = storeName{
                storeTextFieldText = tempName
            }
        }
    }
    var storeDate: Date?{
        didSet{
            if let tempDate = storeDate{
                date = tempDate
            }
        }
    }
    var storeTotal: String?{
        didSet{
            if let tempTotal = storeTotal{
                totalTextFieldText = tempTotal
            }
        }
    }
    var photoData: Data?{
        didSet{
            if let data = photoData{
                image = UIImage(data: data)
            }
            isPhotoReceipt = true
        }
    }
    var videoFile: String?{
        didSet{
            if let file = videoFile{
                if fileMgr.fileExists(atPath: getPathForFileName(fileName: file)){
                    photoPath = file
                }
            }
            isPhotoReceipt = false
        }
    }
    var receiptToEdit: Receipts? {
        didSet{
            if let receipt = receiptToEdit{
                storeTextFieldText = receipt.store!
                totalTextFieldText = receipt.total!
                date = receipt.date!
                isPhotoReceipt = receipt.isPhotoReceipt
                photoPath = receipt.imageLocation
                if isPhotoReceipt!{
                    if fileMgr.fileExists(atPath: getPathForFileName(fileName: receipt.imageLocation)){
                        image = UIImage.init(contentsOfFile: getPathForFileName(fileName: receipt.imageLocation))
                    }
                }else{
                    if fileMgr.fileExists(atPath: getPathForFileName(fileName: receipt.imageLocation)){
                        image = getVideoThumbnail()
                    }
                }
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        fetchEmailReceiptToggleState()
        isNewReceipt = true
        isPhotoReceipt = true
        isPictureTaken = false
        isSaved = false
        
        originalTopMargin = topConstraintMargin.constant
        
        storeTextField.delegate = self
        storeTextField.keyboardType = .emailAddress
        totalTextField.delegate = self
        totalTextField.keyboardType = .numbersAndPunctuation
        
        if emailReceiptToggleState{
            fetchCurrentEmailAddress()
        }
        
        if let tempName = storeTextFieldText{
            storeTextField.text = tempName
        }
        
        if let tempDate = date{
            datePicker.date = tempDate
        }
        
        if let tempTotal = totalTextFieldText{
            totalTextField.text = tempTotal
        }
        
        if let tempImage = photoData{
            receiptImage.image = image
            editImageBtn.isHidden = true
            editImageBtn.isEnabled = false
            viewPicBtn.isHidden = false
            viewPicBtn.isEnabled = true
            playBtn.isHidden = true
            playBtn.isEnabled = false
            photoID = getNextID()
            photoPath = getPhotoPath(index: photoID!)
            isPictureTaken = true
            isPhotoReceipt = true
            editPhotoData = photoData
            
        }
        
        if let temp = receiptToEdit{
            isNewReceipt = false
            storeTextField.text = storeTextFieldText
            totalTextField.text = totalTextFieldText
            datePicker.date = date!
            receiptImage.image = image
            if isPhotoReceipt!{
                playBtn.isHidden = true
                playBtn.isEnabled = false
                editImageBtn.isEnabled = true
                editImageBtn.isHidden = false
                viewPicBtn.isHidden = false
                viewPicBtn.isEnabled = true
            }else{
                playBtn.isHidden = false
                playBtn.isEnabled = true
                editImageBtn.isEnabled = false
                editImageBtn.isHidden = true
                viewPicBtn.isHidden = true
                viewPicBtn.isEnabled = false
            }
        }
        
        if let tempFile = videoFile{
            isPictureTaken = true
            isPhotoReceipt = false
            editImageBtn.isHidden = true
            editImageBtn.isEnabled = false
            playBtn.isEnabled = true
            playBtn.isHidden = false
            viewPicBtn.isHidden = true
            viewPicBtn.isEnabled = false
            receiptImage.image = getVideoThumbnail()
        }
        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(EditReceiptViewController.closeKeyboard))
//        tapGesture.numberOfTapsRequired = 2
//        self.view.addGestureRecognizer(tapGesture)
//        
//        let picGesture = UITapGestureRecognizer(target: self, action: #selector(EditReceiptViewController.imageTapped))
//        receiptImage.addGestureRecognizer(picGesture)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    @IBAction func saveBtn(_ sender: Any) {
        guard let storeToSave = storeTextField.text, !storeToSave.isEmpty else{
            callShortAlert()
            return
        }
        guard let totalToSave = totalTextField.text, !totalToSave.isEmpty else{
            callShortAlert()
            return
        }
        
        let date = datePicker.date
        
        saveReceiptToDb(store: storeToSave, total: totalToSave, date: date)
        
    }
    
    @IBAction func cancelBtn(_ sender: Any) {
        if !isSaved!{
            if let temp = videoFile{
                do{
                    try fileMgr.removeItem(atPath: getPathForFileName(fileName: photoPath))
                }catch let error as NSError{
                    print(error)
                }
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as! UINavigationController
        let targetController = navigationController.topViewController as! ViewImageViewController
        targetController.image = receiptImage.image
    }
    
    //MARK: - Saving Functions
    
    func saveReceiptToDb(store: String, total: String, date: Date){
        let receipt: Receipts
        if let temp = receiptToEdit{
            receipt = temp
        }else{
            receipt = Receipts(context: managedObjectContext!)
        }
        
        if isPictureTaken!{
            if isPhotoReceipt!{
                let url = URL(fileURLWithPath: getPathForFileName(fileName: photoPath))
                do{
                    try editPhotoData?.write(to: url, options: .atomic)
                    receipt.imageLocation = photoPath
                    receipt.isPhotoReceipt = true
                }catch let error as NSError{
                    print("Could not save image. \(error), \(error.userInfo)")
                }
            }else{
                receipt.imageLocation = photoPath
                receipt.isPhotoReceipt = false
            }
        }
        
        receipt.store = store
        receipt.total = total
        receipt.date = date
        
        if emailReceiptToggleState{
            sendMail(receipt: receipt)
        }
        
        
        do{
            try self.managedObjectContext?.save()
            print("Receipt Saved")
            isSaved = true
        }catch let error as NSError{
            print("Could not save Receipt. \(error), \(error.userInfo)")
        }
        saveBtn.isEnabled = false
    }
    
    //MARK: - Image Functions
    
    @IBAction func playVideo(_ sender: Any) {

        let player = AVPlayer(url: URL(fileURLWithPath: getPathForFileName(fileName: photoPath)))
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.present(playerViewController, animated: true) { () -> Void in
            player.play()
        }

    }
    
    @IBAction func editImage(_ sender: Any) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.cameraCaptureMode = .photo
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            if isNewReceipt!{
                photoID = getNextID()
                photoPath = getPhotoPath(index: photoID!)
            }
            receiptImage.image = image
            editPhotoData = UIImageJPEGRepresentation(image, 0.75)
            isPictureTaken = true
            
        }
    }
    
    func getPhotoPath(index: Int) -> String{
        let filename = "Photo-\(index).jpg"
        return filename
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func getVideoThumbnail() -> UIImage{
        do {
            let tempURL = URL(fileURLWithPath: getPathForFileName(fileName: photoPath))
            let asset = AVURLAsset(url: tempURL, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            return thumbnail
            
            // thumbnail here
            
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
        }
        let image = UIImage(named: "No_Image_Available", in: Bundle(for: EditReceiptViewController.self), compatibleWith: nil)
        return image!
    }
    
//    @IBAction func imageTapped(_ sender: UITapGestureRecognizer) {
//        let imageView = sender.view as! UIImageView
//        let newImageView = UIImageView(image: imageView.image)
//        newImageView.frame = UIScreen.main.bounds
//        newImageView.backgroundColor = .black
//        newImageView.contentMode = .scaleAspectFit
//        newImageView.isUserInteractionEnabled = true
//        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage))
//        newImageView.addGestureRecognizer(tap)
//        self.view.addSubview(newImageView)
//        self.navigationController?.isNavigationBarHidden = true
//        self.tabBarController?.tabBar.isHidden = true
//    }
//
//    func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
//        self.navigationController?.isNavigationBarHidden = false
//        self.tabBarController?.tabBar.isHidden = false
//        sender.view?.removeFromSuperview()
//    }
    
    // MARK: - Alerts
    
    func callShortAlert(){
        let alert = UIAlertController(title: "",
                                      message: "Please fill in store and total fields before attempting to save.",
                                      preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - Fetch Functions
    
    func fetchCurrentEmailAddress(){
        let fetchRequest = NSFetchRequest<EmailAddresses>()
        let entity = EmailAddresses.entity()
        fetchRequest.entity = entity
        
        do{
            if let result = try managedObjectContext?.fetch(fetchRequest){
                if result.count > 0{
                    currentEmailAddress = result[0].emailAddress!
                }
            }
        }catch let error as NSError{
            print("Could not fetch current email address. \(error), \(error.userInfo)")
        }
    }
    
    func fetchEmailReceiptToggleState(){
        emailReceiptToggleState = defaults.bool(forKey: "emailReceiptsToggle")
    }
    
    // MARK: - Send Email
    
    func sendMail(receipt: Receipts){
        if let address = currentEmailAddress{
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.mailComposeDelegate = self
                mail.setToRecipients([address])
                mail.setSubject("Saved receipt from ReceiptSmart")
                mail.setMessageBody("\(receipt.store!)\n\(receipt.total!)\n\(receipt.date!)", isHTML: false)
                if isPhotoReceipt!{
                    if fileMgr.fileExists(atPath: getPathForFileName(fileName: receipt.imageLocation)){
                        image = UIImage.init(contentsOfFile: getPathForFileName(fileName: receipt.imageLocation))
                        let imageData: Data = UIImageJPEGRepresentation(image!, 0.75)!
                        mail.addAttachmentData(imageData, mimeType: "image/png", fileName: "imageName")
                    }
                }else{
                    if fileMgr.fileExists(atPath: getPathForFileName(fileName: receipt.imageLocation)){
                        do{
                            let tempURL = URL(fileURLWithPath: getPathForFileName(fileName: receipt.imageLocation))
                            let videoData: Data = try Data.init(contentsOf: tempURL)
                            mail.addAttachmentData(videoData, mimeType: "mp4", fileName: "video")
                        }catch let error as NSError{
                            print(error)
                        }
                    }
                }
                self.present(mail, animated: true, completion: nil)
            }
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
        //self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - TextField Helper Functions
    
    func closeKeyboard(){
        self.view.endEditing(true)
        moveViewDown()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        moveViewDown()
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        moveViewUp()
        saveBtn.isEnabled = true
    }
    
    func moveViewUp() {
        if topConstraintMargin.constant != originalTopMargin {
            return
        }
        
        topConstraintMargin.constant -= 135
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func moveViewDown() {
        if topConstraintMargin.constant == originalTopMargin {
            return
        }
        
        topConstraintMargin.constant = originalTopMargin
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        
    }

}
