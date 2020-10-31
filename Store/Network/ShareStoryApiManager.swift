//
//  ShareStoryApiManager.swift
//  Store
//
//  Created by Philip Dukhov on 10/31/20.
//

import Foundation
import SwiftyVK
import Alamofire

class ShareStoryApiManager {
    private struct UploadInfo: Codable {
        let uploadUrl: URL
        
        enum CodingKeys: String, CodingKey {
            case uploadUrl = "upload_url"
        }
    }
    private struct UploadResult: Codable {
        let uploadResult: String
        
        enum CodingKeys: String, CodingKey {
            case uploadResult = "upload_result"
        }
    }
    
    private let baseApiManager = BaseApiManager()
    
    func uploadVideo(
        videoURL: URL,
        product: Product,
        progressHandler: @escaping (Float) -> Void,
        completion: @escaping (Result<Void, BaseApiManager.Error>) -> Void
    ) {
        VK.API.Stories.getVideoUploadServer(
            [.addToNews: 1,
             .linkUrl: product.link.absoluteString,
             .linkText: product.title,
            ].stringify
        ).onSuccess { [weak self] data in
            progressHandler(0.1)
            self?.uploadData(
                fileURL: videoURL,
                uploadInfo: try JSONDecoder().decode(
                    UploadInfo.self,
                    from: data
                ),
                progressHandler: {
                    progressHandler(0.1 + 0.85 * $0)
                },
                completion: completion
            )
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
    
    func uploadPhoto(
        photoURL: URL,
        linkURL: URL,
        progressHandler: @escaping (Float) -> Void,
        completion: @escaping (Result<Void, BaseApiManager.Error>) -> Void
    ) {
        VK.API.Stories.getPhotoUploadServer(
            [.addToNews: 1,
             .linkUrl: linkURL.absoluteString,
            ].stringify
        ).onSuccess { [weak self] data in
            progressHandler(0.1)
            self?.uploadData(
                fileURL: photoURL,
                uploadInfo: try JSONDecoder().decode(
                    UploadInfo.self,
                    from: data
                ),
                progressHandler: {
                    progressHandler(0.1 + 0.85 * $0)
                },
                completion: completion
            )
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
    
    private func uploadData(
        fileURL: URL,
        uploadInfo: UploadInfo,
        progressHandler: @escaping (Float) -> Void,
        completion: @escaping (Result<Void, BaseApiManager.Error>) -> Void
    ) {
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(
                fileURL,
                withName: "file"
            )
        },
        to: uploadInfo.uploadUrl
        ).uploadProgress { progress in
            progressHandler(
                Float(progress.completedUnitCount)
                    / Float(progress.totalUnitCount)
            )
        }.responseJSON { response in
            do {
                let object = try response.result.get()
                guard
                    let dict = object as? [String: Any],
                    let response = dict["response"] as? [String: Any],
                    response["story"] != nil
                else {
                    throw BaseApiManager.Error.other(NSError(description: "\(object)"))
                }
                completion(.success(()))
            } catch {
                completion(.failure(.other(error)))
            }
        }
    }
}
