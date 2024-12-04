//
//  Encodable+Extensions.swift
//  NetworkLibrary
//
//  Created by Fernando Fuentes on 04/12/24.
//

import Foundation

extension Encodable {
    
    public func toData() -> Data? {
        do {
            let data = try JSONEncoder().encode(self)
            return data
        } catch {
            debugPrint("Error encoding object to data: \(error)")
            return nil
        }
    }
    
}
