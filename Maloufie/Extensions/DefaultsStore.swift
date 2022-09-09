//
//  DefaultsStore.swift
//  Doll
//
//  Created by Dylan Elliott on 5/8/2022.
//

import Foundation

var SharedDefaults: DefaultsStore { UserDefaults.standard }

protocol DefaultsStore {
    func set(data: Data?, for key: DefaultsKey)
    func data(for key: DefaultsKey) -> Data?
    @discardableResult func synchronize() -> Bool
}

extension UserDefaults: DefaultsStore {
    func set(data: Data?, for key: DefaultsKey) {
        set(data, forKey: key.rawValue)
    }
    
    func data(for key: DefaultsKey) -> Data? {
        data(forKey: key.rawValue)
    }
}

extension NSUbiquitousKeyValueStore: DefaultsStore {
    func data(for key: DefaultsKey) -> Data? {
        data(forKey: key.rawValue)
    }
    
    func set(data: Data?, for key: DefaultsKey) {
        set(data, forKey: key.rawValue)
    }
}

extension DefaultsStore {
    
    func overwriteAllValues(from: DefaultsStore) {
        DefaultsKey.allCases.forEach {
            overwriteValues(for: $0, from: from)
        }
    }
    
    func overwriteValues(for key: DefaultsKey, from: DefaultsStore) {
        if let data = from.data(for: key) {
            self.set(data: data, for: key)
        }
    }
}
