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

class PianoKey: ObservableObject, Equatable {
    static func == (lhs: PianoKey, rhs: PianoKey) -> Bool {
        return lhs.midi == rhs.midi
    }
    
    @Published var wasLastKeyPressed = false
    @Published var wasPressed = false
    //@Published var noteIsCorrect:Bool? = nil
    //@Published var fingerIsCorrect:Bool? = nil

    //@Published var correctFingerRH:Int = 0
    //@Published var correctFingerLH:Int = 0
    @Published var userFinger:Int? = nil
    @Published var showInfo:Bool = false

    //var inScale = false
    let midi:Int
    let color:KeyColor
    
    //var requiresFingerRH = false
    //var requiresFingerLH = false

    init(midi:Int) {
        self.midi = midi
        let offset = midi % 12
        color = [0,2,4,5,7,9,11].contains(offset) ? .white : .black
    }
    
    func getUserFingerStr() -> String {
        guard let userFinger = userFinger else {
            return ""
        }
        return "\(userFinger + 1)"
    }
    
    func setLastKeyPressed(way:Bool) {
        DispatchQueue.main.async {
            self.wasLastKeyPressed = way
        }
    }
    
}

class Piano: ObservableObject {
    @Published var keys:[PianoKey]
    let av = AudioSamplerPlayer.getShared()
    var lastGestureTime:Date? = nil
    @Published var lastKeyPressed = 0

    init(startMidi:Int, number:Int) {
        keys = []
        for i in 0...number {
            let key = PianoKey(midi: startMidi + i)
            keys.append(key)
//            if rightHand {
//                if (startMidi + i) >= 68 && (startMidi + i) <= 92 {
//                    key.inScale = scaleOffsets.contains(startOffset)
//                }
//            }
//            else {
//                if (startMidi + i) >= 44 && (startMidi + i) <= 68 {
//                    key.inScale = scaleOffsets.contains(startOffset)
//                }
//            }
        }
        //debug("Init")
    }
        
    func wasAnyKeyPressed() -> Bool {
        for key in self.keys {
            if key.wasPressed {
                return true
            }
        }
        return false
    }

    func processGesture(key:PianoKey, gesture: DragGesture.Value)  {
        var doTap = false
        if let lastTime = lastGestureTime {
            let diff = gesture.time.timeIntervalSince(lastTime)
            if diff > 0.20 {
                doTap = true
            }
        }
        else {
            doTap = true
        }
        if doTap {
            self.lastGestureTime = gesture.time
            setWasLastKeyPressed(pressedKey: key)
            
        }
    }

    func reset() {
        DispatchQueue.main.async {
            for index in 0..<self.keys.count {
                self.keys[index].wasPressed = false
                self.keys[index].wasLastKeyPressed = false
                //self.keys[index].noteIsCorrect = nil
                //self.keys[index].fingerIsCorrect = nil
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

//    func gradeScale() {
//        //DispatchQueue.main.async {
//            for key in self.keys {
//                //print(key.midi, "grade pressed", key.wasPressed, "inscale", key.inScale)
//                key.wasLastKeyPressed = false
//            }
//            for key in self.keys {
//                //key.grade()
//            }
//        //}
//    }
    
    func getLastKeyPressed() -> PianoKey {
        for key in self.keys {
            if key.wasLastKeyPressed {
                return key
            }
        }
        return PianoKey(midi: 0)
    }

    func setWasLastKeyPressed(pressedKey:PianoKey) {
        DispatchQueue.main.async {
            for key in self.keys {
                if key.midi == pressedKey.midi {
                    key.wasPressed = true
                    key.setLastKeyPressed(way: true)
                    self.av.play(note: UInt8(key.midi))
                    self.lastKeyPressed = key.midi
                }
                else {
                    key.setLastKeyPressed(way: false)
                }
            }
        }
    }
    
    func debug(_ ctx:String, midi:Int? = nil) {
        print("=========Piano Keys", ctx)
        for key in self.keys {
            var show = true
            if let midi = midi {
                show = key.midi == midi
            }
            if show {
                print("  ", "midi", key.midi,
                      //"\tinScale", key.inScale,
                      //"\tCorrectFinger", key.correctFinger ?? "_", "\tReqFinger", key.requiresFingerPrompt,
                      "\tpressed", key.wasPressed)
            }
        }
    }
    
    func playScale(scale:Scale, ascending:Bool, octaves:Int = 2) {
        DispatchQueue.global(qos: .background).async {
            var count = 0
            for i in 0..<self.keys.count {
                let index = ascending ? i : self.keys.count - i - 1
                let key = self.keys[index]
                if scale.isMidiInScale(midi: key.midi) {
                    self.av.play(note: UInt8(key.midi))
                    Thread.sleep(forTimeInterval: 0.5)
                    count += 1
                    if count >= (octaves * 7) + 1 {
                        break
                    }
                    self.setWasLastKeyPressed(pressedKey: key)
                }
            }
        }
    }
    
}
