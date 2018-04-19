//
//  ReceiptListViewController.swift
//  CameraApp
//
//  Created by Todd on 10/18/16.
//  Copyright © 2016 Triadic Software. All rights reserved.
//

import UIKit
import CoreData

class ReceiptListViewController: PageItem, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var searchReceiptsBar: UISearchBar!
    @IBOutlet weak var receiptsListTable: UITableView!
    
    var receipts = [Receipts]()
    var receiptsSearching = [Receipts]()
    var isSearching = false
    var emailReceiptsToggle = false
    var fileMgr = FileManager()
    
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("Receipt List View Controller Loaded")
        
        receiptsListTable.tableFooterView = UIView(frame: CGRect.zero)
        
        searchReceiptsBar.delegate = self
        
        let parent = self.parent as? PageViewController
        managedObjectContext = parent?.context
        
        getDefaultState()
        fetchReceiptList()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ReceiptListViewController.closeKeyboard))
        tapGesture.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(tapGesture)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchReceiptList()
        receiptsListTable.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - TableView Delegate Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching{
            return receiptsSearching.count
        }else{
            return receipts.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReceiptCell") as! ReceiptCell
        
        if isSearching{
            let components = getComponentsFromDate(date: receiptsSearching[indexPath.row].date!)
            if let day = components.day{
                if let month = components.month{
                    cell.receiptDayMonth.text = "\(month)/\(day)"
                }
            }
            if let year = components.year{
                cell.receiptYear.text = "\(year)"
            }
            cell.receiptStore.text = receiptsSearching[indexPath.row].store
            cell.receiptTotal.text = "$" + receiptsSearching[indexPath.row].total!
            
        }else{
            let components = getComponentsFromDate(date: receipts[indexPath.row].date!)
            if let day = components.day{
                if let month = components.month{
                    cell.receiptDayMonth.text = "\(month)/\(day)"
                }
            }
            if let year = components.year{
                cell.receiptYear.text = "\(year)"
            }
            cell.receiptStore.text = receipts[indexPath.row].store
            cell.receiptTotal.text = "$" + receipts[indexPath.row].total!
        }
        return cell

    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete{
            if isSearching{
                let deleteReceipt = receiptsSearching.remove(at: indexPath.row)
                receiptsListTable.deleteRows(at: [indexPath], with: .top)
                deleteReceiptFromDB(receipt: deleteReceipt)
            }else{
                let deleteReceipt = receipts.remove(at: indexPath.row)
                receiptsListTable.deleteRows(at: [indexPath], with: .top)
                deleteReceiptFromDB(receipt: deleteReceipt)
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "AddReceipt"{
            let newReceiptController = segue.destination as! EditReceiptViewController
            newReceiptController.managedObjectContext = managedObjectContext
        }else if segue.identifier == "EditReceipt"{
            let editReceiptController = segue.destination as! EditReceiptViewController
            editReceiptController.managedObjectContext = managedObjectContext
            if let indexPath = receiptsListTable.indexPath(for: sender as! ReceiptCell){
                if isSearching{
                    let receipt = receiptsSearching[indexPath.row]
                    editReceiptController.receiptToEdit = receipt
                }else{
                    let receipt = receipts[indexPath.row]
                    editReceiptController.receiptToEdit = receipt
                }
            }
        }
    }
    
    //MARK: - CRUD Functions
    
    func deleteReceiptFromDB(receipt: Receipts){
        if fileMgr.fileExists(atPath: getPathForFileName(fileName: receipt.imageLocation)){
            do{
                try fileMgr.removeItem(atPath: getPathForFileName(fileName: receipt.imageLocation))
            }catch let error as NSError{
                print("Could not remove media file \(error)")
            }
            self.managedObjectContext?.delete(receipt)
            do{
                try managedObjectContext?.save()
            }catch let error as NSError{
                print("Could not delete receipt \(error)")
            }
        }
    }
    
    //MARK: - TableView Functions

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchReceiptsBar.text!.isEmpty{
            isSearching = false
            receiptsListTable.reloadData()
        }else{
            isSearching = true
            receiptsSearching.removeAll(keepingCapacity: false)
            
            for each in 0..<receipts.count{
                let listItem = receipts[each]
                if listItem.store?.lowercased().range(of: self.searchReceiptsBar.text!.lowercased()) != nil {
                    receiptsSearching.append(listItem)
                }
            }
            receiptsListTable.reloadData()
        }
    }
    
    @IBAction func sortReceiptsBtn(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Sort Receipts",
                                      message: "Choose how to sort your receipt list",
                                      preferredStyle: .alert)
        
        let storeSort = UIAlertAction(title: "Sort by store", style: .default){
            [unowned self] action in
            self.receipts.sort{
                ($0.store?.lowercased())! < ($1.store?.lowercased())!
            }
            self.receiptsListTable.reloadData()
        }
        
        let totalSort = UIAlertAction(title: "Sort by total", style: .default){
            [unowned self] action in
            self.receipts.sort{
                Double($0.total!)! < Double($1.total!)!
            }
            self.receiptsListTable.reloadData()
        }
        
        let dateSort = UIAlertAction(title: "Sort by date", style: .default){
            [unowned self] action in
            self.receipts.sort{
                $0.date! < $1.date!
            }
            self.receiptsListTable.reloadData()
        }
        
        alert.addAction(storeSort)
        alert.addAction(totalSort)
        alert.addAction(dateSort)
        
        present(alert, animated: true)
    }
    
    func getComponentsFromDate(date: Date) -> DateComponents{
        let calender = Calendar.current
        
        let components = calender.dateComponents([.day, .month, .year, .hour], from: date)
        
        return components
    }

    //MARK: - Get Starting Info
    
    func getDefaultState(){
        emailReceiptsToggle = defaults.bool(forKey: "emailReceiptsToggle")
    }
    
    func fetchReceiptList(){
        let fetchRequest = NSFetchRequest<Receipts>()
        let entity = Receipts.entity()
        fetchRequest.entity = entity
        
        do{
            if let result = try managedObjectContext?.fetch(fetchRequest){
                if result.count > 0{
                    receipts = result
                    
                }
            }
        }catch let error as NSError{
            print("Could not fetch receipts. \(error), \(error.userInfo)")
        }
    }
    
    func closeKeyboard(){
        self.view.endEditing(true)
    }
    
}
