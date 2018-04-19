//
//  WarrantyListViewController.swift
//  CameraApp
//
//  Created by Todd on 10/16/16.
//  Copyright © 2016 Triadic Software. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class WarrantyListViewController: PageItem, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UITextFieldDelegate {
    
    
    @IBOutlet weak var searchWarrantiesBar: UISearchBar!
    @IBOutlet weak var warrantyListTable: UITableView!
    
    var pushNotificationsToggleState = false
    var warrantyAlertTime = 5
    var warranties = [Warranties]()
    var warrantiesSearching = [Warranties]()
    var isSearching = false
    
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("Warranty List View Controller Loaded")
        warrantyListTable.tableFooterView = UIView(frame: CGRect.zero)
        warrantyListTable.tableHeaderView = UIView(frame: CGRect.zero)
        
        searchWarrantiesBar.delegate = self
        
        let parent = self.parent as? PageViewController
        managedObjectContext = parent?.context
        
        getDefaultStates()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(WarrantyListViewController.closeKeyboard))
        tapGesture.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchWarrantyList()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        warranties.removeAll()
        managedObjectContext?.reset()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - TableView Delegate Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching{
            return warrantiesSearching.count
        }else{
            return warranties.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WarrantyCell") as! WarrantyCell
        
        if isSearching{
            cell.warrantyName.text = warrantiesSearching[indexPath.row].itemName
            cell.warrantyDaysLeft.text = warrantiesSearching[indexPath.row].daysLeft
            if Int(warrantiesSearching[indexPath.row].daysLeft!)! <= warrantyAlertTime{
                cell.contentView.backgroundColor = UIColor.red
            }else{
                cell.contentView.backgroundColor = nil
            }
        }else{
            cell.warrantyName.text = warranties[indexPath.row].itemName
            cell.warrantyDaysLeft.text = warranties[indexPath.row].daysLeft
            if Int(warranties[indexPath.row].daysLeft!)! <= 5{
                cell.contentView.backgroundColor = UIColor.red
            }else{
                cell.contentView.backgroundColor = nil
            }
        }
        
        return cell

    }
    
    @objc(tableView:didSelectRowAtIndexPath:)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isSearching{
            editWarranty(warranty: warrantiesSearching[indexPath.row])
        }else{
            editWarranty(warranty: warranties[indexPath.row])
        }
        
    }
    
    //MARK: - TableView Functions
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchWarrantiesBar.text!.isEmpty{
            isSearching = false
            warrantyListTable.reloadData()
        }else{
            isSearching = true
            warrantiesSearching.removeAll(keepingCapacity: false)
            
            for each in 0..<warranties.count{
                let listItem = warranties[each]
                if listItem.itemName?.lowercased().range(of: self.searchWarrantiesBar.text!.lowercased()) != nil {
                    warrantiesSearching.append(listItem)
                }
            }
            warrantyListTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete{
            if isSearching{
                let deleteWarranty = warrantiesSearching.remove(at: indexPath.row)
                warrantyListTable.deleteRows(at: [indexPath], with: .top)
                deleteWarrantyFromDB(warranty: deleteWarranty)
            }else{
                let deleteWarranty = warranties.remove(at: indexPath.row)
                warrantyListTable.deleteRows(at: [indexPath], with: .top)
                deleteWarrantyFromDB(warranty: deleteWarranty)
            }
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
    
    //MARK: - CRUD Functions
    
    @IBAction func addWarrantiesBtn(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Add New Warranty",
                                      message: "Add a new warranty and time left on the warranty to your list.",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default){
            [unowned self] action in
            
            guard let nameField = alert.textFields?[0], let nameToSave = nameField.text, !nameToSave.isEmpty else{
                return
            }
            
            guard let daysField = alert.textFields?[1], let daysToSave = daysField.text, !daysToSave.isEmpty else{
                return
            }
            
            let dateToSave = Date()
            
            self.saveWarrantyToDB(item: nameToSave, days: daysToSave, date: dateToSave)
            
            self.fetchWarrantyList()
            
            self.warrantyListTable.reloadData()
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        alert.addTextField{ (textField: UITextField) -> Void in
            textField.placeholder = "Item Name"
            textField.delegate = self
        }
        
        alert.addTextField{ (textField: UITextField) -> Void in
            textField.placeholder = "Days Left"
            textField.keyboardType = .numbersAndPunctuation
            textField.delegate = self
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }

    @IBAction func sortWarrantiesBtn(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Sort Warranties",
                                      message: "Choose how to sort your warranty list",
                                      preferredStyle: .alert)
        
        let nameSort = UIAlertAction(title: "Sort by Name", style: .default){
            [unowned self] action in
            self.warranties.sort{
                $0.itemName! < $1.itemName!
            }
            self.warrantyListTable.reloadData()
        }
        
        let daysSort = UIAlertAction(title: "Sort by Days Left", style: .default){
            [unowned self] action in
            self.warranties.sort{
                Int($0.daysLeft!)! < Int($1.daysLeft!)!
            }
            self.warrantyListTable.reloadData()
        }
        
        
        
        alert.addAction(nameSort)
        alert.addAction(daysSort)
        
        present(alert, animated: true)
    }
    
    func editWarranty(warranty: Warranties){
        let alert = UIAlertController(title: "Edit Warranty Information",
                                      message: "",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default){
            [unowned self] action in
            
            guard let nameField = alert.textFields?[0], let nameToEdit = nameField.text else{
                return
            }
            
            guard let daysField = alert.textFields?[1], let daysToEdit = daysField.text else{
                return
            }
            
            if !nameToEdit.isEmpty{
                warranty.itemName = nameToEdit
            }
            
            if !daysToEdit.isEmpty{
                warranty.daysLeft = daysToEdit
            }
            
            do{
                try self.managedObjectContext?.save()
                print("Saved Edits")
            }catch let error as NSError{
                print("Could not save edits. \(error), \(error.userInfo)")
            }
            
            self.fetchWarrantyList()
            
            self.warrantyListTable.reloadData()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        alert.addTextField{ (textField: UITextField) -> Void in
            textField.placeholder = "Edit Item Name"
            textField.delegate = self
        }
        
        alert.addTextField{ (textField: UITextField) -> Void in
            textField.placeholder = "Edit Days Left"
            textField.keyboardType = .numbersAndPunctuation
            textField.delegate = self
        }

        
        present(alert, animated: true)
    }
    
    func deleteWarrantyFromDB(warranty: Warranties){
        self.managedObjectContext?.delete(warranty)
        do{
            try managedObjectContext?.save()
        }catch let error as NSError{
            print("Could not delete warranty \(error)")
        }
    }
    
    func saveWarrantyToDB(item: String, days: String, date: Date){
        let warranty = Warranties(context: managedObjectContext!)
        
        warranty.daysLeft = days
        warranty.itemName = item
        warranty.createdDate = date
        
        do{
            try self.managedObjectContext?.save()
            print("Warranty Saved")
            scheduleNotifications(days: days, item: item)
        }catch let error as NSError{
            print("Could not save Warranty. \(error), \(error.userInfo)")
        }
    }
    
    //MARK: - Get Starting Info
    
    func fetchWarrantyList(){
        let fetchRequest = NSFetchRequest<Warranties>()
        let entity = Warranties.entity()
        fetchRequest.entity = entity
        
        do{
            if let result = try managedObjectContext?.fetch(fetchRequest){
                if result.count > 0{
                    warranties = result
                    
                }
            }
        }catch let error as NSError{
            print("Could not fetch warranties. \(error), \(error.userInfo)")
        }
        setNewDaysLeft()
    }
    
    func getDefaultStates(){
        
        pushNotificationsToggleState = defaults.bool(forKey: "pushNotificationsToggle")
        warrantyAlertTime = defaults.integer(forKey: "warrantyAlertTime")
    }
    
    //MARK: - Functions
    
    func scheduleNotifications(days: String, item: String){
        let daysLeft = Int(days)! - warrantyAlertTime
        
        if daysLeft <= warrantyAlertTime{
            return
        }
        
        if pushNotificationsToggleState{
            
            let content = UNMutableNotificationContent()
            content.title = "Warranty Expiration Alert"
            content.body = "Warranty for \(item) is expiring in \(days) days."
            
            let today = Date()
            let targetDate = Calendar.current.date(byAdding: .day, value: daysLeft, to: today)
            
            let dateComponents = getComponentsFromDate(date: targetDate!)
            
            let trigger = UNCalendarNotificationTrigger.init(dateMatching: dateComponents, repeats: false)
            
            //let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: Double(daysLeft!), repeats: false)
            
            let request = UNNotificationRequest.init(identifier: "Warranty", content: content, trigger: trigger)
            
            let center = UNUserNotificationCenter.current()
            center.add(request) { (error) in
                print(error)
            }
            print("Notification created")
            
        }else{
            return
        }
    }
    
    func getComponentsFromDate(date: Date) -> DateComponents{
        let calender = Calendar.current
        
        let components = calender.dateComponents([.day, .month, .year, .hour], from: date)
        
        return components
    }
    
    func setNewDaysLeft(){
        let today = Date()
        for each in warranties{
            let targetDate = Calendar.current.date(byAdding: .day, value: Int(each.daysLeft!)!, to: each.createdDate!)
            let diffDateComponents = Calendar.current.dateComponents([.day], from: today, to: targetDate!)
            print(each.createdDate!)
            print(each.daysLeft)
            print(targetDate)
            print(diffDateComponents)
            if diffDateComponents.day! <= 0{
                each.daysLeft = "0"
            }else{
                each.daysLeft = String(diffDateComponents.day!)
            }
        }
        self.warrantyListTable.reloadData()

    }
    
    func closeKeyboard(){
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
}
