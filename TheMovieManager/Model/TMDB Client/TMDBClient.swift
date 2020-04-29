//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import UIKit

class TMDBClient {
  
  static let apiKey = "9877f663cbd88ef31651dad974c6ade4"
  
  struct Auth {
    static var accountId = 0
    static var requestToken = ""
    static var sessionId = ""
  }
  
  enum Endpoints {
    static let base = "https://api.themoviedb.org/3"
    static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
    static let redirectWebAuth = "?redirect_to=themoviemanager:authenticate"
    
    case getWatchlist
    case getFavorites
    case requestToken
    case login
    case session
    case webAuth
    case logout
    case search(String)
    case markWatchlist
    case markFavorite
    case posterImageURL(String)
    
    var stringValue: String {
      switch self {
        case .getFavorites: return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
        case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
        case .requestToken: return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
        case .login: return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
        case .session: return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
        case .webAuth: return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + Endpoints.redirectWebAuth
        case .logout: return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
        case .search(let query): return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        case .markWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
        case .markFavorite: return Endpoints.base + "/account/\(Auth.accountId)/favorite" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
        case .posterImageURL(let posterPath): return "https://image.tmdb.org/t/p/w500" + posterPath
      }
    }
    
    var url: URL {
      return URL(string: stringValue)!
    }
  }
  
  class func downloadPosterImage(posterPath: String, completion: @escaping (UIImage?, Error?) -> Void ) {
    let task = URLSession.shared.dataTask(with: Endpoints.posterImageURL(posterPath).url , completionHandler: { (data, response, error) in
      guard let data = data else {
        DispatchQueue.main.async {
          completion(nil, error)
        }
        return
      }
      let downloadedImage = UIImage(data: data)
      DispatchQueue.main.async {
        completion(downloadedImage, nil)
      }
    })
    
    task.resume()
  }
  
  class func markFavorite(movieId: Int, favorite: Bool, completion: @escaping (Bool, Error?) -> Void ) {
    let body = MarkFavorite(mediaType: "movie", mediaId: movieId, favorite: favorite)
    
    taskForPOSTRequest(url: Endpoints.markFavorite.url, body: body, response: TMDBResponse.self) { (response, error) in
      if let response = response {
        completion(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
      } else {
        completion(false, error)
      }
    }
  }
  
  class func markWatchlist(movieId: Int, watchlist: Bool, completion: @escaping (Bool, Error?) -> Void) {
    let body = MarkWatchlist(mediaType: "movie", mediaId: movieId, watchlist: watchlist)
    
    taskForPOSTRequest(url: Endpoints.markWatchlist.url, body: body, response: TMDBResponse.self) { (response, error) in
      if let response = response {
          completion(response.statusCode == 1 || response.statusCode == 12 || response.statusCode == 13, nil)
      } else {
        completion(false, error)
      }
    }
  }
  
  class func logout(completion: @escaping (Bool, Error?) -> Void ) {
    var request = URLRequest.init(url: Endpoints.logout.url)
    request.httpMethod = "DELETE"
    request.addValue("application/json", forHTTPHeaderField: "content-Type")
    
    let body = LogoutRequest(sessionId: Auth.sessionId)
    
    
    request.httpBody = try! JSONEncoder().encode(body)
    
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
      guard let data = data else { completion(false, error); return }
      do {
        let decoder = JSONDecoder()
        let logoutResponse = try decoder.decode(LogoutResponse.self, from: data)
        Auth.sessionId = ""
        Auth.requestToken = ""
        completion(logoutResponse.success, nil)
      } catch {
        completion(false, error)
      }
    }
    
    task.resume()
  }
  
  class func session(completion: @escaping (Bool, Error?) -> Void ) {
    let body = PostSession(requestToken: Auth.requestToken)
    taskForPOSTRequest(url: Endpoints.session.url, body: body, response: SessionResponse.self) { (response, error) in
      if let response = response {
        Auth.sessionId = response.sessionId
        completion(true, nil)
      } else {
        completion(false, error)
      }
    }
  }
  
  class func login(login: String, password: String, completion: @escaping (Bool, Error?) -> Void ) {
    let body = LoginRequest(username: login, password: password, requestToken: Auth.requestToken)
    
    taskForPOSTRequest(url: Endpoints.login.url, body: body, response: RequestTokenResponse.self) { (response, error) in
      if let response = response {
        Auth.requestToken = response.token
        completion(true, nil)
      }
      else {
        completion(false, error)
      }
    }
  }
  
  class func getRequestToken(completion: @escaping (Bool, Error?) -> Void) {
    taskForGETRequest(url: Endpoints.requestToken.url, response: RequestTokenResponse.self) { (response, error) in
      if let response = response {
        Auth.requestToken = response.token
        completion(true, nil)
      } else {
        completion(false, error)
      }
    }
  }
  
  class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
    taskForGETRequest(url: Endpoints.getWatchlist.url, response: MovieResults.self) { (response, error) in
      if let response = response {
        completion(response.results, nil)
      } else {
        completion([], error)
      }
    }
  }
  
  class func getFavorites(completion: @escaping ([Movie], Error?) -> Void) {
    taskForGETRequest(url: Endpoints.getFavorites.url, response: MovieResults.self) { (response, error) in
      if let response = response {
        completion(response.results, nil)
      } else {
        completion([], error)
      }
    }
  }
  
  class func search(query: String, completion: @escaping ([Movie], Error?) -> Void ) -> URLSessionTask {
    let task = taskForGETRequest(url: Endpoints.search(query).url, response: MovieResults.self) { (response, error) in
      if let response = response {
        completion(response.results, nil)
      } else {
        completion([], error)
      }
    }
    return task
  }
  
  @discardableResult class func taskForGETRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void ) -> URLSessionTask {
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
      guard let data = data else {
        DispatchQueue.main.async {
          completion(nil, error)
        }
        return
      }
      let decoder = JSONDecoder()
      do {
        let responseObject = try decoder.decode(ResponseType.self, from: data)
        DispatchQueue.main.async {
          completion(responseObject, nil)
        }
      } catch {
        do {
          let errorResponse = try decoder.decode(TMDBResponse.self, from: data) as Error
          DispatchQueue.main.async {
            completion(nil, errorResponse)
          }
        } catch {
          DispatchQueue.main.async {
            completion(nil, error)
          }
        }
      }
    }
    
    task.resume()
    
    return task
  }
  
  class func taskForPOSTRequest<ResponseType: Decodable, ResquestType: Codable>(url: URL, body: ResquestType, response: ResponseType.Type, completion: @escaping(ResponseType?, Error?) -> Void) {
    // Do stuff
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "content-Type")
    
    request.httpBody = try! JSONEncoder().encode(body)
    let task = URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) in
      guard let data = data else {
        DispatchQueue.main.async {
          completion(nil, error)
        }
        return
      }
      let decoder = JSONDecoder()
      do {
        let responseObject = try decoder.decode(ResponseType.self, from: data)
        DispatchQueue.main.async {
          completion(responseObject, nil)
        }
      } catch {
        do {
          let errorResponse = try decoder.decode(TMDBResponse.self, from: data) as Error
          DispatchQueue.main.async {
            completion(nil, errorResponse)
          }
        } catch {
          DispatchQueue.main.async {
            completion(nil, error)
          }
        }
        
      }
    })
    task.resume()
  }
  
}
