//
//  BaseVkApiManager.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import Foundation
import SwiftyVK
import CoreData

class BaseApiManager {    
    enum Error: Swift.Error {
        case emptyResponse
        case urlRequestError(Swift.Error)
        
        case vkError(VKError)
        case other(Swift.Error)
        
        static func with(vkError: VKError) -> Self {
            switch vkError {
            case .urlRequestError(let error):
                return .urlRequestError(error)
                
            default:
                return .vkError(vkError)
            }
        }
    }
    enum ResponseContainer {
        case items
        case response
    }
    
    private let decoder: JSONDecoder
    private let managedObjectContext: NSManagedObjectContext?
    
    init(context: NSManagedObjectContext? = nil) {
        managedObjectContext = context
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.userInfo[CodingUserInfoKey.managedObjectContext] = context        
    }
    
    func sendHandleAndParseModelFirst<R: ModelType>(
        _ apiMethod: SwiftyVK.Method,
        container: ResponseContainer,
        completion: @escaping (Result<R, Error>) -> Void
    ) {
        sendHandleAndParseFirst(
            apiMethod,
            container: container
        ) { [weak self] (result: Result<R, Error>) in
            completion(result.map {
                self?.clearDuplicates([$0])
                return $0
            })
        }
    }
    
    func sendHandleAndParseModel<R: ModelType>(
        _ apiMethod: SwiftyVK.Method,
        container: ResponseContainer,
        completion: @escaping (Result<[R], Error>) -> Void
    ) {
        sendHandleAndParse(
            apiMethod,
            container: container
        ) { [weak self] (result: Result<[R], Error>) in
            completion(result.map {
                self?.clearDuplicates($0)
                return $0
            })
        }
    }
    
    func sendHandleAndParse<R: Decodable>(
        _ apiMethod: SwiftyVK.Method,
        container: ResponseContainer,
        completion: @escaping (Result<[R], Error>) -> Void
    ) {
        apiMethod.onSuccess { [weak self] data in
            guard let self = self else { return }
            let result: [R]
            switch container {
            case .items:
                result = try self.decoder.decode(
                    ResponseItems<R>.self,
                    from: data
                ).items
                
            case .response:
                result = try self.decoder.decode(
                    [R].self,
                    from: data
                )
            }
            completion(.success(result))
        }
        .onError {
            print($0)
            completion(
                .failure(
                    .with(vkError: $0)
                )
            )
        }
        .send()
    }
    
    func sendHandleAndParseFirst<R: Decodable>(
        _ apiMethod: SwiftyVK.Method,
        container: ResponseContainer,
        completion: @escaping (Result<R, Error>) -> Void
    ) {
        sendHandleAndParse(
            apiMethod,
            container: container
        ) { [weak self] (result: Result<[R], Error>) in
            self.map { completion($0.flatMapFirst(from: result)) }
        }
    }
    
    private func flatMapFirst<R>(
        from result: Result<[R], Error>
    ) -> Result<R, Error> {
        result.flatMap {
            guard let value = $0.first else {
                return .failure(.emptyResponse)
            }
            return .success(value)
        }
    }
    
    private func clearDuplicates<R: ModelType>(
        _ newObjects: [R]
    ) {
        databaseQueue.async { [self] in
            guard !newObjects.isEmpty else { return }
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
                entityName: "\(R.self)"
            )
            fetchRequest.predicate = NSPredicate(
                format: "(id IN %@) AND (NOT (self in %@))",
                newObjects.map { $0.id },
                newObjects.map { $0.objectID }
            )
            do {
                try managedObjectContext?.execute(
                    NSBatchDeleteRequest(
                        fetchRequest: fetchRequest
                    )
                )
                try managedObjectContext?.save()
            } catch {
                print(error)
            }
        }
    }
}

extension Dictionary where Key == Parameter {
    var stringify: Parameters {
        reduce(into: [:]) { $0[$1.0] = "\($1.1)" }
    }
}

extension Dictionary where Key == String {
    var stringify: RawParameters {
        reduce(into: [:]) { $0[$1.key] = "\($1.1)" }
    }
}
