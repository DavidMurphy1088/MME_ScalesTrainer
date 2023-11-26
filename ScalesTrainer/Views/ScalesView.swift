import SwiftUI
import CommonLibrary
import Combine

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
                            PianoKeyView(id:index, pianoKey: pianoKeys.keys[index], cornerRadius: 0)
                            .frame(width: whiteKeyWidth, height: whiteKeyHeight)
                            //.foregroundColor(getColor(pianoKeys.keys[index]))
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
                            PianoKeyView(id:index, pianoKey: pianoKeys.keys[index],
                                         cornerRadius: 8)
                            .frame(width: blackKeyWidth, height: whiteKeyHeight * 0.60)
                            //.foregroundColor(getColor(pianoKeys.keys[index]))
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
