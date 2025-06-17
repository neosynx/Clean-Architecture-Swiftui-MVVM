//
//  WeatherConditionModel.swift
//  StarterApp
//
//  Created by ryan arter on 2025/06/17.
//

import Foundation

public struct WeatherConditionModel: Equatable {
    public let type: WeatherType
    public let iconCode: String?
    
    public init(type: WeatherType, iconCode: String? = nil) {
        self.type = type
        self.iconCode = iconCode
    }
}
