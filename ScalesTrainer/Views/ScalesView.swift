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
                                    selectedFinger = 4 - index
                                }

                            Text("\(5 - index)")
                        }
                    }
                }
                Image("lh")
                    .resizable() // Make the image resizable
                    .scaledToFit() // Scale the image to fit its container
                    .frame(height: frameHeight) // Set the desired width and height
                Text("Which finger ?").font(.title)
                //Spacer().frame(height: 500)
            }
        }
    }
}

struct KeyboardView: View {
    let hand:Int
    @ObservedObject var pianoKeys:PianoKeys
    var practiceMode:Bool
    @Binding var timeAllowed:Double
    @Binding var userMessage:String

    @State var timeRemaining:Double = 0.0
    @State var offset = 0.0
    
    let whiteKeyWidth = 60.0
    var blackKeyWidth = 0.0
    
    @State var clickNumber = 0
    @State var timer: AnyCancellable?
    
    @State var whiteKeyHeight = 200.0
    @State var lastGestureTime:Date? = nil
    @State var requiresFingerPrompt = false
    @State var selectedFinger:Int? = nil
    @State var lastPianoKeyPressed:PianoKey?
    @State var questionMode:QuestionMode = .notStarted

    let av = AudioSamplerPlayer.getShared()

    init(pianoKeys:PianoKeys, hand:Int, practiceMode:Bool, timeAllowed:Binding<Double>, userMessage:Binding<String>) {
        self.pianoKeys = pianoKeys
        self.hand = hand
        _userMessage = userMessage
        blackKeyWidth = whiteKeyWidth * 0.7
        _timeAllowed = timeAllowed
        self.practiceMode = practiceMode
    }
    
    func startTimer() {
        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timer?.cancel()
                    //self.state = .completed
                    self.clickNumber = 0
                    self.timeRemaining = timeAllowed
                    self.questionMode = .inAnswer
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
    
    func playScale() {
        DispatchQueue.global(qos: .background).async {
            var lastKey:PianoKey?
            for key in pianoKeys.keys {
                if key.inScale {
                //DispatchQueue.global(qos: .background).async {
                    //lastPianoKeyPressed = key
                    DispatchQueue.global(qos: .background).async {
                        av.play(note: UInt8(key.midi))
                    }
                    DispatchQueue.main.async {
                        if let lastKey = lastKey {
                            lastKey.wasLastKeyPressed = false
                        }
                        key.wasLastKeyPressed = true
                        lastKey = key
                    }
                    Thread.sleep(forTimeInterval: 0.5)
                }
            }
        }
    }
    
    func buttonsView() -> some View {
        HStack {
            Text(getName()).font(.title).padding()

            if !practiceMode {
                Button(action: {
                    //state = .started
                    pianoKeys.reset()
                    requiresFingerPrompt = false
                    selectedFinger = nil
                    //if questionMode == .inQuestion {
                    startTimer()
                    //}
                    questionMode = .inQuestion
                }) {
                    if questionMode == .notStarted {
                        Text("Start Scale").font(.title)
                    }
                }
                .padding()
            }
            
            if questionMode == .inQuestion {
                CircularProgressView(progress: CGFloat(self.timeRemaining) / 30.0, timeRemaining: Int(timeRemaining))
                    .frame(width: 50, height: 50)
                    .padding(20)
            }
            if questionMode == .inAnswer {
                Button(action: {
                    playScale()
                }) {
                    Text("Play Scale").font(.title)
                }
                .padding()
                Button(action: {
                    questionMode = .notStarted
                    pianoKeys.reset()
                }) {
                    Text("Try Again").font(.title)
                }
                .padding()
            }
        }
    }
    
    func requiresFingerNumber(pianoKey:PianoKey) -> Bool {
        if pianoKey.requiresFingerPrompt {
            ///Dont sound the note if user has already sounded it and given finger
            if pianoKey.userFinger == nil {
                return true
            }
        }
        return false
    }
    
    func soundNote(pianoKey:PianoKey, gesture: DragGesture.Value)  {
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
    }
    
    func processGesture(pianoKey:PianoKey, gesture:DragGesture.Value) {
        lastPianoKeyPressed = pianoKey
        requiresFingerPrompt = false
        selectedFinger = nil
        if questionMode == .inQuestion {
            if requiresFingerNumber(pianoKey: pianoKey) {
                if pianoKey.userFinger == nil {
                    //self.userMessage = "Which finger ?"
                    requiresFingerPrompt = true
                    return
                }
            }
        }

        soundNote(pianoKey: pianoKey, gesture: gesture)
    }
    
    func showInfo(_ pianoKey:PianoKey)  {
        var show = false
        if questionMode == .inAnswer {
            if pianoKey.inScale || pianoKey.wasPressed {
                show = true
            }
        }
        pianoKeys.setShowInfo(midi: pianoKey.midi, way: show)
    }
    
    var body: some View {
        VStack {
            buttonsView()
            ZStack(alignment: .topLeading) { // Aligning to the top and leading edge

                ///White notes
                HStack(spacing: 0) {
                    ForEach(0..<pianoKeys.keys.count, id: \.self) { index in
                        if pianoKeys.keys[index].color == .white {
                            PianoKeyView(id:index, pianoKey: pianoKeys.keys[index], questionMode: $questionMode)
                            .frame(width: whiteKeyWidth, height: whiteKeyHeight)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged(
                                        { gesture in
                                            processGesture(pianoKey: pianoKeys.keys[index], gesture: gesture)
                                            showInfo(pianoKeys.keys[index])
                                        }
                                    )
                                )
                        }
                    }
                }
                .border(Color.black, width: 1)

                ///Black notes
                HStack(spacing: 0) {
                    ForEach(0..<pianoKeys.keys.count, id: \.self) { index in
                        if pianoKeys.keys[index].color == .black {
                            PianoKeyView(id:index, pianoKey: pianoKeys.keys[index], questionMode: $questionMode)
                            .frame(width: blackKeyWidth, height: whiteKeyHeight * 0.60)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged(
                                        { gesture in
                                            processGesture(pianoKey: pianoKeys.keys[index], gesture: gesture)
                                            showInfo(pianoKeys.keys[index]) //{
                                                //pianoKeys.setShowInfo(midi: pianoKeys.keys[index].midi, way: true)
                                            //}
                                        }
                                    )
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
        .border(.blue)
        .onAppear() {
            self.timeRemaining = self.timeAllowed
            pianoKeys.reset()
            Settings.shared.useUpstrokeTaps = false
        }
        .onChange(of: selectedFinger) { finger in
            if let lastPianoKeyPressed = lastPianoKeyPressed {
                pianoKeys.setWasLastKeyPressed(pressedKey: lastPianoKeyPressed)
                av.play(note: UInt8(lastPianoKeyPressed.midi))
                if let finger = finger {
                    lastPianoKeyPressed.userFinger = finger
                    print("============Finger set", lastPianoKeyPressed.midi, finger)
                }
            }
            requiresFingerPrompt = false
            selectedFinger = nil
        }
        
        HandView(
            lastPianoKeyPressed: $lastPianoKeyPressed,
            selectedFinger: $selectedFinger,
            frameHeight: 50)
        .opacity(requiresFingerPrompt ? 1.0 : 0.0)
    }
}

enum PlayState {
    case notStarted
    case started
    case completed
}

enum QuestionMode {
    case notStarted
    case inQuestion
    case inAnswer
}

struct ScalesView: View {
    @ObservedObject var score:Score
    var pianoKeysLH = PianoKeys(midi: 36, number: 24)
    var pianoKeysRH = PianoKeys(midi: 60, number: 24)
    @State var timeAllowed:Double = 12.0
    @State var userMessage = ""
    @State var practiceMode = false

    init(score:Score) {
        self.score = score
    }

    var body: some View {
        VStack {
            Text("Scale Trainer").font(.title).padding()
            HStack {
                SelectScaleView().padding()
                Button(action: {
                    DispatchQueue.main.async {
                        practiceMode.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: practiceMode ? "checkmark.square" : "square")
                        Text("Practice Mode").font(.title)
                    }
                }
                .padding()
                HStack {
                    Text("Time Allowed \(Int(self.timeAllowed))").font(.title).padding()
                    Slider(value: $timeAllowed, in: 0...20, step: 1.0).padding()
                }
                .padding()
            }

            //ScoreView(score: score).padding()
            
            //ToolsView(score: score, helpMetronome: "")
                        
            KeyboardView(pianoKeys: pianoKeysRH, hand: 0, practiceMode: self.practiceMode, timeAllowed: $timeAllowed, userMessage: $userMessage).padding()

            KeyboardView(pianoKeys: pianoKeysLH, hand: 1, practiceMode: self.practiceMode, timeAllowed: $timeAllowed, userMessage: $userMessage).padding()
            
            Text(userMessage).opacity(self.userMessage.count == 0 ? 0.0 : 1.0).font(.title).padding()

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
    }
}
