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

struct HandView:View {
    @Binding var lastPianoKeyPressed:PianoKey?
    @Binding var selectedFinger: Int?
    let frameHeight:Double
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    ForEach(0..<5) { index in
                        ZStack {
                            Rectangle()
                                .fill(Color.blue)
                                //.opacity(opacity ? 1.0 : 0.3)
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

struct PianoKeyView: View {
    let id:Int
    @ObservedObject var pianoKey:PianoKey
        
    func getColor(_ key:PianoKey) -> Color {
        if key.wasLastKeyPressed {
            return Color(.systemTeal)
        }
        else {
            return pianoKey.color == .white ? Color.white : Color.black
        }
    }

    func getID() -> String {
//        let uuidString = id.uuidString
//        let lastTwoCharacters = String(uuidString.suffix(2))
//        return lastTwoCharacters
        return "\(id)"
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
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .frame(height: 40)
                        .foregroundColor(getColor(pianoKey))
                        //.offset(y: whiteKeyHeight * 0.10)
                        .opacity(pianoKey.color == .white ? 0.0 : 1.0)
                )
            
            VStack {
                Spacer()
                //Text("M:\(pianoKey.midi)").foregroundColor(.red).bold().font(.title3)
                //Text("I:\(getID())").foregroundColor(.red).bold().font(.title3)
                Text("\(pianoKey.getFingerStr())").foregroundColor(.blue).bold().font(.title)
                //Text(getCorrect(pianoKey).1).foregroundColor(getCorrect(pianoKey).0 ? Color(.green) : Color(.red)).bold().font(.title)
                Text("")
                Text("")
            }
        }
//        .border(.green)
    }
}

struct KeyboardView: View {
    let hand:Int
    @ObservedObject var pianoKeys:PianoKeys
    @Binding var timeAllowed:Double

    @State var timeRemaining:Double = 0.0
    @State var offset = 0.0
    
    let whiteKeyWidth = 60.0
    var blackKeyWidth = 0.0
    
    @State var clickNumber = 0
    @State var timer: AnyCancellable?
    @State var state:PlayState = .notStarted
    //@State var isSheetPresented = false
    
    @State var whiteKeyHeight = 200.0
    @State var lastGestureTime:Date? = nil
    @State var requiresFingerPrompt = false
    @State var selectedFinger:Int? = nil
    @State var lastPianoKeyPressed:PianoKey?

    let av = AudioSamplerPlayer.getShared()

    init(pianoKeys:PianoKeys, hand:Int, timeAllowed:Binding<Double>) {
        self.pianoKeys = pianoKeys
        self.hand = hand
        blackKeyWidth = whiteKeyWidth * 0.7
        _timeAllowed = timeAllowed
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
                state = .started
                pianoKeys.reset()
                if state == .started {
                    startTimer()
                    //isSheetPresented = true
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
    
    func onTap(pianoKey:PianoKey, gesture: DragGesture.Value) -> Bool {
        if pianoKey.requiresFingerPrompt {
            if pianoKey.finger == nil {
                return true
            }
        }
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
            pianoKeys.setWasLastKeyPressed(pressedKey: pianoKey)
            print("================ Tap", pianoKey.midi)
            av.play(note: UInt8(pianoKey.midi))
            clickNumber += 1
        }
        return false
    }
    
    var body: some View {
        VStack {
            buttonsView()
            ZStack(alignment: .topLeading) { // Aligning to the top and leading edge
                ///White notes
            
                HStack(spacing: 0) {
                    ForEach(0..<pianoKeys.keys.count, id: \.self) { index in
                        if pianoKeys.keys[index].color == .white {
                            PianoKeyView(id:index, pianoKey: pianoKeys.keys[index])
                            .frame(width: whiteKeyWidth, height: whiteKeyHeight)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged({ gesture in
                                        lastPianoKeyPressed = pianoKeys.keys[index]
                                        requiresFingerPrompt = onTap(pianoKey: pianoKeys.keys[index], gesture: gesture)
                                    })
                                )
                        }
                    }
                }
                .border(Color.black, width: 1)

                ///Black notes
                HStack(spacing: 0) {
                    ForEach(0..<pianoKeys.keys.count, id: \.self) { index in
                        if pianoKeys.keys[index].color == .black {
                            PianoKeyView(id:index, pianoKey: pianoKeys.keys[index])
                            .frame(width: blackKeyWidth, height: whiteKeyHeight * 0.60)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged({ gesture in
                                        lastPianoKeyPressed = pianoKeys.keys[index]
                                        requiresFingerPrompt = onTap(pianoKey: pianoKeys.keys[index], gesture: gesture)
                                    })
                                )
                            Spacer().frame(width: whiteKeyWidth - blackKeyWidth)
                        }
                        else {
                            Spacer().frame(width: getBlackSpacing(index: index))
                        }
                    }
                }
                .padding(.leading, whiteKeyWidth - blackKeyWidth / 2.0)
            }
        }
        .onAppear() {
            self.timeRemaining = self.timeAllowed
            pianoKeys.reset()
            Settings.shared.useUpstrokeTaps = false
        }
        .onChange(of: selectedFinger) { finger in
            print("============Finger", finger)
            if let lastPianoKeyPressed = lastPianoKeyPressed {
                lastPianoKeyPressed.finger = finger
                pianoKeys.setWasLastKeyPressed(pressedKey: lastPianoKeyPressed)
                //print("================ Tap", pianoKey.midi)
                av.play(note: UInt8(lastPianoKeyPressed.midi))

            }
        }

        //if requiresFingerPrompt {
            HandView(
                lastPianoKeyPressed: $lastPianoKeyPressed,
                selectedFinger: $selectedFinger,
                frameHeight: 50)
            .opacity(requiresFingerPrompt ? 1.0 : 0.2)
        //}
    }
}

enum PlayState {
    case notStarted
    case started
    case completed
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
           // Metronome.getMetronomeWithSettings(initialTempo:60, allowChangeTempo:true, ctx:"")
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
//            .onAppear() {
//                let staff = Staff(score: score, type: .treble, staffNum: 0, linesInStaff: 5)
//                self.score.createStaff(num: 0, staff: staff)
//                var ts = score.createTimeSlice()
//                ts.addNote(n: Note(timeSlice: ts, num: 72, staffNum: 0))
//            }
    }
}
