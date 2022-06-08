//
//  DataFetchingTests.swift
//  
//
//  Created by Jonathan Long on 6/7/22.
//

import CoreData
@testable import DataService
import XCTest

struct DataServiceTestUtilities {
    let testModelName = "Model"
    let testModelURL = Bundle.module.url(forResource:"Model", withExtension: "momd")!
    lazy var testModel = NSManagedObjectModel(contentsOf: testModelURL)!
}

extension TestEntity {
    static var entityName: String {
        "TestEntity"
    }
}

class DataFetchingTests: XCTestCase {
    
    var utilities = DataServiceTestUtilities()
    lazy var store = DataStore(containerName: utilities.testModelName,
                               managedObjectModel: utilities.testModel,
                               eventHandler: nil)
    let expectedName = "Name"
    
    override func setUp() {
        super.setUp()
        
        for number in 0...9 {
            store.add(type: TestEntity.self,
                                   entityName: TestEntity.entityName) { testEntity in
                testEntity.name = expectedName + "\(number)"
            }
        }
        
    }
    
    func testSimpleAdd() {
        let expectedName = "New Name"
        let entity = store.add(type: TestEntity.self,
                               entityName: TestEntity.entityName) { testEntity in
            testEntity.name = expectedName
        }
        
        XCTAssertNotNil(entity)
        XCTAssertNotNil(entity?.name)
        XCTAssertEqual(entity?.name, expectedName)
    }
    
    func testFetch() async throws {
        let fetchRequest = NSFetchRequest<TestEntity>(entityName: TestEntity.entityName)
        fetchRequest.predicate = NSPredicate(value: true)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        let result: [TestEntityConsumable] = try await store.fetch(fetchRequest: fetchRequest)
        
        XCTAssertEqual(result.count, 10)
        result.enumerated().forEach {
            XCTAssertEqual($0.element.name, expectedName + "\($0.offset)")
        }
    }
    
    
    
    
}

struct TestEntityConsumable: ManagedObjectConsumable {
    var name: String?
    
    init?(managedObject: TestEntity) {
        name = managedObject.name
    }
    
    typealias ManagedObject = TestEntity
    
    
}
