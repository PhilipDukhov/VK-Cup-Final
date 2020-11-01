//
//  Base.swift
//  Store
//
//  Created by Philip Dukhov on 11/1/20.
//

import UIKit
import CoreData

typealias ModelType = Decodable&Identifiable&NSManagedObject

let databaseQueue = DispatchQueue(label: "databaseQueue")

extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}

enum DecoderConfigurationError: Error {
    case missingManagedObjectContext
}

extension UIViewController {
    var managedObjectContext: NSManagedObjectContext! {
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    }
}

extension Decoder {
    func managedObjectContext() throws -> NSManagedObjectContext {
        guard let context = userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
            throw DecoderConfigurationError.missingManagedObjectContext
        }
        return context
    }
}

extension NSManagedObjectContext {
    func get<R: NSManagedObject>(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor] = [],
        fetchLimit: Int = 0
    ) -> [R] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
            entityName: "\(R.self)"
        )
        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = fetchLimit
        fetchRequest.sortDescriptors = sortDescriptors
        return (try? execute(fetchRequest)
                    as? NSAsynchronousFetchResult<R>)?
            .finalResult ?? []
    }
}
    
