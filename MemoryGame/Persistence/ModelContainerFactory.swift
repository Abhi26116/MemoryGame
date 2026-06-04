//
//  ModelContainerFactory.swift
//  Memory Match Kids
//

import Foundation
import SwiftData

enum ModelContainerFactory {
    private static let storeFileName = "MemoryGameData.store"

    static func make() -> ModelContainer {
        let schema = Schema([
            LevelProgressEntity.self,
            AppSettingsEntity.self
        ])

        do {
            return try createContainer(schema: schema)
        } catch {
            NSLog("MemoryGame: ModelContainer failed (\(error)). Resetting store and retrying.")
            deleteStoreFiles()
            do {
                return try createContainer(schema: schema)
            } catch {
                NSLog("MemoryGame: Retry failed (\(error)). Using in-memory store.")
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [memoryConfig])
                } catch {
                    fatalError("Could not create ModelContainer: \(error)")
                }
            }
        }
    }

    private static func createContainer(schema: Schema) throws -> ModelContainer {
        let storeURL = applicationSupportDirectory().appendingPathComponent(storeFileName)
        let config = ModelConfiguration(schema: schema, url: storeURL, allowsSave: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Removes the on-disk store (and legacy default store) after a schema mismatch.
    private static func deleteStoreFiles() {
        let directory = applicationSupportDirectory()
        let names = [
            storeFileName,
            storeFileName + "-shm",
            storeFileName + "-wal",
            "default.store",
            "default.store-shm",
            "default.store-wal"
        ]
        let fileManager = FileManager.default
        for name in names {
            let url = directory.appendingPathComponent(name)
            if fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    private static func applicationSupportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }
}
