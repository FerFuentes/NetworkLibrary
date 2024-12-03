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


extension Base {
    public func createDataBody(withParameters params: [String: String]?, media: [Media]?) -> Data? {
        let lineBreak = "\r\n"
        var body = Data()
        
        guard let boundary = self.boundry else {
            return nil
        }

        if let parameters = params {
            for (key, value) in parameters {
                body.append("--\(boundary + lineBreak)".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)".data(using: .utf8)!)
                body.append("\(value + lineBreak)".data(using: .utf8)!)
            }
        }

        if let media = media {
            for photo in media {
                body.append("--\(boundary + lineBreak)".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(photo.key)\"; filename=\"\(photo.fileName)\"\(lineBreak)".data(using: .utf8)!)
                body.append("Content-Type: \(photo.mimeType + lineBreak + lineBreak)".data(using: .utf8)!)
                body.append(photo.data)
                body.append(lineBreak.data(using: .utf8)!)
            }
        }

        body.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)

        return body
    }
}
