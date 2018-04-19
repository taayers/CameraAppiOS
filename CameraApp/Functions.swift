//
//  Functions.swift
//  CameraApp
//
//  Created by Todd on 11/4/16.
//  Copyright © 2016 Triadic Software. All rights reserved.
//

import Foundation
import UIKit
import CoreData

let applicationDocumentsDirectory: String = {
    let paths = NSSearchPathForDirectoriesInDomains(
        .documentDirectory, .userDomainMask, true)
    return paths[0]
}()

func getPathForFileName(fileName: String) -> String{
    return (applicationDocumentsDirectory as NSString).appendingPathComponent(fileName)
}

func getNextID() -> Int {
    let userDefaults = UserDefaults.standard
    let currentID = userDefaults.integer(forKey: "PhotoID")
    userDefaults.set(currentID + 1, forKey: "PhotoID")
    userDefaults.synchronize()
    
    return currentID
}


