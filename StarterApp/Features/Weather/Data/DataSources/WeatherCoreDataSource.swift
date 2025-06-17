//
//  WeatherCoreDataSource.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation
import CoreData

class WeatherCoreDataSource: WeatherLocalDataSource {
    private let persistentContainer: NSPersistentContainer
    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    func fetchWeather(for city: String) async throws -> ForecastFileDTO? {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let request = NSFetchRequest<WeatherEntity>(entityName: "WeatherEntity")
                request.predicate = NSPredicate(format: "cityName == %@", city)
                request.fetchLimit = 1
                
                do {
                    let entities = try self.context.fetch(request)
                    if let entity = entities.first,
                       let jsonData = entity.jsonData {
                        let forecast = try JSONDecoder().decode(ForecastFileDTO.self, from: jsonData)
                        continuation.resume(returning: forecast)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: WeatherRepositoryError.storageError)
                }
            }
        }
    }
    
    func saveWeather(_ forecast: ForecastFileDTO) async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    // Delete existing entity if it exists
                    let request = NSFetchRequest<WeatherEntity>(entityName: "WeatherEntity")
                    request.predicate = NSPredicate(format: "cityName == %@", forecast.cityName)
                    
                    let existingEntities = try self.context.fetch(request)
                    for entity in existingEntities {
                        self.context.delete(entity)
                    }
                    
                    // Create new entity
                    let entity = WeatherEntity(context: self.context)
                    entity.cityName = forecast.cityName
                    entity.jsonData = try JSONEncoder().encode(forecast)
                    entity.lastUpdated = Date()
                    
                    try self.context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: WeatherRepositoryError.storageError)
                }
            }
        }
    }
    
    func deleteWeather(for city: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = NSFetchRequest<WeatherEntity>(entityName: "WeatherEntity")
                    request.predicate = NSPredicate(format: "cityName == %@", city)
                    
                    let entities = try self.context.fetch(request)
                    for entity in entities {
                        self.context.delete(entity)
                    }
                    
                    try self.context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: WeatherRepositoryError.storageError)
                }
            }
        }
    }
    
    func getAllSavedCities() async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = NSFetchRequest<NSDictionary>(entityName: "WeatherEntity")
                    request.propertiesToFetch = ["cityName"]
                    request.resultType = .dictionaryResultType
                    
                    let results = try self.context.fetch(request)
                    let cities = results.compactMap { $0["cityName"] as? String }
                    continuation.resume(returning: cities)
                } catch {
                    continuation.resume(throwing: WeatherRepositoryError.storageError)
                }
            }
        }
    }
    
    func clearAll() async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "WeatherEntity")
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                    
                    try self.context.execute(deleteRequest)
                    try self.context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: WeatherRepositoryError.storageError)
                }
            }
        }
    }
}

// MARK: - Core Data Entity Extension

import CoreData

@objc(WeatherEntity)
class WeatherEntity: NSManagedObject {
    @NSManaged var cityName: String
    @NSManaged var jsonData: Data?
    @NSManaged var lastUpdated: Date?
}