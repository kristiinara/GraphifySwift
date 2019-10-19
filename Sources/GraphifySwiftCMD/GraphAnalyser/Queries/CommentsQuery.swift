//
//  Comments.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class CommentsQuery: Query {
    var name = "Comments"
    var highNumberOfComments = 10

    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "match (c:Class) where c.number_of_comments > \(self.highNumberOfComments) return c.app_key as app_key, c.name as class_name, c.number_of_comments as number_of_comments"
    }
    
    var notes: String {
        return "Comments code smell looks for if a class has a high number of comments. What high number of comments means needs to be determined statistically."
    }
}
