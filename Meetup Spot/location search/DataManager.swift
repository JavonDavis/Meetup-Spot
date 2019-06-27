//
//  DataManager.swift
//  Meetup Spot
//
//  Created by Javon Davis on 6/24/19.
//  Copyright © 2019 Javon Davis. All rights reserved.
//

import Foundation

class DataManager {
    
    // Teleport base URL
    private let baseURL = "https://api.teleport.org/api/"
    public static let shared = DataManager()
    
    let session = URLSession.shared
    
    private init() {}
    
    private func getLatLonForCity(withId id: String, completion: @escaping (Float, Float) -> Void) {
        let queryURL = "\(baseURL)cities/\(id)"
        
        var components = URLComponents(string: queryURL)!
        components.queryItems = ["city_id": id].map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
        
        let request = URLRequest(url: components.url!)
        let task = session.dataTask(with: request) { (data, response, error) in
            do {
                guard let data = data, let response = response as? HTTPURLResponse, (200 ..< 300) ~= response.statusCode, error == nil else {
                    throw error ?? "Error in request" as! Error
                }
                
                let cityQueryResult = try JSONDecoder().decode(CityInformationResult.self, from: data)
                completion(cityQueryResult.location.latlon.latitude, cityQueryResult.location.latlon.longitude)
            } catch {
                print("Could not look up city:\(error.localizedDescription)")
            }
        }
        task.resume()
    }
    
    private func searchResultToCities(citySearchResult: SearchResult, completion: @escaping ([City]) -> Void) {
        var cities = [City]()
        let dispatchGroup = DispatchGroup()
        for searchResult in citySearchResult._embedded.citySearchResults {
            dispatchGroup.enter()
            
            let link = searchResult._links.cityItem.href
            let id = link.lastPathComponent
            getLatLonForCity(withId: id) { (latitude, longitude) in
                cities.append(City(id: id, name: searchResult.matching_full_name, lat: latitude, lon: longitude))
                dispatchGroup.leave()
            }
            
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(cities)
        }
    }
    
    func getCitiesMatching(name: String, completion: @escaping ([City]) -> Void) {
        let searchURL = baseURL + "cities/"
        var components = URLComponents(string: searchURL)!
        components.queryItems = ["search": name].map { (key, value) in
            URLQueryItem(name: key, value: value)
        }
        
        let request = URLRequest(url: components.url!)
        let task = session.dataTask(with: request) { (data, response, error) in
            do {
                guard let data = data, let response = response as? HTTPURLResponse, (200 ..< 300) ~= response.statusCode, error == nil else {
                    throw error ?? "Error in request" as! Error
                }
                let searchResult = try JSONDecoder().decode(SearchResult.self, from: data)
                self.searchResultToCities(citySearchResult: searchResult) { cities in
                    completion(cities)
                }
            } catch {
                print("Could not create search result:\(error.localizedDescription)")
            }
            
        }
        task.resume()
    }
    
    func getFlockData(for cities: [City]) {
        var peopleGroupJson = ["people_groups":[]]
        for city in cities {
            let peopleGroup = [
                "number_of_people": 3,
                "source_city": [
                    "latitude": city.lat,
                    "longitude": city.lon
                ]
                ] as [String : Any]
            peopleGroupJson["people_groups"]?.append(peopleGroup)
        }
        let peopleGroupJsonData = try? JSONSerialization.data(withJSONObject: peopleGroupJson)
        
        let flockURL = baseURL + "flock/plans/"
        var request = URLRequest(url: URL(string: flockURL)!)
        request.httpMethod = "POST"
        request.httpBody = peopleGroupJsonData
        
        let task = session.dataTask(with: request) { data, response, error in
            print(response)
            do {
                guard let data = data, let response = response as? HTTPURLResponse, (200 ..< 300) ~= response.statusCode, error == nil else {
                    throw error ?? "Error in request" as! Error
                }
                let flockResult = try JSONDecoder().decode(FlockResult.self, from: data)
                print(flockResult.numberOfPeopleTravelling)
            } catch {
                print("Could not POST PLAN:\(error.localizedDescription)")
            }
            
        }
        task.resume()
    }
}

// MARK: - Data models


struct City: Hashable {
    let id: String
    let name: String
    let lat: Float
    let lon: Float
}

// MARK: - Decodable Structs for Search Result
// TODO: Move outside of this file

struct CityItem: Decodable {
    let href: URL
}

struct Links {
    let cityItem: CityItem
}

extension Links: Decodable {
    enum LinksKeys: String, CodingKey {
        case cityItem = "city:item"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: LinksKeys.self)
        let cityItem: CityItem = try container.decode(CityItem.self, forKey: .cityItem)
        
        self.init(cityItem: cityItem)
    }
}

struct CitySearchResult: Decodable {
    let _links: Links
    let matching_full_name: String
}

struct EmbeddedSearchResult {
    let citySearchResults: [CitySearchResult]
}

extension EmbeddedSearchResult: Decodable {
    enum EmbeddedSearchKeys: String, CodingKey {
        case citySearchResults = "city:search-results"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: EmbeddedSearchKeys.self)
        let citySearchResults = try container.decode([CitySearchResult].self, forKey: .citySearchResults)
        
        self.init(citySearchResults: citySearchResults)
    }
}

struct SearchResult: Decodable {
    let _embedded: EmbeddedSearchResult
}


// MARK: - City Info query Decodables


struct LatLon: Decodable {
    let latitude: Float
    let longitude: Float
}

struct CityLocation: Decodable {
    let latlon: LatLon
}

struct CityInformationResult: Decodable {
    let location: CityLocation
}


// MARK: - Flock Query Decodables

struct PeopleGroup: Decodable {
    let costUsd: Double
    let departureDate: Date
    let destinationAirport: String
    let distanceKm: Double
    let flightTimeH: Double
    let numberOfHops: Int
    let numberOfPeople: Int
    let returnDate: String
    let sourceAirport: String
    let timeeH: Double
}

struct FlockCity: Decodable {
    let country: String
    let name: String
    let title: String
    let latitude: Float
    let longitude: Float
}

struct FlockResult: Decodable {
    let averageTimeHPerTravellingPerson: Double
    let city: FlockCity
    let isHome: Bool
    let numberOfPeopleTravelling: Int
    let peopleGroupd: [PeopleGroup]
    let totalCostUsd: Double
    let totalDistanceKm: Double
    let totalFlightTimeH: Double
    let totalFlights: Int
    let totalLayovers: Int
    let totalRouteLayovers: Int
    let totalRoutes: Int
    let totalTickets: Int
    let totalTimeH: Double
}
