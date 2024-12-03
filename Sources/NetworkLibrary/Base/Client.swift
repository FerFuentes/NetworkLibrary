//
//  Client.swift
//  NetworkLibrary
//
//  Created by Fernando Fuentes on 03/12/24.
//
import Foundation
import Network

public protocol Client {
    func sendRequest<T: Decodable>(endpoint: Base, responseModel: T.Type) async -> Result<T, RequestError>
    func sendRequest<T: Decodable>(delegate: URLSessionDelegate, identifier: String, endpoint: Base, responseModel: T.Type)
    func getModelFromLocation<T: Decodable>(_ session: URLSession, downloadTask: URLSessionDownloadTask, location: URL, responseModel: T.Type) -> Result<T, RequestError>
}

extension Client {
    public func sendRequest<T: Decodable>(
        endpoint: Base,
        responseModel: T.Type
    ) async -> Result<T, RequestError> {
        var urlComponents = URLComponents()
        urlComponents.scheme = endpoint.scheme
        urlComponents.host = endpoint.host
        urlComponents.path = endpoint.version + endpoint.path
        urlComponents.queryItems = endpoint.parameters
        
        guard let url = urlComponents.url else {
            return .failure(.invalidURL)
        }
        
        do {
            
            var request = URLRequest(url: url)
            request.httpMethod = endpoint.method.rawValue
            request.allHTTPHeaderFields = endpoint.header
            
            if let body = endpoint.body {
                request.httpBody = body
            }
            
            let sessionConfiguration = URLSessionConfiguration.ephemeral
            sessionConfiguration.timeoutIntervalForRequest = 15
            sessionConfiguration.timeoutIntervalForResource = 15
            sessionConfiguration.sessionSendsLaunchEvents = false
            
            let session = URLSession(configuration: sessionConfiguration)
            let (data, response) = try await session.data(for: request)
            session.finishTasksAndInvalidate()
            
            guard let response = response as? HTTPURLResponse else {
                return .failure(.noResponse)
            }
            
            debugPrint("📤 [Client] Request: \(request), Code: \(response.statusCode)")
            
            switch response.statusCode {
                
            case 200...299:
                do {
                    let decodedResponse = try JSONDecoder().decode(responseModel, from: data)
                    debugPrint("📥 [Client] Response: \(decodedResponse)")
                    return .success(decodedResponse)
                } catch {
                    debugPrint("❌ [Client] Decode error: \(error.localizedDescription)")
                    return .failure(.unexpectedError(error.localizedDescription))
                }
            case 400:
                do {
                    let decodedResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                    let message = decodedResponse.message
                    debugPrint("❌ [Client] Error Response: \(decodedResponse)")
                    return .failure(.badRequest(message))
                } catch {
                    debugPrint("❌ [Client] Decode error: \(error.localizedDescription)")
                    return .failure(.unexpectedError(error.localizedDescription))
                }
                
            case 401:
                debugPrint("❌ [Client] Unauthorized")
                return .failure(.unauthorized)
                
            default:
                debugPrint("❌ [Client] Unexpected StatusCode: \(response.statusCode)")
                return .failure(.unexpectedStatusCode("We are unable to retrieve your information at this time, please try again later."))
            }
        } catch let error as NSError {
            
            switch error.code {
            case NSURLErrorNotConnectedToInternet,
                NSURLErrorNetworkConnectionLost,
            NSURLErrorTimedOut:
                return .failure(.internetConnection(error.localizedDescription))
            default:
                return .failure(.unknown)
            }
            
        }
    }
    
}

extension Client {
    public func sendRequest<T: Decodable>(
        delegate: URLSessionDelegate,
        identifier: String,
        endpoint: Base,
        responseModel: T.Type
    ) {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = endpoint.scheme
        urlComponents.host = endpoint.host
        urlComponents.path = endpoint.version + endpoint.path
        urlComponents.queryItems = endpoint.parameters
        
        let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: identifier)
        sessionConfiguration.timeoutIntervalForRequest = 15
        sessionConfiguration.timeoutIntervalForResource = 15
        sessionConfiguration.isDiscretionary = false
        
        guard let url = urlComponents.url
        else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.header
        
        if let body = endpoint.body {
            request.httpBody = body
        }
        
        debugPrint("📤 [Client-Background] Request: \(request)")
        let backgroundSession = URLSession(configuration: sessionConfiguration, delegate: delegate, delegateQueue: nil)
        backgroundSession.downloadTask(with: request).resume()
        
    }
    
}

extension Client {
    
    public func getModelFromLocation<T: Decodable>(_ session: URLSession, downloadTask: URLSessionDownloadTask, location: URL, responseModel: T.Type) -> Result<T, RequestError> {
        
        guard let response = downloadTask.response as? HTTPURLResponse else {
            session.invalidateAndCancel()
            return .failure(.noResponse)
        }
        
        session.finishTasksAndInvalidate()
        switch response.statusCode {
            
        case 200...299:
            
            do {
                let data = try Data(contentsOf: location)
                let decodedResponse = try JSONDecoder().decode(responseModel, from: data)
                debugPrint("📥  [Client-Background] Response: \(decodedResponse)")
                return .success(decodedResponse)
            } catch {
                debugPrint("❌ [Client-Background] Decode error: \(error.localizedDescription)")
                return .failure(.unexpectedError(error.localizedDescription))
            }
            
        case 400:
            do {
                let data = try Data(contentsOf: location)
                let decodedResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                let message = decodedResponse.message
                debugPrint("❌ [Client-Background] Error Response: \(decodedResponse)")
                return .failure(.badRequest(message))
            } catch {
                debugPrint("❌ [Client-Background] Decode error: \(error.localizedDescription)")
                return .failure(.unexpectedError(error.localizedDescription))
            }
            
        case 401:
            return .failure(.unauthorized)
            
        default:
            debugPrint("❌ [Client-Background] Unexpected StatusCode: \(response.statusCode)")
            return .failure(.unexpectedStatusCode("We are unable to retrieve your information at this time, please try again later."))
        }
    }
    
    func handleError(_ session: URLSession, error: Error?) {
        
        if let error = error {
            debugPrint("❌ [Client-Background] \(session.configuration.identifier ?? "UNKNOW") fetch error: \(error)")
            session.invalidateAndCancel()
        }
        
    }
}
