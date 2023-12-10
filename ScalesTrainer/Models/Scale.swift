import Foundation
import CommonLibrary

enum ScaleShapeType {
    case major
    //case naturalMinor
    case harmonicMinor
    case melodicMinor
    case chromatic
    case majorArpeggio
    case minorArpeggio
}

class ScaleType : ObservableObject, Equatable, Hashable, Identifiable {  
    public let idx = UUID()
    let type:ScaleShapeType
    let ascendingScaleOffsets:[Int]
    ///required since descedning is different for melodic minor
    let descendingScaleOffsets:[Int]

    static func == (lhs: ScaleType, rhs: ScaleType) -> Bool {
        return lhs.idx == rhs.idx
    }
    
    init(type:ScaleShapeType, ascendingScaleOffsets:[Int], descendingScaleOffsets:([Int]?) = nil) {
        self.type = type
        self.ascendingScaleOffsets = ascendingScaleOffsets
        if let descendingScaleOffsets = descendingScaleOffsets {
            self.descendingScaleOffsets = ascendingScaleOffsets
        }
        else {
            self.descendingScaleOffsets = ascendingScaleOffsets
        }
    }
    
    func getName() -> String {
        var name = ""
        switch type {
        case .major:
            name = "Major"
//        case .naturalMinor:
//            name = "Natural Minor"
        case .harmonicMinor:
            name = "Harmonic Minor"
        case .melodicMinor:
            name = "Melodic Minor"
        case .chromatic:
            name = "Chromatic"
        case .majorArpeggio:
            name = "Major Arpgeggio"
        case .minorArpeggio:
            name = "Minor Arpeggio"
        }
        return name
    }
    
    static public func getAllTypes() -> [ScaleType] {
        var result:[ScaleType] = []
        result.append(ScaleType(type: .major, ascendingScaleOffsets: [0,2,4,5,7,9,11]))
        result.append(ScaleType(type: .harmonicMinor, ascendingScaleOffsets: [0,2,3,5,7,8,11]))
        result.append(ScaleType(type: .melodicMinor, ascendingScaleOffsets: [0,2,3,5,7,8,11], descendingScaleOffsets:[0,2,3,5,7,8,10]))
        //result.append(ScaleType(type: .naturalMinor, ascendingScaleOffsets: [0,2,3,5,7,8,10]))
        result.append(ScaleType(type: .chromatic, ascendingScaleOffsets: [0,1,2,3,4,5,6,7,8,9,10,11]))
        result.append(ScaleType(type: .majorArpeggio, ascendingScaleOffsets: [0,4,7]))
        result.append(ScaleType(type: .minorArpeggio, ascendingScaleOffsets: [0,3,7]))
        return result
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(idx)
    }
}

class Scale {
    let key:Key
    let scaleType:ScaleType
    let rightHand:Bool
    
    var startMidi:Int = 0
    var startFinger = 0
    var fingerBreakIndex = 0
    
    var noteCount = 24
    
    var fingers:[Int?] = [Int?](repeating: nil, count: 12)
    
    init(key:Key, scaleType:ScaleType, rightHand:Bool) {
        self.key = key
        self.scaleType = scaleType
        self.rightHand = rightHand
        startMidi = key.firstScaleNote()
        if rightHand {
            while startMidi < 60 {
                startMidi += 12
            }
            if isWhiteKey(midi: startMidi) {
                startFinger = 0
                fingerBreakIndex = 3
            }
        }
        setFingers()
    }
    
    private func isWhiteKey(midi:Int) -> Bool {
        let offset = (midi - 24) % 12
        return [0,2,4,5,7,9,11].contains(offset)
    }
    
    ///Set fingers of the scale starting at the first finger
    ///All the fingers can bet set as the next finger except once in the scale
    func setFingers() {
        var next = startFinger
        var cnt = 0
        for offset in scaleType.ascendingScaleOffsets {
            fingers[offset] = next
            if cnt == fingerBreakIndex - 1 {
                next = 0
            }
            else {
                if next == 4 {
                    next = 0
                }
                else {
                    next = next + 1
                }
            }
            cnt += 1
        }
    }
    
    func getFinger(midi:Int) -> Int? {
        if midi < self.startMidi {
            return nil
        }
        if midi > self.startMidi + 24 {
            return nil
        }
        var scaleOffset = (midi % 12) 
        if scaleOffset < 0 {
            scaleOffset += 12
        }
        return fingers[scaleOffset]
    }
    
    func isMidiInScale(midi:Int) ->Bool {
        let offset = (midi - key.lowestNote) % 12
        let inScale = scaleType.ascendingScaleOffsets.contains(offset)
        return inScale
    }
    
    ///Return finger number for a midi in the scale that the user must specify
    func getRequiredFinger(midi:Int) -> Int? {
        let offset = (midi - 32) % 12
        if offset == 0 {
            return 2
        }
        if offset == 5 {
            return 3
        }
        return nil
    }
    
    func getFingerName(finger: Int) -> String {
        var name = ""
        switch finger {
        case 0:
            name = "Thumb"
        case 1:
            name = "Second Finger"
        case 2:
            name = "Third Finger"
        case 3:
            name = "Fourth Finger"
        case 4:
            name = "Fifth Finger"
        default:
            name = ""
        }
        return name
    }
}

//class TrainerScaleTypes {
//    var scaleTypes:[ScaleType] = []
//    init() {
//        scaleTypes.append(ScaleType(type: .major, scaleOffsets: [0, 2, 4, 5, 7, 9, 11]))
//        scaleTypes.append(ScaleType(type: .harmonicMinor, scaleOffsets: [0, 2, 3, 5, 7, 8, 11]))
//
////        let key = Key(type: Key.KeyType.minor, keySig: KeySignature(type: .flat, count: 7))
////        let shape = ScaleShape(type: .harmonicMinor, scaleOffsets: [0, 2, 3, 5, 7, 8, 11])
////        scales.append(Scale(key: key, scaleShape: shape, rightHand: true))
////        let shape = ScaleShape(type: .harmonicMinor, scaleOffsets: [0, 2, 3, 5, 7, 8, 11])
//    }
//}

//class TrainerKeys {
//    var keys:[Key] = []
//    init() {
//        keys.append(Key(type: Key.KeyType.major, keySig: KeySignature(type: .sharp, count: 0)))
//        keys.append(Key(type: Key.KeyType.minor, keySig: KeySignature(type: .flat, count: 7)))
//    }
//}
