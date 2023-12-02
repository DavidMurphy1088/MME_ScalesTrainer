import SwiftUI
import CommonLibrary
import Combine
import Foundation

class Fingers {
    let hand:Int
    private let midis = [60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81, 83, 84, 86]
    private var fingers:[Int:Int] = [:]

    init(hand:Int) {
        self.hand = hand
        if hand == 1 {
            fingers[68] = 3
            fingers[70] = 2
            fingers[72] = 1
            fingers[73] = 4
            fingers[75] = 3
            fingers[77] = 2
            fingers[72] = 1
        }
    }
    
    func getFinger(index:Int) -> Int? {
        if index < 0 {
            return nil
        }
        var midi = midis[index]
        if index < 5  {
            return nil
        }
        if index > 11 {
            return nil
        }
        midi = midi - (hand == 0 ? 0:1)
        var f:Int? = nil
        if fingers.keys.contains(midi) {
            f = fingers[midi]
        }
        print(index, "Midi", midi, "fin", f)
        return f
    }
}

enum KeyColor {
    case white
    case black
}

class PianoKey: ObservableObject {
    @Published var wasLastKeyPressed = false
    @Published var wasPressed = false
    @Published var isCorrect:Bool? = nil
    @Published var correctFinger:Int? = nil
    @Published var userFinger:Int? = nil
    @Published var showInfo:Bool = false

    var inScale = false
    let midi:Int
    let color:KeyColor
    var requiresFingerPrompt = false
    
    init(midi:Int) {
        self.midi = midi
        let offset = midi % 12
        color = [0,2,4,5,7,9,11].contains(offset) ? .white : .black
    }
    
    func getFingerStr(user:Bool) -> String {
        //return "F:" + (finger == nil ? "_" : "\(finger!)")
        guard let correctFinger = correctFinger else {
            return ""
        }
        guard let userFinger = userFinger else {
            return ""
        }
        if user {
            return "\(userFinger + 1)"
        }
        else {
            return "\(correctFinger + 1)"
        }
    }
    
}

class PianoKeys: ObservableObject {
    @Published var keys:[PianoKey]
    
    init(midi:Int, number:Int) {
        keys = []
        for i in 0...number {
            let key = PianoKey(midi: midi + i)
            keys.append(key)
            key.inScale = [44, 46, 47, 49, 51, 52, 55, 56,   68, 70, 71, 73, 75, 76, 79, 80].contains(key.midi)
            key.requiresFingerPrompt = [44,49, 68].contains(key.midi)
            ///Fingers are zero based !!!
            ///Do we only need finger when finger cross over thumb -i.e. lefft hard upwards, RH downwards
            if key.midi == 44 {
                key.correctFinger = 2
                //key.showInfo = true
            }
            if key.midi == 49 {
                key.correctFinger = 3
            }
            if key.midi == 68 {
                key.correctFinger = 2
            }
        }
    }
    
    func reset() {
        DispatchQueue.main.async {
            for index in 0..<self.keys.count {
                self.keys[index].wasPressed = false
                self.keys[index].wasLastKeyPressed = false
                self.keys[index].isCorrect = nil
                self.keys[index].userFinger = nil
                self.keys[index].showInfo = false
            }
        }
    }
    
    func setShowInfo(midi:Int, way:Bool) {
        DispatchQueue.main.async {
            for index in 0..<self.keys.count {
                if self.keys[index].midi == midi {
                    self.keys[index].showInfo = way
                }
                else {
                    self.keys[index].showInfo = false
                }
            }
        }
    }

    func gradeAnswer() {
        DispatchQueue.main.async {
            for key in self.keys {
                //print(key.midi, "grade pressed", key.wasPressed, "inscale", key.inScale)
                key.wasLastKeyPressed = false
            }
            for key in self.keys {
                if key.wasPressed {
                    key.isCorrect = (key.inScale)
                }
                else {
                    if key.inScale {
                        key.isCorrect = false
                    }
                }
                if key.requiresFingerPrompt {
                    if key.userFinger != key.correctFinger {
                        key.isCorrect = false
                    }
                }
            }
        }
    }
    
    func setWasLastKeyPressed(pressedKey:PianoKey) {
        DispatchQueue.main.async {
            //print("========setLastPressed")
            for key in self.keys {
                key.wasLastKeyPressed = false
                if key.midi == pressedKey.midi {
                    key.wasLastKeyPressed  = true
                    key.wasPressed = true
                }
                //print("  setWasPressed", key.midi, key.wasPressed, "needs finger:", key.requiresFingerPrompt, "has finger:", key.finger)
            }
        }
    }
}
