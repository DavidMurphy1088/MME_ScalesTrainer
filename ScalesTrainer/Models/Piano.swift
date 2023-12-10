import SwiftUI
import CommonLibrary
import Combine
import Foundation

protocol PianoUserProtocol: View {
    associatedtype KeyDisplayView: View
    associatedtype KeyActionView: View
    init()
    func getKeyDisplayView(key:PianoKey) -> KeyDisplayView
    func getActionView(piano:Piano) -> KeyActionView
}

//class Fingers {
//    let hand:Int
//    private let midis = [60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81, 83, 84, 86]
//    private var fingers:[Int:Int] = [:]
//
//    init(hand:Int) {
//        self.hand = hand
//        if hand == 1 {
//            fingers[68] = 3
//            fingers[70] = 2
//            fingers[72] = 1
//            fingers[73] = 4
//            fingers[75] = 3
//            fingers[77] = 2
//            fingers[72] = 1
//        }
//    }
//
//    func getFinger(index:Int) -> Int? {
//        if index < 0 {
//            return nil
//        }
//        var midi = midis[index]
//        if index < 5  {
//            return nil
//        }
//        if index > 11 {
//            return nil
//        }
//        midi = midi - (hand == 0 ? 0:1)
//        var f:Int? = nil
//        if fingers.keys.contains(midi) {
//            f = fingers[midi]
//        }
//        print(index, "Midi", midi, "fin", f)
//        return f
//    }
//}

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

    let midi:Int
    let color:KeyColor

    init(midi:Int) {
        self.midi = midi
        let offset = midi % 12
        color = [0,2,4,5,7,9,11].contains(offset) ? .white : .black
    }
    
    func setLastKeyPressed(way:Bool) {
        DispatchQueue.main.async {
            self.wasLastKeyPressed = way
        }
    }
}

class Piano: ObservableObject {
    @Published var keys:[PianoKey]
    let midiSampler = AudioSamplerPlayer.getShared().getSampler()
    var lastGestureTime:Date? = nil
    @Published var lastMidiPressed = 0
    
    init(startMidi:Int, number:Int) {
        keys = []
        for i in 0...number {
            let key = PianoKey(midi: startMidi + i)
            keys.append(key)
        }
    }
    
    func setWasLastKeyPressed(pressedKey:PianoKey, notifyWatchers:Bool = true) {
        DispatchQueue.main.async {
            for key in self.keys {
                if key.midi == pressedKey.midi {
                    key.wasPressed = true
                    key.setLastKeyPressed(way: true)
//                    let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
//                        self.hilightedKey = nil
                    //}
                    //self.av.play(note: UInt8(key.midi))
                    if notifyWatchers {
                        self.lastMidiPressed = key.midi
                    }
                }
                else {
                    key.setLastKeyPressed(way: false)
                }
            }
        }
    }
    
    func clearLastPressed() {
        DispatchQueue.main.async {
            for key in self.keys {
                key.setLastKeyPressed(way: false)
            }
        }
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
                //self.keys[index].userFinger = nil
                //self.keys[index].showInfo = false
            }
        }
    }
    
    func getLastKeyPressed() -> PianoKey {
        for key in self.keys {
            if key.wasLastKeyPressed {
                return key
            }
        }
        return PianoKey(midi: 0)
    }

    func playNote(midi:Int) {
        //self.midiSampler.play(note: UInt8(midi))
        midiSampler.startNote(UInt8(midi), withVelocity:64, onChannel:UInt8(0))
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
                if key.midi < scale.startMidi {
                    continue
                }
                if key.midi > scale.startMidi + scale.noteCount {
                    break
                }
                if scale.isMidiInScale(midi: key.midi) {
                    self.playNote(midi: key.midi)
                    self.setWasLastKeyPressed(pressedKey: key, notifyWatchers: false)
                    Thread.sleep(forTimeInterval: 0.5)
                    count += 1
                    if count >= (octaves * 7) + 1 {
                        break
                    }
                    //break
                }
            }
        }
    }
    
}
