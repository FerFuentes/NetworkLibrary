//
//  RequestError.swift
//  NetworkLibrary
//
//  Created by Fernando Fuentes on 03/12/24.
//

public enum RequestError: Error, Equatable {
    case decode
    case invalidURL
    case noResponse
    case badRequest(String?)
    case unauthorized
    case unexpectedStatusCode(String)
    case unexpectedError(String)
    case unknown
    case internetConnection(String)

    public var customMessage: String {
        switch self {
        case .decode:
            return "Decode error"
            
        case .unauthorized:
            return "Please check that you are logged in the app"
            
        case .unexpectedStatusCode(let message), .unexpectedError(let message), .internetConnection(let message):
            return message
            
        case .badRequest(let message):
            return message ?? "We are unable to retrieve your information at this time, please try again later."
            
        default:
            return "We are unable to retrieve your information at this time, please try again later."
        }
    }
}
