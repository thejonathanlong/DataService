//
//  DataStore.swift
//  
//
//  Created on 6/7/22.
//

import CoreData
import Foundation

public class DataStore {
    
    //MARK: - Event
    public enum Event {
        case failure(Error)
    }
    
    //MARK: - Public Properties
    
    public let container: NSPersistentCloudKitContainer
    
    public let eventHandler: ((Event) -> Void)?
    
    //MARK: - Init
    init(containerName: String,
         managedObjectModel: NSManagedObjectModel,
         storeType: String = NSSQLiteStoreType,
         eventHandler: ((Event) -> Void)? = nil) {
        self.eventHandler = eventHandler
        
        container = NSPersistentCloudKitContainer(name: containerName, managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.type = storeType
        container.persistentStoreDescriptions = [description]
        self.container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                eventHandler?(.failure(error))
            }
        }
    }
}

//MARK: - Public
public extension DataStore {
    @discardableResult func add<ManagedObject>(type: ManagedObject.Type,
                                               entityName: String,
                                               update: (ManagedObject) -> Void) -> ManagedObject? where ManagedObject: NSManagedObject {
        
        guard let entityDescription = NSEntityDescription.entity(forEntityName: entityName,
                                                                 in: container.viewContext)
        else {
            return nil }
        
        let entity = ManagedObject(entity: entityDescription,
                  insertInto: container.viewContext)
        update(entity)
        return entity
    }
    
    func fetch<ManagedObject, Consumable: ManagedObjectConsumable>(fetchRequest: NSFetchRequest<ManagedObject>) async throws -> [Consumable] where ManagedObject == Consumable.ManagedObject {
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        try fetchedResultsController.performFetch()
        return fetchedResultsController.fetchedObjects!.compactMap { Consumable.init(managedObject: $0) }
    }
}
