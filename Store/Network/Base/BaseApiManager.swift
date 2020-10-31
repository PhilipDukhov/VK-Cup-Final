//
//  BaseVkApiManager.swift
//  Store
//
//  Created by Philip Dukhov on 10/29/20.
//

import Foundation
import SwiftyVK

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
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
    
    func sendHandleAndParse<R: Codable>(
        _ apiMethod: SwiftyVK.Method,
        container: ResponseContainer,
        completion: @escaping (Result<[R], Error>) -> Void
    ) {
        apiMethod.onSuccess { [weak self] data in
            guard let strongSelf = self else { return }
            let result: [R]
            switch container {
            case .items:
                result = try strongSelf.decoder.decode(
                    ResponseItems<R>.self,
                    from: data
                ).items
                
            case .response:
                result = try strongSelf.decoder.decode(
                    [R].self,
                    from: data
                )
            }
            completion(.success(result))
        }
        .onError {
            completion(
                .failure(
                    .with(vkError: $0)
                )
            )
        }
        .send()
    }
    
    func sendHandleAndParseFirst<R: Codable>(
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
