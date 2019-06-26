//
//  LocationSearchViewController.swift
//  Meetup Spot
//
//  Created by Javon Davis on 6/25/19.
//  Copyright © 2019 Javon Davis. All rights reserved.
//

import UIKit

class LocationSearchViewController: UIViewController {

    @IBOutlet weak var newLocationTextField: UITextField!
    @IBOutlet weak var locationsTableView: UITableView!
    @IBOutlet weak var searchResultsTableView: SelfSizedTableView!
    @IBOutlet weak var submitButton: UIButton!
    
    let dataManager = DataManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchResultsTableView.maxHeight = 372
        locationsTableView.setEmptyView(title: "No Locations", message: "You haven't entered any locations as yet")
        
        self.searchResultsTableView.delegate = self
        self.searchResultsTableView.dataSource = self
        
        self.locationsTableView.delegate = self
        self.locationsTableView.dataSource = self
    }
    
    @IBAction func onSubmitClick(_ sender: Any) {
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

extension LocationSearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case searchResultsTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchResultsCell", for: indexPath) as! SearchResultTableViewCell
            cell.label.text = "San Franciso, California"
            return cell
        default:
            // TODO raise error?
            print("Unhandled TableView \(tableView)")
            return UITableViewCell()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sections: Int
        switch tableView {
        case searchResultsTableView:
            sections = 1
        default:
            // TODO raise error?
            sections = 0
        }
        return sections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows: Int
        switch tableView {
        case searchResultsTableView:
            rows = 0
        default:
            // TODO raise error?
            rows = 0
        }
        return rows
    }
}

extension LocationSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
