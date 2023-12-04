import Foundation
class Scale {
    let name:String
    let scaleOffsets = [0, 2, 3, 5, 7, 8, 11]

    init(name:String) {
        self.name = name
    }
    
    func setFingers() {
//        for octave in 0..<2 {
//            ///LH
//            setFinger(midi: 44 + (octave * 12), rightHand: <#Bool#>, finger: 3)
//            setFinger(midi: 46 + (octave * 12), finger: 2)
//            setFinger(midi: 47 + (octave * 12), finger: 1)
//            setFinger(midi: 49 + (octave * 12), finger: 4)
//            setFinger(midi: 51 + (octave * 12), finger: 3)
//            setFinger(midi: 52 + (octave * 12), finger: 2)
//            setFinger(midi: 55 + (octave * 12), finger: 1)
//            setFinger(midi: 56 + (octave * 12), finger: 3)
//
//            ///RH
//            setFinger(midi: 68 + (octave * 12), finger: 3, true)
//            setFinger(midi: 70 + (octave * 12), finger: 4)
//            setFinger(midi: 71 + (octave * 12), finger: 1, true)
//            setFinger(midi: 73 + (octave * 12), finger: 2)
//            setFinger(midi: 75 + (octave * 12), finger: 3)
//            setFinger(midi: 76 + (octave * 12), finger: 1, true)
//            setFinger(midi: 79 + (octave * 12), finger: 2)
//            setFinger(midi: 80 + (octave * 12), finger: 3)
//        }
    }
    
    func isMidiInScale(midi:Int) ->Bool {
        let offset = (midi - 32) % 12
        let inScale = scaleOffsets.contains(offset)
        return inScale
    }
    
    func getCorrectFingerStr(rightHand:Bool) -> String {
//        if rightHand {
//            return "\(correctFingerRH + 1)"
//        }
//        else {
//            return "\(correctFingerLH + 1)"
//        }
        return ""
    }
    
    func grade(rightHand:Bool) {
//        if self.wasPressed {
//            self.noteIsCorrect = (self.inScale)
//        }
//        else {
//            if self.inScale {
//                self.noteIsCorrect = false
//            }
//        }
//        if let noteIsCorrect = noteIsCorrect {
//            if rightHand {
//                if self.requiresFingerRH {
//                    self.fingerIsCorrect = self.userFinger == self.correctFingerRH
//                }
//            }
//            else {
//                if self.requiresFingerLH {
//                    self.fingerIsCorrect = self.userFinger == self.correctFingerLH
//                }
//            }
//        }
    }
    func setFinger(midi:Int, rightHand:Bool, finger:Int, _ required:Bool? = nil) {
        ///Fingers are zero based !!!
//        for key in keys {
//            if key.midi == midi {
//                if rightHand {
//                    key.correctFingerRH = finger - 1
//                    if let required = required {
//                        key.requiresFingerRH = required
//                    }
//                }
//                else {
//                    key.correctFingerLH = finger - 1
//                    if let required = required {
//                        key.requiresFingerLH = required
//                    }
//                }
//            }
//        }
    }
}
