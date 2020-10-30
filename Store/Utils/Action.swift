//
//  Action.swift
//  Store
//
//  Created by Philip Dukhov on 10/28/20.
//

import Foundation

public struct ActionInfo: Hashable {
    private let line: Int
    private let file: String
    private let date: TimeInterval
    private let hashString: String?
    
    public init(line: Int,
                file: String,
                date: TimeInterval = Date().timeIntervalSince1970,
                hashString: String? = nil)
    {
        self.line = line
        self.file = file
        self.date = date
        self.hashString = hashString
    }
    
    public func hash(into hasher: inout Hasher) {
        if let hashString = hashString {
            hasher.combine(hashString)
        } else {
            hasher.combine(date)
        }
    }
    
    public static func == (lhs: ActionInfo, rhs: ActionInfo) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

public struct ActionWith<T>: Hashable {
    public let execute: (T) -> Void
    
    private let actionInfo: ActionInfo
    
    public init(line: Int = #line, file: String = #file, hashString: String? = nil, execute: @escaping (T) -> Void) {
        self.actionInfo = .init(line: line,
                                file: file,
                                hashString: hashString)
        self.execute = execute
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(actionInfo)
    }
    
    public static func == (lhs: ActionWith<T>, rhs: ActionWith<T>) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

public struct Action: Hashable {
    public let execute: () -> Void
    
    private let actionInfo: ActionInfo
    
    public init(line: Int = #line, file: String = #file, hashString: String? = nil, execute: @escaping () -> Void) {
        self.actionInfo = .init(line: line,
                                file: file,
                                hashString: hashString)
        self.execute = execute
    }
    
    public static let none = Action{}
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(actionInfo)
    }
    
    public static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
