//
//  MasterCameraApp.swift
//  MasterCamera
//
//  Created by SHU-FANG WU on 2025/12/28.
//

import SwiftUI
import CoreData

@main
struct MasterCameraApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
