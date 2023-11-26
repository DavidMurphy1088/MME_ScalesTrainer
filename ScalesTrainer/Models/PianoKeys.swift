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
    @Published var finger:Int? = nil

    var inScale = false
    let midi:Int
    let color:KeyColor
    var requiresFingerPrompt = false
    
    init(midi:Int) {
        self.midi = midi
        let offset = midi % 12
        color = [0,2,4,5,7,9,11].contains(offset) ? .white : .black
    }
    
//    func setSelected(way:Bool) {
//        DispatchQueue.main.async {
//            self.selected = way
//        }
//    }
    func getFingerStr() -> String {
        //return "F:" + (finger == nil ? "_" : "\(finger!)")
        return "" + (finger == nil ? "" : "\(finger! + 1)")
    }
}

class PianoKeys: ObservableObject {
    @Published var keys:[PianoKey]
    
    init(midi:Int, number:Int) {
        keys = []
        for i in 0...number {
            keys.append(PianoKey(midi: midi + i))
        }
    }
    
    func reset() {
        DispatchQueue.main.async {
            for index in 0..<self.keys.count {
                self.keys[index].wasPressed = false
                self.keys[index].wasLastKeyPressed = false
                self.keys[index].isCorrect = nil
                self.keys[index].finger = nil
                self.keys[index].inScale = [44, 46, 47, 49, 51, 52, 55, 56,   68, 70, 71, 73, 75, 76, 79, 80].contains(self.keys[index].midi)
                self.keys[index].requiresFingerPrompt = [44,49].contains(self.keys[index].midi)
            }
        }
    }
    
    func gradeAnswer() {
        DispatchQueue.main.async {
            for key in self.keys {
                //print(key.midi, "grade pressed", key.wasPressed, "inscale", key.inScale)
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
                //print("  ", p.midi, key.midi, key.wasPressed)
            }
        }
    }
}
