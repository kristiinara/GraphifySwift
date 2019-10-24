//
//  Argument.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 11/04/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//
class Argument {
    var name: String // for Android it is type of argument
    var type: String
    var position: Int
    var appKey: String
    var id: Int?
    var typeClass: Class?
    
    init(name: String, type: String, position: Int, appKey: String) {
        self.name = name
        self.type = type
        self.position = position
        self.appKey = appKey
    }
    
    var cleanedType: String {
        var typeString = self.type
        typeString = typeString.replacingOccurrences(of: "?", with: "")
        typeString = typeString.replacingOccurrences(of: "!", with: "")
        return typeString
    }
}

extension Argument : Node4jInsertable {
    var nodeName: String {
        return "Argument"
    }
    
    var createQuery: String? {
        return "create (n:\(self.nodeName) {name:'\(self.name)', position:\(self.position), app_key:'\(self.appKey)', type:'\(self.type)'}) return id(n)"
    }
    
    var deleteQuery: String? {
        if let id = self.id {
            return "delete (n:\(self.nodeName) where id(n)=\(id)"
        }
        return nil
    }
    
    var updateQuery: String? {
        if let id = self.id {
            return "match (n:\(self.nodeName) where id(n)=\(id) set n.name = '\(self.name)', position:\(self.position), app_key: '\(self.appKey)'"
        }
        return nil
    }
    
    var isTypeQuery: String? {
        if let typeClass = self.typeClass {
            if let selfid = self.id, let  classId = typeClass.id {
                return "match (a:Argument), (c:Class) where id(a) = \(selfid) and id(c) = \(classId) create (a)-[r:IS_OF_TYPE]->(c) return id(r)"
            }
        }
        return nil
    }
}

extension Argument: SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.decl.var.parameter"
    }
}
