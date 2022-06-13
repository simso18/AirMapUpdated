////
////  custom.swift
////  AirMapUpdated
////
////  Created by laptop on 12/04/2022.
////
//import Foundation
//import SwiftUI
//import Combine
//
//class HttpAuth: ObservableObject {
//
//    @Published var authenticated = false
//
//    func postAuth(username: String, password: String){
//        guard let url = URL(string: "http://mysite/loginswift.php") else { return }
//
//        let body: [String: String] = ["username": username, "password": password]
//
//        let finalBody = try! JSONSerialization.data(withJSONObject: body)
//
////        var request = URLRequest(url: url)
////        request.httpMethod = "POST"
////        request.httpBody = finalBody
////        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        URLSession.shared.dataTask(with: url) { (data, response, error) in
//            guard let data = data else { return }
//            if let resData = try? JSONDecoder().decode(Response.self, from: data){
//                finResults = resData.results
//            }
//        }.resume()
//    }
//}
//
//struct Response: Codable {
//    var results: [Result]
//}
//
//struct Result: Codable {
//    var trackId: Int
//    var trackName: String
//    var collectionName: String
//}
//
