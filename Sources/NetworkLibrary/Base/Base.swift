//
//  Base.swift
//  NetworkLibrary
//
//  Created by Fernando Fuentes on 03/12/24.
//

import Foundation

public protocol Base {
    var scheme: String { get }
    var host: String { get }
    var version: String { get }
    var path: String { get }
    var method: RequestMethod { get }
    var header: [String: String]? { get }
    var parameters: [URLQueryItem]? { get }
    var body: Data? { get }
    var boundry: String? { get }
}
