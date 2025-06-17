//
//  Temperature.swift
//  ExampleMVVM
//
//  Created by MacBook Air M1 on 19/6/24.
//

import Foundation

public struct TemperatureModel: Equatable {
    
    // MARK: - Properties
    
    public let current: Double
    public let min: Double?
    public let max: Double?
    public let feelsLike: Double?
    
    public init(current: Double, min: Double? = nil, max: Double? = nil, feelsLike: Double? = nil) {
        self.current = current
        self.min = min
        self.max = max
        self.feelsLike = feelsLike
    }
}
