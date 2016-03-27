//
//  ViewController.swift
//  KirjainPeli
//
//  Created by Timo Olkkonen on 29/02/16.
//  Copyright © 2016 Timo Olkkonen. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVSpeechSynthesizerDelegate {
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    let SPACING: CGFloat = 20
    let FONT_SIZE: CGFloat = 40
    
    let label: UILabel = UILabel.init()
    var characterBuffer = NSMutableAttributedString.init()
    
    var db: COpaquePointer = nil
    var statement: COpaquePointer = nil
    var utteranceIndexes = [AVSpeechUtterance: Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        speechSynthesizer.delegate = self
        initWordDatabase()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.whiteColor()
        label.font = label.font.fontWithSize(FONT_SIZE)
        
        let column = UIStackView(arrangedSubviews: [label] + ["ABCDE", "FGHIJ", "KLMNO", "PQRST", "UVWXY", "ZÅÄÖ"].map(toRow))
        column.axis = .Vertical
        column.distribution = .FillEqually
        column.alignment = .Fill
        column.spacing = SPACING
        column.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(column)
        
        let viewsDictionary = ["stackView":column]
        let stackView_H = NSLayoutConstraint.constraintsWithVisualFormat("H:|-20-[stackView]-20-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let stackView_V = NSLayoutConstraint.constraintsWithVisualFormat("V:|-30-[stackView]-30-|", options: NSLayoutFormatOptions(rawValue:0), metrics: nil, views: viewsDictionary)
        view.addConstraints(stackView_H)
        view.addConstraints(stackView_V)
    }
        
    func toRow(characters: String) -> UIStackView {
        let row = UIStackView(arrangedSubviews: characters.characters.map(toLetterButton))
        row.axis = .Horizontal
        row.distribution = .FillEqually
        row.alignment = .Fill
        row.spacing = SPACING
        row.translatesAutoresizingMaskIntoConstraints = false
        return row
    }
    
    func toLetterButton(letter: Character) -> UIButton {
        let button = UIButton(type: .System)
        button.setTitle(String(letter), forState: .Normal)
        button.addTarget(self, action: "letterPressed:", forControlEvents: .TouchDown)
        button.titleLabel!.font = button.titleLabel!.font.fontWithSize(FONT_SIZE)
        button.titleLabel!.textColor = UIColor.blueColor()
        button.backgroundColor = UIColor.lightGrayColor()
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.blackColor().CGColor
        button.layer.cornerRadius = 15
        return button
    }
    
    func letterPressed(letterButton: UIButton) {
        let letter = letterButton.currentTitle!
        characterBuffer.appendAttributedString(NSAttributedString.init(string: letter))
        let characterCount = characterBuffer.string.characters.count
        label.attributedText = characterBuffer
        say(letter, startIndex: characterCount-1)
        getWords().forEach({
            say($0, startIndex: characterCount - $0.characters.count)
        })
    }
    
    func getWords() -> [String] {
        var index = characterBuffer.string.startIndex
        var words: [String] = []
        let SQLITE_TRANSIENT = unsafeBitCast(-1, sqlite3_destructor_type.self)
        while (index != characterBuffer.string.endIndex) {
            let key = characterBuffer.string.substringFromIndex(index).lowercaseString
            if sqlite3_bind_text(statement, 1, key, -1, SQLITE_TRANSIENT) != SQLITE_OK {
                let errmsg = String.fromCString(sqlite3_errmsg(db))
                print("failure binding foo: \(errmsg)")
            }
            
            if sqlite3_step(statement) == SQLITE_ROW {
                let word = sqlite3_column_text(statement, 0)
                if word != nil {
                    words.append(String.fromCString(UnsafePointer<Int8>(word))!)
                }
            }
            sqlite3_reset(statement)
            sqlite3_clear_bindings(statement)
            index = index.successor()
        }
        return words
    }
    
    func say(text: String, startIndex: Int) {
        let speechUtterance = AVSpeechUtterance(string: text.lowercaseString)
        speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechUtterance.pitchMultiplier = 1.0
        speechUtterance.volume = 1.0
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "fi-FI")
        speechUtterance.preUtteranceDelay = 0.0
        speechUtterance.postUtteranceDelay = 0.0
        utteranceIndexes[speechUtterance] = startIndex
        speechSynthesizer.speakUtterance(speechUtterance)
    }
    
    func initWordDatabase() {
        let path = NSBundle.mainBundle().pathForResource("finnish_words.db", ofType: nil)
        if sqlite3_open(path!, &db) != SQLITE_OK {
            print("error opening database")
        }
        if sqlite3_prepare_v2(db, "select word from words where word = (?)", -1, &statement, nil) != SQLITE_OK {
            let errmsg = String.fromCString(sqlite3_errmsg(db))
            print("error preparing query: \(errmsg)")
        }
    }

    func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didStartSpeechUtterance utterance: AVSpeechUtterance) {
        let startIndex = utteranceIndexes[utterance]
        characterBuffer.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: NSRange(location: startIndex!, length: utterance.speechString.characters.count))
        label.attributedText = characterBuffer
    }
    
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didFinishSpeechUtterance utterance: AVSpeechUtterance) {
        let startIndex = utteranceIndexes[utterance]
        characterBuffer.removeAttribute(NSForegroundColorAttributeName, range: NSRange(location: startIndex!, length: utterance.speechString.characters.count))
        label.attributedText = characterBuffer
        utteranceIndexes.removeValueForKey(utterance)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

