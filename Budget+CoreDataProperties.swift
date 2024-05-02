//
//  Budget+CoreDataProperties.swift
//  SpendSmart
//
//  Created by Anirudh Maheshwari on 11/04/24.
//
//

import Foundation
import CoreData


extension Budget {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Budget> {
        return NSFetchRequest<Budget>(entityName: "Budget")
    }

    @NSManaged public var amount: Double
    @NSManaged public var year: Int16
    @NSManaged public var month: Int16
    @NSManaged public var id: String?

}

extension Budget : Identifiable {

}
