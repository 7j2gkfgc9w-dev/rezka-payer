//
//  rezka_playerApp.swift
//  Shared
//
//  Created by Vitalii Parovishnyk on 16.08.2022.
//

import SwiftUI
import Foundation

enum AppDiag {
    static func mark(_ event: String) {
        guard let encoded = event.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "http://192.168.1.2:8099/__appdiag?build=5&event=\(encoded)") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.5
        URLSession.shared.dataTask(with: request).resume()
    }

    static func markAwait(_ event: String) async {
        guard let encoded = event.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "http://192.168.1.2:8099/__appdiag?build=5&event=\(encoded)") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.5
        _ = try? await URLSession.shared.data(for: request)
    }
}

@main
struct rezka_playerApp: App {
    init() {
        AppDiag.mark("APP_INIT")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
