import SwiftUI
import CommonLibrary

enum QuestionState {
    case notStarted
    case inQuestion
    case inAnswer
}

enum PracticeState {
    case none
    case playingScale
    case timingScale
}

class KeyState : ObservableObject {
    var midi:Int
    @Published var finger:Int? = nil
    @Published var scaleNoteHilite = false
    var correctScaleOffset:Int? = nil
    var closestMetronomeIndex:Int = 0
    var metronomeTicks:Int? = nil
    var pressedSequenceNumber:Int? = nil
    var nextNoteHilight = false
    var examStatus:NoteDisplayState? = nil

    init(midi:Int) {
        self.midi = midi
    }
    
    func resetPresses() {
        closestMetronomeIndex = 0
        metronomeTicks = nil
        pressedSequenceNumber = nil
    }
}

enum NoteDisplayState {
    case noShow
    case errorState
    case outOfScale
    case missing
    case wrongFinger
    case tooEarly
    case tooLate
    case nextToPlay
    case correct
}

enum AppMode {
    case practiceMode
    case examMode
}

class ScalesAppModel : ObservableObject {
    @Published private var questionState = QuestionState.notStarted
    @Published var practiceState = PracticeState.none
    
    @Published var appMode:AppMode = .practiceMode
    @Published var piano:Piano? = nil
    @Published var statesForMidi:[KeyState?] = []

    @Published var key:Key
    @Published var scaleType:ScaleType
    @Published var scale:Scale
    @Published var lastPressedKey:KeyState?
    
    @Published var showingFingers:Bool = false
    @Published var doubleTempo:Bool = false
    
    @Published var showExamResults:Bool = false
    var examResultCorrectCount:Int?
    var examResultNoteCount:Int?
    var examResultWrongCount:Int?

    var metronomeWasTicking = false
    
    private var metronome = Metronome.getMetronomeWithSettings(initialTempo: 80, allowChangeTempo: true, ctx: "", maxTempo: 200)
    var checkFingerMode = false
    var seeNextFingerMode = false
    
    let pianoTotalKeys = 31
    let pianoStartMidi = 60
    
    let scaleTypes:[ScaleType] = ScaleType.getAllTypes()
    let sharpKeys = Key.getAllKeys(type: .sharp)
    let flatKeys = Key.getAllKeys(type: .flat)
    
    var lastMetronomeTickIndex:Int?

    static let shared:ScalesAppModel = ScalesAppModel()
    
    init() {
        let initKey = Key(type: .major, keySig: KeySignature(keyName: "C", type: .major))
        key = initKey
        let initScaleType = ScaleType.getAllTypes()[0]
        //let initScaleType = ScaleType.getAllTypes()[3]
        scaleType = initScaleType
        scale = Scale(key:initKey, scaleType: initScaleType, rightHand: true)
        setScale(key: initKey, scaleType:initScaleType)
        self.metronome.setTempo(tempo: 80, context: "")
    }
    
    func debugStates(_ ctx:String) {
        print("\nDebug KEY_STATES \(ctx)")
        for midi in 0..<self.statesForMidi.count {
            if midi >= 60 && midi <= 76 {
                if let keyPress = self.statesForMidi[midi] {
                    print("midi", midi,
                          "\tcorrectScaleOffset", keyPress.correctScaleOffset ?? "_",
                          "\tpressSequence", keyPress.pressedSequenceNumber ?? "_",
                          "\tticks:", keyPress.metronomeTicks ?? "_",
                          "\tclosestTick", keyPress.closestMetronomeIndex
                    )
                }
            }
        }
    }

    func saveTap(midi:Int) {
        DispatchQueue.main.async { [self] in
            let keyState = self.statesForMidi[midi]
            guard let keyState = keyState else {
                ///This midi index is outside the range of the piano's midi range
                return
            }
            
            ///Find the next note in the scale and tell it to hilite
            if self.seeNextFingerMode {
                var nextNote:Int?
                for i in 1..<5 {
                    if self.scale.isMidiInScale(midi: midi + i) {
                        nextNote = midi + i
                        break
                    }
                }
                if self.practiceState == .none {
                    for state in self.statesForMidi {
                        state?.nextNoteHilight = state?.midi == nextNote
                    }
                }
            }
            
            ///Metronome handling
            keyState.closestMetronomeIndex = self.metronome.tickTimes.count - 1
            if self.questionState == .inQuestion {
                if self.lastMetronomeTickIndex == nil {
                    keyState.metronomeTicks = nil
                }
                else {
                    let ticks = keyState.closestMetronomeIndex - self.lastMetronomeTickIndex!
                    keyState.metronomeTicks = ticks
                }
                //print("========= GetTicks KeyMidi", midi, "ticks", keyState.metronomeTicks )
            }
            
            if self.lastPressedKey == nil {
                self.lastPressedKey = KeyState(midi: midi)
                self.lastPressedKey!.pressedSequenceNumber = 0
            }
            else {
                self.lastPressedKey!.midi = midi
                self.lastPressedKey!.pressedSequenceNumber! += 1
            }
            keyState.pressedSequenceNumber = self.lastPressedKey?.pressedSequenceNumber
            self.lastMetronomeTickIndex = keyState.closestMetronomeIndex
            
            ///Cause the other piano notes to update their displays
            for key in self.piano!.keys {
                if key.midi != midi {
                    key.redisplay()
                }
            }
            
            ///End scale when two octaves done
            if self.piano?.lastMidiPressed == self.scale.startMidi + 24 {
                endScale()
            }
        }
    }
    
    func getScaleName() -> String {
        return self.key.getKeyName(withType: false) + " " + self.scaleType.getName()
    }
    
    func getQuestionState() -> QuestionState {
        return self.questionState
    }
    
    func stopTicking() {
        metronome.stopTicking()
    }
    
    func startTicking() {
        metronome.startTicking(timeSignature: TimeSignature(top: 4, bottom: 4))
    }

    ///Called before / after an extra UI is presented (e.g. to let user select correct finger)
    func beforeActionSubmitted() {
        self.metronomeWasTicking = self.metronome.tickingIsActive
        self.stopTicking()
    }

    func afterActionSubmitted() {
        if self.metronomeWasTicking {
            self.startTicking()
        }
    }

    func setScale(key:Key, scaleType:ScaleType) {
        DispatchQueue.main.async {
            self.piano?.lastMidiPressed = nil
            self.statesForMidi = Array(repeating: nil, count: 60 + 4*12)
            var piano:Piano
            self.key = key
            self.scaleType = scaleType
            self.scale = Scale(key:key, scaleType: scaleType, rightHand: true)
            if self.scale.startMidi > 67 {
                piano = Piano(startMidi: 65, number: self.pianoTotalKeys)
            }
            else {
                piano = Piano(startMidi: 60, number: self.pianoTotalKeys)
            }
            ///One key state for every piano key
            var correctKeyNum = 0
            for key in piano.keys {
                let keyState = KeyState(midi: key.midi)
                if self.scale.isMidiInScale(midi: key.midi) {
                    keyState.correctScaleOffset = correctKeyNum
                    correctKeyNum += 1
                }
                self.statesForMidi[key.midi] = keyState
            }
            
            self.piano = piano
            self.reset()
        }
    }
    
    func notifiedNotePlayed(midi:Int) {
        DispatchQueue.main.async {
            for s in 0..<25 {
                if let state = self.statesForMidi[s] {
                    state.scaleNoteHilite = state.midi == midi
                }
            }
        }
    }
    
    func playScale() {
        self.setPracticeState(state: .playingScale)
        piano?.playScale(scale: self.scale,
                         metronome: metronome,
                         tempoAdjust: doubleTempo ? 2.0 : 1.0,
                         ascending: true,
                         notifyNotePlayed: notifiedNotePlayed, endNotify: playScaleEnd)
    }
    
    func stopScale() {
        piano?.stopPlayScale()
    }
    
    func playScaleEnd() {
        self.setPracticeState(state: .none)
    }
    
    func reset() {
        DispatchQueue.main.async {
            self.lastMetronomeTickIndex = nil
            self.lastPressedKey = nil
            self.showingFingers = false
            if let piano = self.piano {
                piano.setAllKeysUnPressed()
            }
            for i in 0..<self.statesForMidi.count {
                self.statesForMidi[i]?.resetPresses()
                self.statesForMidi[i]?.nextNoteHilight = false
                self.statesForMidi[i]?.finger = nil
            }
            self.questionState = .notStarted
            self.practiceState = .none
        }
    }
    
    func startExam() {
        DispatchQueue.main.async {
            self.examResultCorrectCount = nil
            self.showExamResults = false
            self.setAppMode(mode: .examMode)
            self.reset()
            self.setQuestionState(state: .inQuestion)
            self.doubleTempo = false
            self.metronome.startTicking(timeSignature: TimeSignature(top: 4, bottom: 4))
        }
    }
    
    func endScale() {
        DispatchQueue.main.async {
            self.setAppMode(mode: .practiceMode)
            self.questionState = .notStarted
            self.metronome.stopTicking()
            var examCorrect = 0
            var examInScale = 0
            var examWrong = 0
            self.debugStates("exam grade")
            for s in 0..<25 {
                guard let state = self.statesForMidi[self.scale.startMidi + s] else {
                    continue
                }
                if self.scale.isMidiInScale(midi: state.midi) {
                    if state.examStatus == .correct {
                        examCorrect += 1
                    }
                    else {
                        //examCorrect -= 1
                    }
                    examInScale += 1
                    print ("==========", state.midi, examCorrect, examInScale)
                }
                else {
                    if state.pressedSequenceNumber != nil {
                        examWrong += 1
                    }
                }
            }
            if self.appMode == .examMode {
                //print("====== END Exam", correct, inScale)
                self.examResultCorrectCount = examCorrect
                self.examResultNoteCount = examInScale
                self.examResultWrongCount = examWrong
                self.showExamResults = true
            }
        }
    }

    func setUsersFingerForMidi(midi:Int, finger:Int) {
        DispatchQueue.main.async {
            self.statesForMidi[midi]?.finger = finger
        }
    }
    
    func setAppMode(mode:AppMode) {
        DispatchQueue.main.async {
            self.appMode = mode
        }
    }
    
    func setShowingFingers(way:Bool) {
        DispatchQueue.main.async {
            self.showingFingers = way
        }
    }
    
    func setDoubleTempo(way:Bool) {
        DispatchQueue.main.async {
            self.doubleTempo = way
        }
    }

    func setQuestionState(state:QuestionState) {
        DispatchQueue.main.async {
            self.questionState = state
        }
    }
    
    func setPracticeState(state:PracticeState) {
        DispatchQueue.main.async {
            self.practiceState = state
        }
    }

    func getUsersFingerForMidi(midi:Int) -> Int? {
        ///Check all octaves of midi
        for i in stride(from: midi, to: self.statesForMidi.count, by: 12) {
            if let finger = self.statesForMidi[i]?.finger {
                return finger
            }
        }
        for i in stride(from: midi, through: 0, by: -12) {
            if let finger = self.statesForMidi[i]?.finger {
                return finger
            }
        }
        return nil
    }
    
    func getNoteStatus(pianoKey:PianoKey) -> NoteDisplayState  {
        let debugNote = 60
//        if [debugNote].contains(midi) {
//            print("=========== getShowStatus1 For_midi", midi)
//            //model.piano?.debug("getShowStatus", midi: midi)
//        }
        let noteState = getNoteShowStatus(pianoKey: pianoKey)
        if let midiState = self.statesForMidi[pianoKey.midi] {
            midiState.examStatus = noteState
        }
        if self.appMode == .examMode {
            return NoteDisplayState .noShow
        }

//        if [debugNote].contains(midi) {
//            print("=========== getShowStatus2 For_midi", midi, "ShowStatus", state)
//            //model.piano?.debug("getShowStatus", midi: midi)
//        }
        return noteState
    }

    ///Decide the display status for each piano key on the keyboard
    private func getNoteShowStatus(pianoKey:PianoKey) -> NoteDisplayState  {
        if pianoKey.midi < scale.startMidi || pianoKey.midi > scale.startMidi + 24 {
            return NoteDisplayState .noShow
        }
        let stateForMidi = self.statesForMidi[pianoKey.midi]
        guard let stateForMidi = stateForMidi else {
            return .errorState
        }
        
        if pianoKey.midi == 60 {
//            print("==== getNoteShowStatus",
//                  pianoKey.midi, "lastPressed",
//                  lastPressedKey?.midi ?? "_", "seq",
//                  lastPressedKey?.pressedSequenceNumber ?? "_",
//                  "hilite", stateForMidi.midi, stateForMidi.nextNoteHilight)
//            //debugStates("getNoteShowStatus")
        }
        
        if stateForMidi.nextNoteHilight {
            return .nextToPlay
        }
        let noteInScale = scale.isMidiInScale(midi: pianoKey.midi)

        ///Check for missing notes
        if let lastPressedKey = self.lastPressedKey {
            if noteInScale {
                if stateForMidi.pressedSequenceNumber == nil {
                    ///Determine if a following scale note was pressed (but this note was not)
                    for i in 1..<24 {
                        if scale.isMidiInScale(midi: stateForMidi.midi + i) {
                            if pianoKey.midi + i < self.statesForMidi.count {
                                if self.statesForMidi[pianoKey.midi + i]?.pressedSequenceNumber != nil {
                                    return .missing
                                }
                            }
                        }
                    }
                }
            }
        }

        ///Check fingering
        if let requiredFinger = scale.getRequiredFinger(midi: stateForMidi.midi) {
            if let userFinger = stateForMidi.finger {
                if userFinger != requiredFinger {
                    return .wrongFinger
                }
            }
        }
        
        ///Check note values from metronome
        if stateForMidi.pressedSequenceNumber != nil {
            if !noteInScale {
                return .outOfScale
            }
            if let ticks = stateForMidi.metronomeTicks {
                if ticks > 9 {
                    return .tooLate
                }
                if ticks < 6 {
                    return .tooEarly
                }
            }
            return NoteDisplayState.correct
        }
        return .noShow
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

