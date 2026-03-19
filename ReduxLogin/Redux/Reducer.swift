//
//  Reducer.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 14.07.2024.
//

import Combine
import Foundation

struct Reducer<State, Action> {
    typealias Change = (inout State) -> Void

    let reduce: (State, Action) -> AnyPublisher<Change, Never>
}

extension Reducer {
    static func sync(_ fun: @escaping (inout State) -> Void) -> AnyPublisher<Change, Never> {
        Just(fun).eraseToAnyPublisher()
    }
}
