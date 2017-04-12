//
//  FatalErrorViewController.swift
//  EasyLife
//
//  Created by Lee Arromba on 12/04/2017.
//  Copyright © 2017 Pink Chicken Ltd. All rights reserved.
//

import UIKit

class FatalViewController: UIViewController {
    @IBOutlet var label: UILabel!
    
    var error: Error?
    
    override func viewDidLoad() {
        if let error = error {
            label.text = "Error loading data. Please restart the app and try again.\n\nDetailed error:\n\(error.localizedDescription)"//TODO: localise
        }
    }
}
