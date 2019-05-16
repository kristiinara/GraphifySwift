//
//  Node4jInsertable.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 18/04/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//

//import Foundation

protocol Node4jInsertable {
    var nodeName: String {get}
    var createQuery: String? {get}
    var deleteQuery: String? {get}
    var updateQuery: String? {get}
}
