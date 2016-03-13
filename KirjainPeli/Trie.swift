//
//  Trie.swift
//  KirjainPeli
//
//  Created by Timo Olkkonen on 13/03/16.
//  Copyright © 2016 Timo Olkkonen. All rights reserved.
//

import Foundation

class Trie {
    
    class Node {
        let key: String
        var children: Array<Node> = Array<Node>()
        var isFinal: Bool = false
        let level: Int
        
        init(key: String, level: Int) {
            self.key = key
            self.level = level
        }
    }
    
    let root = Node.init(key: "", level: 0)
    
    func add(word: String) {
        let key = word.characters.reverse()
        var current = root
        while (key.count != current.level) {
            let prefix = String(key.prefix(current.level + 1))
            let next = current.children.filter({$0.key == prefix}).first
            if (next == nil) {
                let new  = Node.init(key: prefix, level: current.level + 1)
                current.children.append(new)
                current = new
            } else {
                current = next!
            }
        }
        current.isFinal = true
    }
    
    func find(prefix: String) -> Array<String>! {
        var current: Node? = root
        var words = Array<String>()
        var index = prefix.startIndex
        while (current != nil && index != prefix.endIndex) {
            index = index.advancedBy(1)
            let key = prefix.substringToIndex(index)
            let next = current!.children.filter({$0.key == key}).first
            if (next != nil && next!.isFinal) {
                words.append(String(next!.key.characters.reverse()))
            }
            current = next
        }
        return words
    }
}