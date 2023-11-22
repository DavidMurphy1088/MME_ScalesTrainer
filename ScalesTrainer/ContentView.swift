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
    @Published var selected = false
    @Published var wasPressed = false
    let midi:Int
    let color:KeyColor
    
    init(midi:Int) {
        self.midi = midi
        let offset = midi % 12
        color = [0,2,4,5,7,9,11].contains(offset) ? .white : .black
    }
    
    func setSelected(way:Bool) {
        DispatchQueue.main.async {
            self.selected = way
        }
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
    
    func setPressed(pressedKey:PianoKey? = nil) {
        DispatchQueue.main.async {
            for key in self.keys {
                if let p = pressedKey {
                    key.wasPressed = key.midi == p.midi
                }
                else {
                    key.wasPressed = false
                }
            }
        }
    }
}

struct PianoKeyView: View {
    @ObservedObject var pianoKeys:PianoKeys
    @ObservedObject var pianoKey:PianoKey
    @Binding var clickNumber:Int
    let av = AudioSamplerPlayer.getShared()
    @State var isSheetPresented = false
    
    func getColor(_ key:PianoKey) -> Color {
        if key.wasPressed {
            return Color(.systemTeal)
        }
        else {
            return pianoKey.color == .white ? Color.white : Color.black
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
                        .offset(y: 90)
                        .opacity(pianoKey.color == .white ? 0.0 : 1.0)
                )

            VStack {
                Spacer()
                Text("\(pianoKey.midi)").foregroundColor(.red).bold().font(.title)
                if pianoKey.selected {
                    Text("**")
                }
                Text("")
                Text("")
            }
        }
        .onTapGesture {
            pianoKey.setSelected(way: true)
            //av.stopPlaying()
            av.play(note: UInt8(pianoKey.midi))
            if clickNumber == 0 {
                isSheetPresented = true
            }
            clickNumber += 1
            pianoKeys.setPressed(pressedKey: pianoKey)
        }
        .sheet(isPresented: $isSheetPresented) {
            HandView(isSheetPresented: $isSheetPresented)
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

struct KeyboardView: View {
    let hand:Int
    @ObservedObject var pianoKeys:PianoKeys
    @State var offset = 0.0
    let whiteKeyWidth = 60.0
    var blackKeyWidth = 0.0
    @State var clickNumber = 0
    @State var timer: AnyCancellable?
    @State var state:PlayState = .notStarted
    @State var timeRemaining = 5
    @State var isSheetPresented = false

    init(pianoKeys:PianoKeys, hand:Int) {
        self.pianoKeys = pianoKeys
        self.hand = hand
        blackKeyWidth = whiteKeyWidth * 0.7
    }
    
    func startTimer() {
        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timer?.cancel()
                    self.state = .notStarted
                    self.clickNumber = 0
                    pianoKeys.setPressed()
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
    
    func buttonsView() -> some View {
        HStack {
            Text("Right Hand").font(.title).padding()
            Button(action: {
                state = .started
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
                CircularProgressView(progress: CGFloat(timeRemaining) / 30.0, timeRemaining: timeRemaining)
                    .frame(width: 50, height: 50)
                    .padding(20)
            }
        }
    }
    
    var body: some View {
        VStack {
            buttonsView()
            ZStack(alignment: .topLeading) { // Aligning to the top and leading edge
                
                HStack(spacing: 0) {
                    ForEach(0..<pianoKeys.keys.count, id: \.self) { index in
                        if pianoKeys.keys[index].color == .white {
                            PianoKeyView(pianoKeys: pianoKeys,
                                         pianoKey: pianoKeys.keys[index],
                                         clickNumber: $clickNumber)
                            .frame(width: whiteKeyWidth, height: 300)
                        }
                    }
                }
                .border(Color.black, width: 1)
                
                HStack(spacing: 0) {
                    ForEach(0..<pianoKeys.keys.count, id: \.self) { index in
                        if pianoKeys.keys[index].color == .black {
                            PianoKeyView(pianoKeys: pianoKeys,
                                         pianoKey: pianoKeys.keys[index],
                                         clickNumber: $clickNumber)
                            .frame(width: blackKeyWidth, height: 200)
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
    }
}

enum PlayState {
    case notStarted
    case started
    case stopped
}

struct HandView:View {
    @Binding var isSheetPresented: Bool
    
    var body: some View {
        VStack {
            ZStack {
                Image("lh")
                    .resizable() // Make the image resizable
                    .scaledToFit() // Scale the image to fit its container
                    .frame(width: 500) // Set the desired width and height
                VStack {
                    HStack {
                        ForEach(0..<5) { index in
                            ZStack {
                                Rectangle()
                                    .fill(Color.blue)
                                    .opacity(0.3)
                                    .frame(width: 80, height: 40)
                                    .onTapGesture {
                                        isSheetPresented = false
                                    }

                                Text("\(5 - index)")
                            }
                        }
                    }
                    Spacer().frame(height: 500)
                }
            }
        }
    }
}

struct ScalesView: View {
    @ObservedObject var score:Score
    var pianoKeysLH = PianoKeys(midi: 36, number: 24)
    var pianoKeysRH = PianoKeys(midi: 60, number: 24)
    
    init(score:Score) {
        self.score = score
    }

    var body: some View {
        VStack {
            Text("Scale Trainer").font(.title).padding()
            
            SelectScaleView().padding()

            //ScoreView(score: score).padding()
            //MetronomeView(score: score, helpText: "", frameHeight: 100)
            ToolsView(score: score, helpMetronome: "")
            
            KeyboardView(pianoKeys: pianoKeysRH, hand: 0).padding()

            KeyboardView(pianoKeys: pianoKeysLH, hand: 1).padding()
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
