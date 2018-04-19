//
//  ViewController.swift
//  CameraApp
//
//  Created by Todd on 10/16/16.
//  Copyright © 2016 Triadic Software. All rights reserved.
//

import UIKit
import CoreData

class PageViewController: UIPageViewController, UIPageViewControllerDataSource {
    
    var controllers = [UIViewController]()
    var context: NSManagedObjectContext?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("Page View Controller Loaded")
        context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        self.dataSource = self
        populateControllersArray()
        self.setViewControllers([controllers[1]] as [UIViewController], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let controller = viewController as? PageItem {
            if controller.itemIndex > 0 {
                return controllers[controller.itemIndex - 1]
            }
        }
        return nil
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?{
        if let controller = viewController as? PageItem {
            if controller.itemIndex < controllers.count - 1 {
                return controllers[controller.itemIndex + 1]
            }
        }
        return nil
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    //override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    //}
    
    public func showReceiptsListViewController(){
        self.setViewControllers([controllers[0]], direction: .reverse, animated: true, completion: nil)
    }
    
    public func showWarrantyListViewController(){
        self.setViewControllers([controllers[2]], direction: .forward, animated: true, completion: nil)
    }
    
    func populateControllersArray(){
        
        let controller3 = storyboard!.instantiateViewController(withIdentifier: "ReceiptListViewController") as! PageItem
        controller3.itemIndex = 0
        controllers.append(controller3)
        
        let controller2 = storyboard!.instantiateViewController(withIdentifier: "CameraViewController") as! PageItem
        controller2.itemIndex = 1
        controllers.append(controller2)
        
        let controller1 = storyboard!.instantiateViewController(withIdentifier: "WarrantyListViewController") as! PageItem
        controller1.itemIndex = 2
        controllers.append(controller1)

    }
    
    func getViewControllerAtIndex(index: Int) -> UIViewController{
        return controllers[index]
    }
    

}
