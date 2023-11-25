import SwiftUI
import CommonLibrary
import Combine

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
        return "F:" + (finger == nil ? "X" : "\(finger!)")
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
                self.keys[index].inScale = [44, 46, 47, 49, 51, 52, 55, 56,   68, 70, 71, 73, 75, 76, 79, 80].contains(self.keys[index].midi)
                self.keys[index].finger = self.keys[index].midi == 44 ? nil : 1
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

struct SelectScaleView: View {
    var body: some View {
        VStack {
            Button(action: {
            }) {
                Text("A\u{266D} Harmonic Minor").defaultButtonStyle()
            }
        }
    }
}

struct PianoKeyView: View {
    @ObservedObject var pianoKeys:PianoKeys
    @ObservedObject var pianoKey:PianoKey
    @Binding var activateFingerChoiceForMidi:Int?
    @Binding var clickNumber:Int
    let av = AudioSamplerPlayer.getShared()
    
    func getColor(_ key:PianoKey) -> Color {
        if key.wasLastKeyPressed {
            return Color(.systemTeal)
        }
        else {
            return pianoKey.color == .white ? Color.white : Color.black
        }
    }
    
    func getCorrect(_ key:PianoKey) -> (Bool, String) {
        if let answer = pianoKey.isCorrect {
            return (answer, answer ? "\u{2713}" : "X")
        }
        else {
            return (false, "")
        }
    }
    
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(getColor(pianoKey))
                .border(.black, width: 1)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 10, style: .continuous)
//                        .frame(height: 40)
//                        .foregroundColor(getColor(pianoKey))
//                        .offset(y: whiteKeyHeight * 0.10)
//                        .opacity(pianoKey.color == .white ? 0.0 : 1.0)
//                )

            VStack {
                Spacer()
                Text("\(pianoKey.midi)").foregroundColor(.red).bold().font(.title3)
                Text("\(pianoKey.getFingerStr())").foregroundColor(.red).bold().font(.title3)
                Text(getCorrect(pianoKey).1).foregroundColor(getCorrect(pianoKey).0 ? Color(.green) : Color(.red)).bold().font(.title)
                Text("")
                Text("")
            }
        }
        .onTapGesture {
            if pianoKey.finger == nil {
                activateFingerChoiceForMidi = pianoKey.midi
            }
            else {
                pianoKeys.setWasLastKeyPressed(pressedKey: pianoKey)
                av.play(note: UInt8(pianoKey.midi))
                clickNumber += 1
            }
        }
    }
}

struct KeyboardView: View {
    let hand:Int
    @ObservedObject var pianoKeys:PianoKeys
    @Binding var timeAllowed:Double

    @State var timeRemaining:Double = 0.0
    @State var offset = 0.0
    let whiteKeyWidth = 70.0
    var blackKeyWidth = 0.0
    @State var clickNumber = 0
    @State var timer: AnyCancellable?
    @State var state:PlayState = .notStarted
    @State var isSheetPresented = false
    @State var whiteKeyHeight = 200.0
    @State var handViewPopup = true
    @State var activateFingerChoiceForMidi:Int? = nil
    @State var selectedFinger = 0

    init(pianoKeys:PianoKeys, hand:Int, timeAllowed:Binding<Double>) {
        self.pianoKeys = pianoKeys
        self.hand = hand
        blackKeyWidth = whiteKeyWidth * 0.7
        _timeAllowed = timeAllowed
        //self.timeRemaining = self.timeAllowed
    }
    
    func startTimer() {
        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timer?.cancel()
                    self.state = .completed
                    self.clickNumber = 0
                    self.timeRemaining = timeAllowed
                    pianoKeys.gradeAnswer()
                }
            }
    }
    
    func getBlackSpacing(index:Int) -> CGFloat {
        if index >= pianoKeys.keys.count-1 {
            return 0
        }
        if pianoKeys.keys[index].color == .white && pianoKeys.keys[index+1].color == .white {
            return whiteKeyWidth
        }
        return 0.0
    }
    
    func getName() -> String {
        return hand == 0 ? "Right Hand" : "Left Hand"
    }
    
    func buttonsView() -> some View {
        HStack {
            Text(getName()).font(.title).padding()
            Button(action: {
                handViewPopup = true
            }) {
                if state == .notStarted {
                    Text("Pick Finger").font(.title)
                }
            }
            Button(action: {
                state = .started
                pianoKeys.reset()
                if state == .started {
                    startTimer()
                    isSheetPresented = true
                }
            }) {
                if state == .notStarted {
                    Text("Start Scale").font(.title)
                }
            }
            .padding()
            if state == .started {
                CircularProgressView(progress: CGFloat(timeRemaining) / 30.0, timeRemaining: Int(timeRemaining))
                    .frame(width: 50, height: 50)
                    .padding(20)
            }
            if state == .completed {
                Button(action: {
                    state = .notStarted
                    pianoKeys.reset()
                }) {
                    Text("Try Again").font(.title)
                }

            }
        }
    }
    
    var body: some View {
        VStack {
            buttonsView()
            ZStack(alignment: .topLeading) { // Aligning to the top and leading edge
                ///White notes
                HStack(spacing: 0) {
                    ForEach(0..<pianoKeys.keys.count, id: \.self) { index in
                        if pianoKeys.keys[index].color == .white {
                            PianoKeyView(pianoKeys: pianoKeys,
                                         pianoKey: pianoKeys.keys[index],
                                         activateFingerChoiceForMidi: $activateFingerChoiceForMidi,
                                         clickNumber: $clickNumber)
                            .frame(width: whiteKeyWidth, height: whiteKeyHeight)
                        }
                    }
                }
                .border(Color.black, width: 1)
                
                ///Black notes
                HStack(spacing: 0) {
                    ForEach(0..<pianoKeys.keys.count, id: \.self) { index in
                        if pianoKeys.keys[index].color == .black {
                            PianoKeyView(pianoKeys: pianoKeys,
                                         pianoKey: pianoKeys.keys[index],
                                         activateFingerChoiceForMidi: $activateFingerChoiceForMidi,
                                         clickNumber: $clickNumber)
                            .frame(width: blackKeyWidth, height: whiteKeyHeight * 0.60)
                            Spacer().frame(width: whiteKeyWidth - blackKeyWidth)
                        }
                        else {
                            Spacer().frame(width: getBlackSpacing(index: index))
                        }
                    }
                }
                .padding(.leading, whiteKeyWidth - blackKeyWidth / 2.0)
            }
            
            HandView(
                
                opacity: Binding(
                get: { self.selectedFinger },
                set: { newValue in
                    //self.opacity = newValue
                }),
                
                selectedFinger: Binding(
                get: { self.selectedFinger },
                set: { newValue in
                    self.selectedFinger = newValue
                    // Perform any additional actions here
                    print("Value changed to \(newValue) for midi \(activateFingerChoiceForMidi)")
                }),
                frameHeight: 50
            )

        }
        .onAppear() {
            self.timeRemaining = self.timeAllowed
            pianoKeys.reset()
        }
    }
}

enum PlayState {
    case notStarted
    case started
    case completed
}

struct HandView:View {
    @Binding var opacity: Bool
    @Binding var selectedFinger: Int
    let frameHeight:Double
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    ForEach(0..<5) { index in
                        ZStack {
                            Rectangle()
                                .fill(Color.blue)
                                .opacity(opacity ? 1.0 : 0.3)
                                .frame(width: 80, height: 40)
                                .onTapGesture {
                                    selectedFinger = index
                                }

                            Text("\(5 - index)")
                        }
                    }
                }
                Image("lh")
                    .resizable() // Make the image resizable
                    .scaledToFit() // Scale the image to fit its container
                    .frame(height: frameHeight) // Set the desired width and height

                //Spacer().frame(height: 500)
            }
        }
    }
}

struct ScalesView: View {
    @ObservedObject var score:Score
    var pianoKeysLH = PianoKeys(midi: 36, number: 24)
    var pianoKeysRH = PianoKeys(midi: 60, number: 24)
    @State var timeAllowed = 10.0
    
    init(score:Score) {
        self.score = score
    }

    var body: some View {
        VStack {
            Text("Scale Trainer").font(.title).padding()
            
            HStack {
                SelectScaleView().padding()
                HStack {
                    Text("Time Allowed \(Int(timeAllowed))").font(.title).padding()
                    Slider(value: $timeAllowed, in: 0...20, step: 1.0).padding()
                }
                .padding()

            }

            //ScoreView(score: score).padding()
            
            //ToolsView(score: score, helpMetronome: "")
            
            KeyboardView(pianoKeys: pianoKeysRH, hand: 0, timeAllowed: $timeAllowed).padding()

            KeyboardView(pianoKeys: pianoKeysLH, hand: 1, timeAllowed: $timeAllowed).padding()
        }
        .onAppear() {
            Metronome.getMetronomeWithSettings(initialTempo:60, allowChangeTempo:true, ctx:"")
        }
    }
}

struct ContentView: View {
    var score:Score
    init() {
        score = Score(key: Key(type: .major, keySig:KeySignature(type: .sharp, keyName: "C")), timeSignature: TimeSignature(top: 4, bottom: 4), linesPerStaff: 5)
    }
    var body: some View {
        ScalesView(score: score)
            //.padding()
            .onAppear() {
                let staff = Staff(score: score, type: .treble, staffNum: 0, linesInStaff: 5)
                self.score.createStaff(num: 0, staff: staff)
                var ts = score.createTimeSlice()
                ts.addNote(n: Note(timeSlice: ts, num: 72, staffNum: 0))
            }
    }
}
