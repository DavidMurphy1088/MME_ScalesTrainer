//
//  ScalesTrainerApp.swift
//  ScalesTrainer
//
//  Created by David Murphy on 11/20/23.
//

import SwiftUI

@main
struct ScalesTrainerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
