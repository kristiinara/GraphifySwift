//
//  Module.swift
//  Basic
//
//  Created by Kristiina Rahkema on 30/09/2019.
//

import Foundation

class Module {
    let name: String
    let appKey: String
    var id: Int?
    
    var classes: [ClassInstance] = []
    var structures: [Struct] = []
    var protocols: [Protocol] = []
    
    weak var belongsToApp: App? //TODO: is this necessary?
    
    var allClasses: [Class] {
        var allClasses: [Class] = []
        allClasses.append(contentsOf: self.classes)
        allClasses.append(contentsOf: self.structures)
        allClasses.append(contentsOf: self.protocols)
        
        return allClasses
    }
    
    init(name: String, appKey: String) {
        self.name = name
        self.appKey = appKey
    }
}

extension Module: Node4jInsertable {
    var nodeName: String {
        return "Module"
    }

    var properties: String {
        return """
        {
        name:'\(self.name)',
        app_key:'\(self.appKey)'
        }
        """
    }
    
    var deleteQuery: String? {
        if let id = self.id {
            return "delete (n:\(self.nodeName) where id(n)=\(id)"
        }
        return nil
    }
    
    var updateQuery: String? {
        if let id = self.id {
            return """
                match (n:\(self.nodeName)
                where id(n)=\(id) set n += \(self.properties)
            """
        }
        return nil
    }

    var createQuery: String? {
        let query = "create (n:\(self.nodeName) \(self.properties)) return id(n)"
        print("query: \(query)")
        return query
    }
    
    func ownsClassQuery(_ someClass: Class) -> String? {
        if let moduleId = self.id, let classId = someClass.id {
            return "match (a:Module), (c:Class) where id(a) = \(moduleId) and id(c) = \(classId) create (a)-[r:MODULE_OWNS_CLASS]->(c) return id(r)"
        }
        return nil
    }
    
    func ownsStructQuery(_ someStruct: Struct) -> String? {
        if let moduleId = self.id, let structId = someStruct.id {
            return "match (a:Module), (c:Struct) where id(a) = \(moduleId) and id(c) = \(structId) create (a)-[r:MODULE_OWNS_CLASS]->(c) return id(r)"
        }
        return nil
    }
    
    func ownsStructQuery(_ someProtocol: Protocol) -> String? {
        if let moduleId = self.id, let protocolId = someProtocol.id {
            return "match (a:Module), (c:Protocol) where id(a) = \(moduleId) and id(c) = \(protocolId) create (a)-[r:MODULE_OWNS_CLASS]->(c) return id(r)"
        }
        return nil
    }
}
