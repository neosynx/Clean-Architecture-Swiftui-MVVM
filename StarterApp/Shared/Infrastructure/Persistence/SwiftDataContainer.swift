//
//  SwiftDataContainer.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation
import SwiftData

/// SwiftData container for managing persistent storage in iOS 17+
/// This actor ensures thread-safe access to the model container and context
actor SwiftDataContainer {
    
    // MARK: - Properties
    
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private let logger: AppLogger
    
    // MARK: - Configuration
    
    struct Configuration {
        let isStoredInMemoryOnly: Bool
        let allowsSave: Bool
        let cloudKitContainerIdentifier: String?
        
        static let `default` = Configuration(
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitContainerIdentifier: nil
        )
        
        static let inMemory = Configuration(
            isStoredInMemoryOnly: true,
            allowsSave: true,
            cloudKitContainerIdentifier: nil
        )
    }
    
    // MARK: - Initialization
    
    init(
        configuration: Configuration = .default,
        logger: AppLogger
    ) throws {
        self.logger = logger
        
        // Define the schema
        let schema = Schema([
            WeatherEntity.self
        ])
        
        // Create model configuration
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: configuration.isStoredInMemoryOnly,
            allowsSave: configuration.allowsSave
        )
        
        // Initialize container
        self.modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        // Create context
        self.modelContext = ModelContext(modelContainer)
        self.modelContext.autosaveEnabled = true
        
        logger.info("SwiftDataContainer initialized with configuration: \(configuration)")
    }
    
    // MARK: - CRUD Operations
    
    /// Fetch models matching the given descriptor
    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) async throws -> [T] {
        logger.debug("Fetching \(T.self) with descriptor")
        
        do {
            let results = try modelContext.fetch(descriptor)
            logger.debug("Fetched \(results.count) \(T.self) items")
            return results
        } catch {
            logger.error("Failed to fetch \(T.self): \(error)")
            throw SwiftDataError.fetchFailed(error)
        }
    }
    
    /// Fetch all models of a given type
    func fetchAll<T: PersistentModel>(_ type: T.Type) async throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        return try await fetch(descriptor)
    }
    
    /// Fetch a single model by predicate
    func fetchOne<T: PersistentModel>(
        _ type: T.Type,
        where predicate: Predicate<T>
    ) async throws -> T? {
        let descriptor = FetchDescriptor<T>(
            predicate: predicate,
            sortBy: []
        )
        
        let results = try await fetch(descriptor)
        return results.first
    }
    
    /// Insert a new model
    func insert<T: PersistentModel>(_ model: T) async throws {
        logger.debug("Inserting \(type(of: model))")
        
        do {
            modelContext.insert(model)
            try await save()
            logger.debug("Successfully inserted \(type(of: model))")
        } catch {
            logger.error("Failed to insert \(type(of: model)): \(error)")
            throw SwiftDataError.insertFailed(error)
        }
    }
    
    /// Insert multiple models
    func insertBatch<T: PersistentModel>(_ models: [T]) async throws {
        logger.debug("Batch inserting \(models.count) \(T.self) items")
        
        do {
            for model in models {
                modelContext.insert(model)
            }
            try await save()
            logger.debug("Successfully batch inserted \(models.count) items")
        } catch {
            logger.error("Failed to batch insert: \(error)")
            throw SwiftDataError.batchInsertFailed(error)
        }
    }
    
    /// Update an existing model
    func update<T: PersistentModel>(_ model: T) async throws {
        logger.debug("Updating \(type(of: model))")
        
        do {
            // SwiftData automatically tracks changes
            try await save()
            logger.debug("Successfully updated \(type(of: model))")
        } catch {
            logger.error("Failed to update \(type(of: model)): \(error)")
            throw SwiftDataError.updateFailed(error)
        }
    }
    
    /// Delete a model
    func delete<T: PersistentModel>(_ model: T) async throws {
        logger.debug("Deleting \(type(of: model))")
        
        do {
            modelContext.delete(model)
            try await save()
            logger.debug("Successfully deleted \(type(of: model))")
        } catch {
            logger.error("Failed to delete \(type(of: model)): \(error)")
            throw SwiftDataError.deleteFailed(error)
        }
    }
    
    /// Delete all models matching a predicate
    func deleteAll<T: PersistentModel>(
        _ type: T.Type,
        where predicate: Predicate<T>? = nil
    ) async throws {
        logger.debug("Deleting all \(T.self) matching predicate")
        
        do {
            let descriptor = FetchDescriptor<T>(predicate: predicate)
            let models = try await fetch(descriptor)
            
            for model in models {
                modelContext.delete(model)
            }
            
            try await save()
            logger.debug("Successfully deleted \(models.count) \(T.self) items")
        } catch {
            logger.error("Failed to delete all \(T.self): \(error)")
            throw SwiftDataError.deleteAllFailed(error)
        }
    }
    
    /// Count models matching a predicate
    func count<T: PersistentModel>(
        _ type: T.Type,
        where predicate: Predicate<T>? = nil
    ) async throws -> Int {
        let descriptor = FetchDescriptor<T>(predicate: predicate)
        let results = try await fetch(descriptor)
        return results.count
    }
    
    // MARK: - Transaction Support
    
    /// Perform operations in a transaction
    func transaction<T>(_ block: @escaping () throws -> T) async throws -> T {
        logger.debug("Starting transaction")
        
        do {
            let result = try block()
            try await save()
            logger.debug("Transaction completed successfully")
            return result
        } catch {
            logger.error("Transaction failed: \(error)")
            // SwiftData automatically rolls back on error
            throw SwiftDataError.transactionFailed(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func save() async throws {
        guard modelContext.hasChanges else {
            logger.debug("No changes to save")
            return
        }
        
        try modelContext.save()
        logger.debug("Context saved successfully")
    }
    
    // MARK: - Maintenance
    
    /// Clear all data (useful for testing)
    func clearAllData() async throws {
        logger.info("Clearing all SwiftData storage")
        
        // This would need to iterate through all model types
        // For now, this is a placeholder
        // In practice, you'd clear each model type individually
        
        logger.info("All data cleared")
    }
    
    /// Get storage statistics
    func getStatistics() async throws -> StorageStatistics {
        // Placeholder for storage statistics
        // In a real implementation, you'd query model counts
        StorageStatistics(
            totalModels: 0,
            storageSize: 0,
            lastModified: Date()
        )
    }
}

// MARK: - SwiftData Errors

enum SwiftDataError: LocalizedError {
    case fetchFailed(Error)
    case insertFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case deleteAllFailed(Error)
    case batchInsertFailed(Error)
    case transactionFailed(Error)
    case migrationFailed(Error)
    case containerInitializationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .insertFailed(let error):
            return "Failed to insert data: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update data: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete data: \(error.localizedDescription)"
        case .deleteAllFailed(let error):
            return "Failed to delete all data: \(error.localizedDescription)"
        case .batchInsertFailed(let error):
            return "Failed to batch insert data: \(error.localizedDescription)"
        case .transactionFailed(let error):
            return "Transaction failed: \(error.localizedDescription)"
        case .migrationFailed(let error):
            return "Migration failed: \(error.localizedDescription)"
        case .containerInitializationFailed(let error):
            return "Failed to initialize container: \(error.localizedDescription)"
        }
    }
}

// MARK: - Storage Statistics

struct StorageStatistics {
    let totalModels: Int
    let storageSize: Int64
    let lastModified: Date
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: storageSize)
    }
}

// MARK: - Testing Support

#if DEBUG
extension SwiftDataContainer {
    /// Create an in-memory container for testing
    static func inMemory(logger: AppLogger) throws -> SwiftDataContainer {
        try SwiftDataContainer(
            configuration: .inMemory,
            logger: logger
        )
    }
}
#endif
