//
//  ViewController.swift
//  Meetup Spot
//
//  Created by Javon Davis on 6/24/19.
//  Copyright © 2019 Javon Davis. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func goButtonClicked(_ sender: Any) {
        performSegue(withIdentifier: "showMainController", sender: nil)
    }
    
}

