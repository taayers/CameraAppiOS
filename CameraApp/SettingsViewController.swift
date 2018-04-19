//
//  SettingsViewController.swift
//  CameraApp
//
//  Created by Todd on 10/20/16.
//  Copyright © 2016 Triadic Software. All rights reserved.
//

import UIKit
import CoreData


class SettingsViewController: UIViewController {
    
    var managedObjectContext: NSManagedObjectContext?
    var warrantyAlertTime = 5
    var emailReceiptToggleState = false
    var pushNotificationsToggleState = false
    var currentEmailAddress = "None"
    
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var emailReceiptsToggle: UISwitch!
    @IBOutlet weak var pushNotificationsToggle: UISwitch!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("Settings View Controller Loaded")
        
        getDefaultStates()
        fetchCurrentEmailAddress()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Configure View
    func configureToggles(){
        if emailReceiptToggleState == false{
            emailReceiptsToggle.setOn(false, animated: false)
        }else{
            emailReceiptsToggle.setOn(true, animated: false)
        }
        if pushNotificationsToggleState == false{
            pushNotificationsToggle.setOn(false, animated: false)
        }else{
            pushNotificationsToggle.setOn(true, animated: false)
        }
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func backBtn(_ sender: AnyObject) {
        saveDefaultStates()
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func warrantyAlertTimeBtn(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Warranty Alert Time",
                                      message: "Set the number of days prior to a warranty expiring that you would like to be alerted. Current setting is \(warrantyAlertTime) days.",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default){
            [unowned self] action in
            
            guard let textField = alert.textFields?.first,
                let timeToSave = Int(textField.text!) else{
                    return
                }
            self.warrantyAlertTime = timeToSave
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    @IBAction func emailReceiptsOptionsBtn(_ sender: AnyObject) {
        
        let alert = UIAlertController(title: "Add Email Address",
                                message: "Add an email address that new receipts will be sent to. Current email address is \(currentEmailAddress)",
                                preferredStyle: .alert)
                                    
        let saveAction = UIAlertAction(title: "Save", style: .default){
            [unowned self] action in
            
            guard let textField = alert.textFields?[0],
                let addressToSave = textField.text , !addressToSave.isEmpty else{
                    return
            }
            self.deleteEmailAddresses()
            self.saveEmailAddressToDB(address: addressToSave)
        
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }

    // MARK: - Saves
    func saveEmailAddressToDB(address: String){
        let email = EmailAddresses(context: managedObjectContext!)
        
        email.emailAddress = address
        
        do{
            try self.managedObjectContext?.save()
            print("Email Address Saved")
            currentEmailAddress = address
        }catch let error as NSError{
            print("Could not save Email Address. \(error), \(error.userInfo)")
        }
    }
    
    func saveDefaultStates(){
        emailReceiptToggleState = emailReceiptsToggle.isOn
        pushNotificationsToggleState = pushNotificationsToggle.isOn
        defaults.set(emailReceiptToggleState, forKey: "emailReceiptsToggle")
        defaults.set(pushNotificationsToggleState, forKey: "pushNotificationsToggle")
        defaults.set(warrantyAlertTime, forKey: "warrantyAlertTime")
    }
    
    // MARK: - Fetches
    func getDefaultStates(){
        
        emailReceiptToggleState = defaults.bool(forKey: "emailReceiptsToggle")
        pushNotificationsToggleState = defaults.bool(forKey: "pushNotificationsToggle")
        warrantyAlertTime = defaults.integer(forKey: "warrantyAlertTime")
        

//        let fetchRequest = NSFetchRequest<EmailReceiptsToggle>()
//        
//        let entity = EmailReceiptsToggle.entity()
//        fetchRequest.entity = entity
//        
//        do {
//            var result = try managedObjectContext?.fetch(fetchRequest)
//            emailReceiptToggleState = (result?[0].toggleOn)!
//            print(emailReceiptToggleState)
//            print("Email Receipt Toggle Fetched")
//        } catch let error as NSError {
//            print("Could not fetch. \(error), \(error.userInfo)")
//        }
        configureToggles()
    }
    
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
    
    func deleteEmailAddresses(){
        let deleteRequest = NSFetchRequest<EmailAddresses>()
        let deleteEntity = EmailAddresses.entity()
        deleteRequest.entity = deleteEntity
        deleteRequest.includesPropertyValues = false
        
        do{
            if let deleteResults = try managedObjectContext?.fetch(deleteRequest){
                for item in deleteResults{
                    managedObjectContext?.delete(item)
                }
            }
        }catch let error as NSError{
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
}
