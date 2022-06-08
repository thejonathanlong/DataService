//
//  FetchedResultsObservable.swift
//  
//
//  Created on 6/7/22.
//

import Combine
import CoreData
import Foundation
import SwiftUI

//MARK: - ManagedObjectConsumable
public protocol ManagedObjectConsumable {
    associatedtype ManagedObject: NSManagedObject
    init?(managedObject: ManagedObject)
}

//MARK: - FetchedResultsObservable
public class FetchedResultsObservable<ManagedObject, Consumable: ManagedObjectConsumable>: ObservableObject where Consumable.ManagedObject == ManagedObject {
    
    //MARK: - Private Properties
    private let fetchedResultsController: NSFetchedResultsController<ManagedObject>
    
    @Published private var fetchedConsumables = [Consumable]()
    
    private var cancellables = Set<AnyCancellable>()
    
    //MARK: - Public Properties
    public var objectWillChangeSequence: AsyncPublisher<Publishers.Buffer<ObjectWillChangePublisher>> {
        objectWillChange
            .buffer(size: 1, prefetch: .byRequest, whenFull: .dropOldest)
            .values
    }
    
    //MARK: - Init
    init(fetchRequest: NSFetchRequest<ManagedObject>,
         context: NSManagedObjectContext,
         cacheName: String? = nil) {
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: context,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: cacheName)
        NotificationCenter
            .default
            .publisher(for: NSManagedObjectContext.didChangeObjectsNotification)
            .sink { [weak self] _ in
                self?.fetchedConsumables = self?.fetchedResultsController
                    .fetchedObjects?
                    .compactMap {
                        Consumable.init(managedObject: $0)
                    } ?? []
            }
            .store(in: &cancellables)
    }
    
    internal func start() throws {
        try fetchedResultsController.performFetch()
    }
}
