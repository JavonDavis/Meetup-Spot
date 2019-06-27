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
    var cities = [City]()
    var chosenCities = [City]()
    var cityTracker: Set<City> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchResultsTableView.maxHeight = 372
        locationsTableView.setEmptyView(title: "No Locations", message: "You haven't entered any locations as yet")
        
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        
        locationsTableView.delegate = self
        locationsTableView.dataSource = self
        
        newLocationTextField.addTarget(self, action: #selector(locationSearchFieldChanged(_:)), for: .editingChanged)
    }
    
    @IBAction func onSubmitClick(_ sender: Any) {
        dataManager.getFlockData(for: chosenCities)
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
            cell.cityNameLabel.text = cities[indexPath.row].name
            return cell
        case locationsTableView:
            let cell = tableView.dequeueReusableCell(withIdentifier: "locationChoiceCell", for: indexPath) as! LocationChoiceTableViewCell
            cell.cityNameLabel.text = chosenCities[indexPath.row].name
            return cell
        default:
            // TODO raise error?
            print("Unhandled TableView \(tableView)")
            return UITableViewCell()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch tableView {
        case searchResultsTableView:
            return 1
        case locationsTableView:
            return 1
        default:
            // TODO raise error?
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case searchResultsTableView:
            return cities.count
        case locationsTableView:
            return chosenCities.count
        default:
            // TODO raise error?
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch tableView {
        case locationsTableView:
            let city = self.chosenCities[indexPath.row]
            if editingStyle == .delete {
                cityTracker.remove(city)
                chosenCities.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        default:
            print("Unhandlede TableView: \(tableView)")
        }
    }
}

extension LocationSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch tableView {
        case searchResultsTableView:
            // Get the city
            let city = cities[indexPath.row]
            
            // Clear and reload the search field
            newLocationTextField.text = ""
            locationSearchFieldChanged(newLocationTextField)
            
            // If the city isn't already chosen
            if !cityTracker.contains(city) {
                cityTracker.insert(city)
                chosenCities.append(city)
                
                locationsTableView.restore()
                locationsTableView.reloadData()
            }
        default:
            print("Unknown TableView \(tableView)")
        }
    }
}

// MARK: - Search Text field functions


extension LocationSearchViewController {
    @objc func locationSearchFieldChanged(_ textField: UITextField) {
        guard let searchText = textField.text, !searchText.isEmpty else {
            cities = []
            searchResultsTableView.reloadData()
            return
        }
        dataManager.getCitiesMatching(name: searchText) { cities in
            self.cities = cities
            DispatchQueue.main.async {
                self.searchResultsTableView.reloadData()
            }
        }
        self.searchResultsTableView.reloadData()
    }
}
