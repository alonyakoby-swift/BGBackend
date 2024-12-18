import Vapor
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(Combine)
import Combine
#else
import OpenCombine
import OpenCombineFoundation
#endif

class DataSourceGateway {
    private let baseUrl = "https://webservicefiles-bergner.com"
    var accessToken: String?
    private var cancellables = Set<AnyCancellable>()
    
    // Authentication
    func authenticate(username: String, password: String) -> AnyPublisher<Void, Error> {
        let url = URL(string: "\(baseUrl)/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "username": username,
            "password": password,
            "grant_type": "password",
            "client_id": "2",
            "client_secret": "SjdmevjDnsE0LRAHFBMJK1wkOO9Pav8Ki19DGkr4"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                guard httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
            .map { authResponse in
                self.accessToken = authResponse.access_token
                print("Authenticated successfully")
            }
            .eraseToAnyPublisher()
    }

    // Fetch Products List with Pagination
    func fetchProductsList(page: Int, perPage: Int) -> AnyPublisher<ProductListResponse, Error> {
        guard let token = accessToken else {
            return Fail(error: URLError(.userAuthenticationRequired)).eraseToAnyPublisher()
        }
        
        let url = URL(string: "\(baseUrl)/api/articles?with=[\"Files\"]&pagination={\"page\":\(page),\"pageLength\":\(perPage)}")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                guard httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: ProductListResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    // Fetch Products List without Pagination
    func fetchProductsList() -> AnyPublisher<ProductListResponse, Error> {
        guard let token = accessToken else {
            return Fail(error: URLError(.userAuthenticationRequired)).eraseToAnyPublisher()
        }

        let url = URL(string: "\(baseUrl)/api/articles")! // Without Documents
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 900 // Set the timeout interval directly on the request

        return URLSession.shared.dataTaskPublisher(for: request)
            .retry(3) // Retry the request up to 3 times
            .timeout(.seconds(900), scheduler: RunLoop.main)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                guard httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: ProductListResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }


    // Fetch Product Detail by ID
    func fetchProductDetail(by id: String) -> AnyPublisher<Product, Error> {
        guard let token = accessToken else {
            return Fail(error: URLError(.userAuthenticationRequired)).eraseToAnyPublisher()
        }
        
        let url = URL(string: "\(baseUrl)/api/articles/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                guard httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: Product.self, decoder: JSONDecoder())
            .map { product in
                print("Fetched product detail: \(product)")
                return product
            }
            .eraseToAnyPublisher()
    }

    // Fetch Product Detail by ProductCode
    func fetchProductCode(by code: String) -> AnyPublisher<Product, Error> {
        guard let token = accessToken else {
            return Fail(error: URLError(.userAuthenticationRequired)).eraseToAnyPublisher()
        }
        
        let url = URL(string: "\(baseUrl)/api/articles/byCode/\(code)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                guard httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: Product.self, decoder: JSONDecoder())
            .map { product in
                return product
            }
            .eraseToAnyPublisher()
    }
}

// Models
struct AuthResponse: Decodable {
    let token_type: String
    let expires_in: Int
    let access_token: String
    let refresh_token: String
}

struct ProductListResponse: Decodable {
    let data: [Product]
    let current_page: Int?
    let last_page: Int?
}
