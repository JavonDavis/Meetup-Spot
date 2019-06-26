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
    private let baseUrl = "https://api.teleport.org/api/"
    public static let shared = DataManager()
    
    let session = URLSession.shared
    
    private func searchResultToCities(citySearchResult: SearchResult) -> [City] {
        var cities = [City]()
        for searchResult in citySearchResult._embedded.citySearchResults {
            let link = searchResult._links.cityItem.href
            let id = link.lastPathComponent
            cities.append(City(id: id, name: searchResult.matching_full_name))
        }
        return cities
    }
    
    func getCitiesMatching(name: String, completion: @escaping ([City]) -> Void) {
        let searchURL = baseUrl + "cities/"
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
                let cities = self.searchResultToCities(citySearchResult: searchResult)
                print("Found \(cities.count) cities")
                completion(cities)
                // TODO: - Call closure with City data
            } catch {
                print("Could not create search result:\(error.localizedDescription)")
            }
            
        }
        task.resume()
    }
}

// MARK: - Data models


struct City {
    let id: String
    let name: String
}

// MARK: - Decodable Structs for Search Result
// TODO: Move outside of this file

struct CityItem: Decodable {
    let href: URL
    
    init(href: URL) {
        self.href = href
    }
}

struct Links {
    let cityItem: CityItem
    
    init(cityItem: CityItem) {
        self.cityItem = cityItem
    }
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
    
    init(_links: Links, matching_full_name: String) {
        self._links = _links
        self.matching_full_name = matching_full_name
    }
}

struct EmbeddedSearchResult {
    let citySearchResults: [CitySearchResult]
    
    init(citySearchResults: [CitySearchResult]) {
        self.citySearchResults = citySearchResults
    }
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
    
    init(_embedded: EmbeddedSearchResult) {
        self._embedded = _embedded
    }
}
