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
    
    func grade() {
        if self.wasPressed {
            self.isCorrect = (self.inScale)
        }
        else {
            if self.inScale {
                self.isCorrect = false
            }
        }
        if self.requiresFingerPrompt {
            if self.userFinger != self.correctFinger {
                self.isCorrect = false
            }
        }
    }
}

class PianoKeys: ObservableObject {
    @Published var keys:[PianoKey]
    
    func setFinger(midi:Int, finger:Int) {
        ///Fingers are zero based !!!
        for key in keys {
            if key.midi == midi {
                key.correctFinger = finger - 1
            }
        }
    }
    
    init(startMidi:Int, number:Int, ascending:Bool, fingerMode:Bool) {
        keys = []
        for i in 0...number {
            let key = PianoKey(midi: startMidi + i)
            keys.append(key)
            key.inScale = [44, 46, 47, 49, 51, 52, 55, 56,   68, 70, 71, 73, 75, 76, 79, 80].contains(key.midi)
            if fingerMode {
                ///Set the keys that will prompt for a finger
                ///Do we only need finger when finger cross over thumb -i.e. lefft hard upwards, RH downwards
                if ascending {
                    key.requiresFingerPrompt = [44,49,56,    68,71].contains(key.midi)
                }
                else {
                    key.requiresFingerPrompt = [56, 55,  47  ].contains(key.midi)
                }
            }
        }
        ///LH
        setFinger(midi: 44, finger: 3)
        setFinger(midi: 46, finger: 2)
        setFinger(midi: 47, finger: 1)
        setFinger(midi: 49, finger: 4)
        setFinger(midi: 51, finger: 3)
        setFinger(midi: 52, finger: 2)
        setFinger(midi: 55, finger: 1)
        setFinger(midi: 56, finger: 3)
        
        ///RH
        setFinger(midi: 68, finger: 2)
        setFinger(midi: 70, finger: 3)
        setFinger(midi: 71, finger: 1)
        setFinger(midi: 73, finger: 1)
        setFinger(midi: 75, finger: 1)
    }
    
    func wasAnyKeyPressed() -> Bool {
        for key in self.keys {
            if key.wasPressed {
                return true
            }
        }
        return false
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
        //DispatchQueue.main.async {
            for index in 0..<self.keys.count {
                if self.keys[index].midi == midi {
                    self.keys[index].showInfo = way
                }
                else {
                    self.keys[index].showInfo = false
                }
            }
        //}
    }

    func gradeScale() {
        //DispatchQueue.main.async {
            for key in self.keys {
                //print(key.midi, "grade pressed", key.wasPressed, "inscale", key.inScale)
                key.wasLastKeyPressed = false
            }
            for key in self.keys {
                key.grade()
            }
        //}
    }
    
    func getLastKeyPressed() -> PianoKey? {
        for key in self.keys {
            if key.wasLastKeyPressed {
                return key
            }
        }
        return nil
    }

    func setWasLastKeyPressed(pressedKey:PianoKey) {
        //DispatchQueue.main.async {
            //print("========setLastPressed")
            for key in self.keys {
                key.wasLastKeyPressed = false
                if key.midi == pressedKey.midi {
                    key.wasLastKeyPressed  = true
                    key.wasPressed = true
                }
                //print("  setWasPressed", key.midi, key.wasPressed, "needs finger:", key.requiresFingerPrompt, "has finger:", key.finger)
            }
        //}
    }
    
    func debug(_ ctx:String, midi:Int? = nil) {
        print("=========Keys", ctx)
        for key in self.keys {
            var show = true
            if let midi = midi {
                show = key.midi == midi
            }
            if show {
                print("  ", "midi", key.midi, "pressed", key.wasPressed)
            }
        }
    }
}
