//
//  Transaction+CoreDataProperties.swift
//  SpendSmart
//
//  Created by Anirudh Maheshwari on 30/03/24.
//
//

import Foundation
import CoreData


extension Transaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        return NSFetchRequest<Transaction>(entityName: "Transaction")
    }

    @NSManaged public var amount: Double
    @NSManaged public var date: Date?
    @NSManaged public var id: String?
    @NSManaged public var type: String?
    @NSManaged public var category: String?

}

extension Transaction : Identifiable {

}
