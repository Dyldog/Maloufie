//
//  UserDefaultable.swift
//  Doll
//
//  Created by Dylan Elliott on 5/8/2022.
//

import Foundation

@propertyWrapper
struct UserDefaultable<T: Codable> {
    
    let key: DefaultsKey
    let initial: T
    
    var wrappedValue: T {
        get {
            guard let data = SharedDefaults.data(for: key) else { return initial }
            return (try? JSONDecoder().decode(T.self, from: data)) ?? initial
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            SharedDefaults.set(data: data, for: key)
        }
    }
    
    init(wrappedValue: T, key: DefaultsKey) {
        self.key = key
        self.initial = wrappedValue
    }
}
