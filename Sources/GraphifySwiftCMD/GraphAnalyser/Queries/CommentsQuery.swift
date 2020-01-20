//
//  Comments.swift
//  Basic
//
//  Created by Kristiina Rahkema on 06/06/2019.
//

import Foundation

class CommentsQuery: Query {
    var name = "Comments"
    var veryHighNumberOfComments = Metrics.veryHighNumberOfComments

    var result: String?
    var json: [String : Any]?
    
    var string: String {
        return "match (c:Class) where c.number_of_comments > \(self.veryHighNumberOfComments) return c.app_key as app_key, c.name as class_name, c.number_of_comments as number_of_comments, c.data_string as main_text"
    }
    
    var appString: String {
        return "match (c:Class) where c.number_of_comments > \(self.veryHighNumberOfComments) return distinct(c.app_key) as app_key, count(distinct c) as number_of_smells"
    }
    
    var notes: String {
        return "Comments code smell looks for if a class has a high number of comments. What high number of comments means needs to be determined statistically."
    }
}
