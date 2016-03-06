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
    var characterBuffer: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
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
        characterBuffer += letter
        label.text = characterBuffer
        say(letter)
        
        ["ÄITI", "AUTO", "OSKARI"].forEach {
            if characterBuffer.hasSuffix($0) {
                say($0)
            }
        }
    }
    
    func say(text: String) {
        let speechUtterance = AVSpeechUtterance(string: text.lowercaseString)
        speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechUtterance.pitchMultiplier = 1.0
        speechUtterance.volume = 1.0
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "fi-FI")
        speechSynthesizer.speakUtterance(speechUtterance)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

