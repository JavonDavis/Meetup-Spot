import UIKit
import Foundation
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

let baseUrl = "https://api.teleport.org/api/"

let searchURL = baseUrl + "cities/"
var components = URLComponents(string: searchURL)!
let name = "san"
components.queryItems = ["search": name].map { (key, value) in
    URLQueryItem(name: key, value: value)
}

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

let json = """
{
"_embedded": {
"city:search-results": [
{
"_links": {
"city:item": {
"href": "https://api.teleport.org/api/cities/geonameid:5391959/"
}
},
"matching_alternate_names": [
{
"name": "San Francisco"
}
],
matching_full_name: "San Francisco, California, United States"
},
...
]
},
"_links": {
"self": {
"href": "https://api.teleport.org/api/cities/?search=san francisco"
}
},
"count": 25
}
""".data(using: .utf8)

let session = URLSession.shared
let request = try! URLRequest(url: components.url!)
let task = session.dataTask(with: request) { (data, response, error) in

    print("Response: \(String(describing: response))")
    print("Error: \(String(describing: error))")
    do {
        guard let data = data, let response = response as? HTTPURLResponse, (200 ..< 300) ~= response.statusCode, error == nil else {
            throw error ?? "Error in request" as! Error
        }
        let searchResult = try JSONDecoder().decode(SearchResult.self, from: data)
        print(searchResult._embedded.citySearchResults[0].matching_full_name)
        let cities = searchResultToCities(citySearchResult: searchResult)
        print(cities)
    } catch {
        print("Could not create search result:\(error.localizedDescription)")
    }
    
}
task.resume()

struct City {
    let id: String
    let name: String
}

func searchResultToCities(citySearchResult: SearchResult) -> [City] {
    var cities = [City]()
    for searchResult in citySearchResult._embedded.citySearchResults {
        let link = searchResult._links.cityItem.href
        let id = link.lastPathComponent
        cities.append(City(id: id, name: searchResult.matching_full_name))
    }
    return cities
}

