//
//  Utils.swift
//  SpendSmart
//
//  Created by Anirudh Maheshwari on 03/04/24.
//

import UIKit

class Utils {
    
    static func addSuccessAlert(_ obj: String, completion: (() -> Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: "Success!", message: "\(obj) Added Successfully!", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        }
        
        alertController.addAction(okAction)
        return alertController
    }
    
    static func updateSuccessAlert(_ obj: String, completion: (() -> Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: "Success!", message: "\(obj) Updated Successfully!", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        }
        alertController.addAction(okAction)
        return alertController
    }
    
    static func fieldsValidationErrorAlert(_ obj: String) -> UIAlertController {
        let alertController = UIAlertController(title: "ERROR!", message: "Please enter a valid \(obj) value.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        return alertController
    }
    
    static func calculateMultipleTransactionsTotal(transactionList: [Transaction]) -> Double {
        var totalAmount: Double = 0.0
        for transaction in transactionList {
            totalAmount += transaction.amount
        }
        return totalAmount
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
