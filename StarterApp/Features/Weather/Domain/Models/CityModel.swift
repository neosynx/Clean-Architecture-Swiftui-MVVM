//
//  City.swift
//  ExampleMVVM
//
//  Created by MacBook Air M1 on 19/6/24.
//

import Foundation

public struct CityModel: Equatable {
    
    // MARK: - Parameters
    
    public let name: String
    public let country: String
    
    public init(name: String, country: String) {
        self.name = name
        self.country = country
    }
}
