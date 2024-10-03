// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import CoreData

final class SeedProgressManager {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    // Fetch SeedProgress from Core Data
    func fetchSeedProgress() -> SeedProgressEntity? {
        let request: NSFetchRequest<SeedProgressEntity> = SeedProgressEntity.fetchRequest()
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Failed to fetch seed progress: \(error)")
            return nil
        }
    }
    
    // Save or Update SeedProgress to Core Data
    func saveSeedProgress(level: Int16, seedsCollected: Int16, lastAppOpenDate: Date?) {
        if let seedProgress = fetchSeedProgress() {
            // Update existing SeedProgress entity
            seedProgress.level = level
            seedProgress.seedsCollected = seedsCollected
            seedProgress.lastAppOpenDate = lastAppOpenDate
        } else {
            // Create new SeedProgress entity
            let newProgress = ProgressEntity(context: context)
            newProgress.level = level
            newProgress.seedsCollected = seedsCollected
            newProgress.lastAppOpenDate = lastAppOpenDate
        }
        
        // Save the context
        do {
            try context.save()
        } catch {
            print("Failed to save seed progress: \(error)")
        }
    }
    
    // Collect one seed per day
    func collectSeed() {
        guard let seedProgress = fetchSeedProgress() else { return }
        
        let calendar = Calendar.current
        if let lastOpenDate = seedProgress.lastAppOpenDate, calendar.isDateInToday(lastOpenDate) {
            print("Seed already collected today")
            return
        }
        
        // Collect a seed
        seedProgress.seedsCollected += 1
        seedProgress.lastAppOpenDate = Date()
        
        // Handle level transitions
        if seedProgress.level == 1 && seedProgress.seedsCollected >= 5 {
            seedProgress.level = 2
            seedProgress.seedsCollected = 0
        } else if seedProgress.level == 2 && seedProgress.seedsCollected >= 7 {
            seedProgress.seedsCollected = 7 // Cap the progress after level 2
        }
        
        saveSeedProgress(level: seedProgress.level, seedsCollected: seedProgress.seedsCollected, lastAppOpenDate: seedProgress.lastAppOpenDate)
    }
}
