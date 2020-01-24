//
//  Struct.swift
//  GraphifySwift
//
//  Created by Kristiina Rahkema on 21/03/2019.
//  Copyright © 2019 Kristiina Rahkema. All rights reserved.
//

class Struct: Class {
    
}

extension Struct: SourceKittenMappable {
    static var kittenKey: String {
        return "source.lang.swift.decl.struct"
    }
}
