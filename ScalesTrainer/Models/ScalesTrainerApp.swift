import SwiftUI
import CommonLibrary

enum QuestionMode {
    case notStarted
    case inQuestion
    case inAnswer
}

class ScalesAppModel : ObservableObject {
    enum NoteState {
        case noShow
        case inScale
        case outOfScale
        case missing
        case wrongFinger
    }

    @Published var timedMode:Bool = false
    @Published var questionMode = QuestionMode.notStarted
    @Published var piano:Piano
    @Published var fingerUsedByMidi:[Int?]
    @Published var keyPressesForMidi:[Int]    

    @Published var key:Key
    @Published var scaleType:ScaleType
    @Published var scale:Scale
    
    var metronome = Metronome.getMetronomeWithSettings(initialTempo: 60, allowChangeTempo: true, ctx: "")
    var checkFingerNumbers = false
    let totalKeys = 31
    
    let scaleTypes:[ScaleType] = ScaleType.getAllTypes()
    let sharpKeys = Key.getAllKeys(type: .sharp)
    let flatKeys = Key.getAllKeys(type: .flat)

    static let shared:ScalesAppModel = ScalesAppModel()
    
    init() {
        self.piano = Piano(startMidi: 65, number: totalKeys)
        fingerUsedByMidi = Array(repeating: nil, count: 65 + totalKeys + 1)
        keyPressesForMidi = Array(repeating: 0, count: 65 + totalKeys + 1)
        let initKey = Key(type: .major, keySig: KeySignature(keyName: "C", type: .major))
        let initScaleType = ScaleType(type: .major, ascendingScaleOffsets: [])
        key = initKey
        scaleType = initScaleType
        scale = Scale(key:initKey, scaleType: initScaleType, rightHand: true)
    }
    
    func getScaleName() -> String {
        return self.key.getKeyName(withType: false) + " " + self.scaleType.getName()
    }
    
    func setScale(key:Key, scaleType:ScaleType) {
        DispatchQueue.main.async {
            self.key = key
            self.scaleType = scaleType
            self.scale = Scale(key:key, scaleType: scaleType, rightHand: true)
        }
    }
    
    func reset() {
        DispatchQueue.main.async {
            for i in 0..<self.fingerUsedByMidi.count {
                self.fingerUsedByMidi[i] = nil
                self.keyPressesForMidi[i] = 0
            }
        }
    }
    
    func setTimedMode(way:Bool) {
        DispatchQueue.main.async {
            self.timedMode = way
        }
    }
    
    func setQuestionMode(way:QuestionMode) {
        DispatchQueue.main.async {
            self.questionMode = way
        }
    }
    
    func setUsersFingerForMidi(midi:Int, finger:Int) {
        DispatchQueue.main.async {
            self.fingerUsedByMidi[midi] = finger
        }
    }
    
    func getUsersFingerForMidi(midi:Int) -> Int? {
        ///Check all octaves of midi
        for i in stride(from: midi, to: fingerUsedByMidi.count, by: 12) {
            if let finger = fingerUsedByMidi[i] {
                return finger
            }
        }
        for i in stride(from: midi, through: 0, by: -12) {
            if let finger = fingerUsedByMidi[i] {
                return finger
            }
        }
        return nil
    }
    
    func addKeyPressedForMidi(midi:Int) {
        DispatchQueue.main.async {
            self.keyPressesForMidi[midi] += 1
        }
    }
    
    func getNoteStatus(key:PianoKey) -> NoteState {
        let noteInScale = scale.isMidiInScale(midi: key.midi)
        if questionMode == .notStarted {
            if key.wasPressed  {
                if noteInScale {
                    if checkFingerNumbers {
                        if let finger = fingerUsedByMidi[key.midi] {
                            if finger != scale.getRequiredFinger(midi: key.midi) {
                                return NoteState.wrongFinger
                            }
                        }
                    }
                    return NoteState.inScale
                }
                else {
                    return NoteState.outOfScale
                }
            }
            else {
                return NoteState.noShow
            }
        }
        if questionMode == .inQuestion {
            return NoteState.noShow
        }
        if questionMode == .inAnswer {
            if key.wasPressed  {
                if noteInScale {
                    if let finger = fingerUsedByMidi[key.midi] {
                        if finger != scale.getRequiredFinger(midi: key.midi) {
                            return NoteState.wrongFinger
                        }
                    }
                    return NoteState.inScale
                }
                else {
                    return NoteState.outOfScale
                }
            }
            else {
                if key.midi < scale.startMidi || key.midi > (scale.startMidi + scale.noteCount) {
                    return NoteState.noShow
                }
                if noteInScale {
                    return .missing
                }
            }
        }
        return NoteState.noShow
    }
}

@main
struct ScalesTrainerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ScalesView(showSelectScale: false)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

