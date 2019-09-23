//
//  Variable.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 21/03/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//

class Variable : Kind {
    var id: Int?
    var usr: String? = "?"
    var name: String
    var appKey: String = "Default"
    var modifier: String = ""
    var type: String
    var isStatic: Bool = false
    var isFinal: Bool = false
    weak var classInstance: Class?
    
    var methodReferences: [Function] = []
    var variableReferences: [Variable] = []
    
    var uses: [Int]?
    
    init(name: String, type: String) {
        self.name = name
        self.type = type
    }
    
    init(name: String, appKey: String, modifier: String, type: String, isStatic: Bool, isFinal: Bool) {
        self.name = name
        self.appKey = appKey
        self.modifier = modifier
        self.type = type
        self.isStatic = isStatic
        self.isFinal = isFinal
    }
    
    var description: String {
        return "Method: \(name), type: \(type)"
    }
}

extension Variable: Node4jInsertable {
    var nodeName: String {
        return "Variable"
    }
    
    var properties: String {
        return """
        {
        name:'\(self.name)',
        app_key:'\(self.appKey)',
        modifier:'\(self.modifier)',
        type:'\(self.type)',
        is_static:\(self.isStatic),
        is_final:\(self.isFinal)
        }
        """
    }
    
    var createQuery: String? {
        return "create (n:\(self.nodeName) \(self.properties)) return id(n)"
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
}

class GlobalVariable: Variable, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.decl.var.global"
    }
}


class InstanceVariable: Variable, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.decl.var.instance"
    }
}

class StaticVariable: Variable, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.decl.var.static"
    }
}

class ClassVariable: Variable, SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.decl.var.class"
    }
}
