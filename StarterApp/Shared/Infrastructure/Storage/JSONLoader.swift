//
//  JSONLoader.swift
//  ExampleMVVM
//
//  Created by MacBook Air M1 on 20/6/24.
//

import Foundation

class JSONLoader {
    func loadJSON(filename: String, logger: AppLogger? = nil) -> Data? {
        if let url = Bundle.main.url(forResource: filename, withExtension: "json") {
            do {
                return try Data(contentsOf: url)
            } catch {
                if let logger = logger {
                    logger.error("Error loading local JSON file: \(error)")
                } else {
                    print("Error loading local JSON file: \(error)")
                }
            }
        }
        return nil
    }
}


