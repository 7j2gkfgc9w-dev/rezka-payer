//
//  ContentViewModel.swift
//  rezka-player
//
//  Created by Vitalii Parovishnyk on 21.10.2022.
//

import SwiftUI

@MainActor
final class ContentViewModel: ObservableObject {
    
    @Published var phase = DataFetchPhase<[CategoryList]>.fetching
    @Published private(set) var isFetching = true
    
    private let api = NavigationRezkaApi()
    
    private let cache: DiskCache<[CategoryList]> = .init(filename: "navigationcache-b5", expirationInterval: 5 * 60)
    
    var categories: [CategoryList] {
        phase.value ?? []
    }
    
    func load() async {
        await AppDiag.markAwait("LOAD_BEGIN")
        if Task.isCancelled { return }
        
        try? await cache.loadFromDisk()
        await AppDiag.markAwait("CACHE_LOADED")
        
        if let categories = await cache.value(forKey: "categories_list"),
           !categories.contains(where: { $0.type == .none }) {
            phase = .success(categories)
        }
        
        phase = .fetching
        
        await AppDiag.markAwait("NAV_CALL_BEGIN")
        await loadNavigation()
    }
    
    private func loadNavigation() async {
        isFetching = true
        do {
            let categories = try await api.fetch()
            await AppDiag.markAwait("NAV_FETCH_OK_\(categories.count)")
            if Task.isCancelled { return }
            await cache.setValue(categories, forKey: "categories_list")
            try? await cache.saveToDisk()
            
            await AppDiag.markAwait("BEFORE_PHASE_SUCCESS")
            phase = .success(categories)
            AppDiag.mark("PHASE_SUCCESS_SET_\(categories.count)")
            isFetching = false
            
        } catch {
            await AppDiag.markAwait("NAV_FAILURE")
            if Task.isCancelled { return }
            phase = .failure(error)
            isFetching = false
        }
    }
}
