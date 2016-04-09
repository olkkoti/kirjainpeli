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
    let MAX_CHARS = 30
    
    let label: UILabel = UILabel.init()
    let scoreLabel: UILabel = UILabel.init()
    let incrementLabel: UILabel = UILabel.init()
    var score = 0
    var characterBuffer = NSMutableAttributedString.init()
    
    var db: COpaquePointer = nil
    var statement: COpaquePointer = nil
    var pendingUtterances = [AVSpeechUtterance: Int]()
    var startedUtterances = [AVSpeechUtterance: Int]()
    var utteranceScores = [AVSpeechUtterance: (Int, Int)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        speechSynthesizer.delegate = self
        initWordDatabase()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.whiteColor()
        label.font = label.font.fontWithSize(FONT_SIZE)
        label.numberOfLines = 0
        
        scoreLabel.textColor = UIColor.yellowColor()
        scoreLabel.font = scoreLabel.font.fontWithSize(FONT_SIZE)
        scoreLabel.text = String.init(score)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        
        incrementLabel.textColor = UIColor.redColor()
        incrementLabel.font = incrementLabel.font.fontWithSize(FONT_SIZE)
        incrementLabel.text = " "
        incrementLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let scoreColumn = UIStackView(arrangedSubviews: [scoreLabel, incrementLabel])
        scoreColumn.axis = .Vertical
        scoreColumn.alignment = UIStackViewAlignment.Trailing
        scoreColumn.translatesAutoresizingMaskIntoConstraints = false

        let topRow = UIView()
        topRow.addSubview(label)
        topRow.addSubview(scoreColumn)
        
        let column = UIStackView(arrangedSubviews: [topRow] + ["ABCDE", "FGHIJ", "KLMNO", "PQRST", "UVWXY", "ZÅÄÖ"].map(toRow))
        column.axis = .Vertical
        column.distribution = .FillEqually
        column.alignment = .Fill
        column.spacing = SPACING
        column.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(column)
        
        label.leftAnchor.constraintEqualToAnchor(topRow.leftAnchor).active = true
        label.topAnchor.constraintEqualToAnchor(topRow.topAnchor).active = true
        label.bottomAnchor.constraintEqualToAnchor(topRow.bottomAnchor).active = true
        scoreColumn.leftAnchor.constraintEqualToAnchor(label.rightAnchor).active = true
        scoreColumn.rightAnchor.constraintEqualToAnchor(topRow.rightAnchor).active = true
        scoreColumn.topAnchor.constraintEqualToAnchor(topRow.topAnchor).active = true
        scoreColumn.bottomAnchor.constraintEqualToAnchor(topRow.bottomAnchor).active = true
        scoreColumn.widthAnchor.constraintGreaterThanOrEqualToConstant(100).active = true
        column.leftAnchor.constraintEqualToAnchor(view.leftAnchor, constant: 20).active = true
        column.rightAnchor.constraintEqualToAnchor(view.rightAnchor, constant: -20).active = true
        column.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: 30).active = true
        column.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: -30).active = true
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
        var characterCount = characterBuffer.string.characters.count
        if (characterCount > MAX_CHARS) {
            characterBuffer = NSMutableAttributedString.init(string: characterBuffer.string.substringFromIndex(characterBuffer.string.startIndex.successor()))
            characterCount = characterBuffer.string.characters.count;
            for (utterance, index) in pendingUtterances {
                pendingUtterances[utterance] = index - 1
            }
            for (utterance, index) in startedUtterances {
                let newIndex = index - 1
                startedUtterances[utterance] = newIndex
                highlight(utterance, startIndex: newIndex)
            }
        }
        label.attributedText = characterBuffer
        
        let letterUtterance = toUtterance(letter)
        speechSynthesizer.speakUtterance(letterUtterance)
        pendingUtterances[letterUtterance] = characterCount - letterUtterance.speechString.characters.count
        
        let words = getWords()
        let utterances = words.map(toUtterance)
        utterances.forEach({
            let utteranceLength = $0.speechString.characters.count
            utteranceScores[$0] = (utteranceLength, utterances.count)
            pendingUtterances[$0] = characterCount - utteranceLength
            speechSynthesizer.speakUtterance($0)
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
    
    func toUtterance(text: String) -> AVSpeechUtterance {
        let speechUtterance = AVSpeechUtterance(string: text.lowercaseString)
        speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechUtterance.pitchMultiplier = 1.0
        speechUtterance.volume = 1.0
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "fi-FI")
        speechUtterance.preUtteranceDelay = 0.0
        speechUtterance.postUtteranceDelay = 0.0
        return speechUtterance
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
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            if let store = self {
                let startIndex = store.pendingUtterances[utterance]
                store.highlight(utterance, startIndex: startIndex)
                store.label.attributedText = store.characterBuffer
                if let scores = store.utteranceScores[utterance] {
                    store.incrementLabel.text = "+ \(scores.1)x\(scores.0)"
                }
                store.pendingUtterances.removeValueForKey(utterance)
                store.startedUtterances[utterance] = startIndex
            }
        }
    }
    
    func speechSynthesizer(synthesizer: AVSpeechSynthesizer, didFinishSpeechUtterance utterance: AVSpeechUtterance) {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            if let store = self {
                let startIndex = store.startedUtterances[utterance]
                if let startLength = store.adjustedStartAndLength(startIndex, utterance: utterance) {
                    store.characterBuffer.removeAttribute(NSForegroundColorAttributeName, range: NSRange(location: startLength.start, length: startLength.length))
                }
                store.label.attributedText = store.characterBuffer
                if let utteranceScore = store.utteranceScores[utterance] {
                    store.score += utteranceScore.0 * utteranceScore.1
                    store.scoreLabel.text = "\(store.score)"
                    store.incrementLabel.text = " "
                }
                store.utteranceScores.removeValueForKey(utterance)
                store.startedUtterances.removeValueForKey(utterance)
            }
        }
    }
    
    func highlight(utterance: AVSpeechUtterance, startIndex: Int?) {
        if let startLength = adjustedStartAndLength(startIndex, utterance: utterance) {
            characterBuffer.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: NSRange(location: startLength.start, length: startLength.length))
            }
    }
    
    func adjustedStartAndLength(startIndex: Int?, utterance: AVSpeechUtterance) -> (start: Int, length: Int)? {
        if let index = startIndex {
            let length = utterance.speechString.characters.count
            let adjustedIndex = index < 0 ? 0 : index
            let adjustedLength = index < 0 ? index + length : length
            if (adjustedLength > 0) {
                return (adjustedIndex, adjustedLength)
            }
        }
        return nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

