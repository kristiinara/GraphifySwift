//
//  MessageChains.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class MessageChainsQuery: Query {
    var name = "MessageChain"
    let veryHighNumberOfChainedMessages = 3 //TODO: how to figure out a reasonable number? Again Boxblot technique? Look at article about differences in results on Message Chain code smell ("The Inconsistent Measurement of Message Chains")
    
    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "MATCH (c:Class)-[CLASS_OWNS_METHOD]-(m:Method) where m.max_number_of_chaned_message_calls > \(self.veryHighNumberOfChainedMessages) return m.name as name, c.name as class_name, m.app_key as app_key, m.max_number_of_chaned_message_calls as max_number_of_chaned_message_calls"
    }
}
