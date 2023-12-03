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
    //@Binding var lastPianoKeyPressed1:PianoKey?
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
                Image("lefthand")
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
    let ascending:Bool
    @Binding var practiceMode:Bool
    let fingerMode:Bool
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
    @State var questionMode:QuestionMode = .notStarted
    @State var anyKeyPressed:Bool = false

    let av = AudioSamplerPlayer.getShared()

    init(pianoKeys:PianoKeys, hand:Int, ascending:Bool, practiceMode:Binding<Bool>, fingerMode:Bool, timeAllowed:Binding<Double>, userMessage:Binding<String>) {
        self.pianoKeys = pianoKeys
        self.hand = hand
        self.ascending = ascending
        _userMessage = userMessage
        blackKeyWidth = whiteKeyWidth * 0.7
        _timeAllowed = timeAllowed
        _practiceMode = practiceMode
        self.fingerMode = fingerMode
    }
    
    func startTimer() {
        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timer?.cancel()
                    self.clickNumber = 0
                    self.timeRemaining = timeAllowed
                    self.questionMode = .inAnswer
                    pianoKeys.gradeScale()
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
    
    func getName(ascending:Bool) -> String {
        var name = hand == 0 ? "Right Hand" : "Left Hand"
        name = name + (ascending ? " Ascending" : " Descending")
        return name
    }
    
    func playScale(ascending:Bool) {
        DispatchQueue.global(qos: .background).async {
            var lastKey:PianoKey?
            for i in 0..<pianoKeys.keys.count {
                let key = pianoKeys.keys[ascending ? i : pianoKeys.keys.count-i-1]
                if key.inScale {
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
    
    func startOver() {
        pianoKeys.reset()
        requiresFingerPrompt = false
        selectedFinger = nil
        if !practiceMode {
            startTimer()
            questionMode = .inQuestion
        }
    }
    
    func buttonsView() -> some View {
        HStack {
            Text(getName(ascending: ascending)).font(.title).padding()

            if practiceMode {
                if pianoKeys.wasAnyKeyPressed() {
                    Button(action: {
                        DispatchQueue.main.async {
                            startOver()
                        }
                    }) {
                        Text("Try Again").font(.title)
                    }
                    .padding()
                }
            }
            else {
                if self.questionMode == .inAnswer {
                    Button(action: {
                        DispatchQueue.main.async {
                            startOver()
                        }
                    }) {
                        Text("Try Again").font(.title)
                    }
                    .padding()
                }
            }
            
            if !practiceMode {
                Button(action: {
                    startOver()
                }) {
                    if questionMode == .notStarted {
                        Text("Start Scale").font(.title)
                    }
                }
                .padding()
                if questionMode == .inQuestion {
                    CircularProgressView(progress: CGFloat(self.timeRemaining) / 30.0, timeRemaining: Int(timeRemaining))
                        .frame(width: 50, height: 50)
                        .padding(20)
                }
            }
            
            if questionMode == .inAnswer {
                Button(action: {
                    playScale(ascending: ascending)
                }) {
                    Text("Play Scale").font(.title)
                }
                .padding()
                
//                Button(action: {
//                    questionMode = .notStarted
//                    pianoKeys.reset()
//                }) {
//                    Text("Try Again").font(.title)
//                }
//                .padding()
            }
        }
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
            //pianoKeys.setWasLastKeyPressed(pressedKey: pianoKey)
            //print("================ Tap", pianoKey.midi)
            av.play(note: UInt8(pianoKey.midi))
            clickNumber += 1
        }
    }
    
    func processGesture(pianoKey:PianoKey, gesture:DragGesture.Value, practiceMode:Bool) {
        if !practiceMode {
            if questionMode == .notStarted {
                return
            }
        }
        if practiceMode {
            pianoKeys.setWasLastKeyPressed(pressedKey: pianoKey)
        }
        else {
            if questionMode == .inQuestion {
                pianoKeys.setWasLastKeyPressed(pressedKey: pianoKey)
            }
        }
        requiresFingerPrompt = false
        selectedFinger = nil
        if questionMode == .inQuestion {
            if fingerMode {
                if pianoKey.requiresFingerPrompt {
                    if pianoKey.userFinger == nil {
                        requiresFingerPrompt = true
                        return
                    }
                }
            }
        }
        if practiceMode {
            pianoKey.grade()
        }
        soundNote(pianoKey: pianoKey, gesture: gesture)
    }
    
    func showInfo(_ pianoKey:PianoKey)  {
        var show = false
        if practiceMode {
            if let correct = pianoKey.isCorrect {
                if !correct {
                    show = true
                }
            }
        }
        else {
            if questionMode == .inAnswer {
                if pianoKey.inScale || pianoKey.wasPressed {
                    show = true
                }
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
                            PianoKeyView(id:index, pianoKey: pianoKeys.keys[index], questionMode: $questionMode, fingerMode: fingerMode)
                            .frame(width: whiteKeyWidth, height: whiteKeyHeight)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged(
                                        { gesture in
                                            DispatchQueue.main.async {
                                                processGesture(pianoKey: pianoKeys.keys[index], gesture: gesture, practiceMode: practiceMode)
                                                showInfo(pianoKeys.keys[index])
                                            }
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
                            PianoKeyView(id:index, pianoKey: pianoKeys.keys[index], questionMode: $questionMode, fingerMode: fingerMode)
                            .frame(width: blackKeyWidth, height: whiteKeyHeight * 0.60)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged(
                                        { gesture in
                                            DispatchQueue.main.async {
                                                processGesture(pianoKey: pianoKeys.keys[index], gesture: gesture, practiceMode: practiceMode)
                                                showInfo(pianoKeys.keys[index])
                                            }
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
            if practiceMode {
                questionMode = .inQuestion
            }
        }
        .onChange(of: practiceMode) { mode in
            self.questionMode = .notStarted
        }
        .onChange(of: timeAllowed) { mode in
            self.timeRemaining = timeAllowed
        }
        .onChange(of: selectedFinger) { finger in
            if finger == nil {
                return
            }
            if let lastPianoKeyPressed = pianoKeys.getLastKeyPressed() {
                lastPianoKeyPressed.userFinger = finger
                av.play(note: UInt8(lastPianoKeyPressed.midi))
                if practiceMode {
                    lastPianoKeyPressed.grade()
                    print("=============== Finger selected", "midi", lastPianoKeyPressed.midi, "correct", lastPianoKeyPressed.isCorrect ?? "NIL")

                    if let correct = lastPianoKeyPressed.isCorrect {
                        if !correct {
                            showInfo(lastPianoKeyPressed)
                        }
                    }
                }
            }
            requiresFingerPrompt = false
            selectedFinger = nil
        }
        
        HandView(
            //lastPianoKeyPressed: $lastPianoKeyPressed,
            selectedFinger: $selectedFinger,
            frameHeight: 50)
        .opacity(requiresFingerPrompt ? 1.0 : 0.0)
    }
}

//enum PlayState {
//    case notStarted
//    case started
//    case completed
//}

enum QuestionMode {
    case notStarted
    case inQuestion
    case inAnswer
}

struct ScalesView: View {
    @ObservedObject var score:Score

    @State var timeAllowed:Double = 0.0
    @State var userMessage = ""
    @State var practiceMode = true
    @State var fingerMode = false
    @State var ascending = false

    init(score:Score) {
        self.score = score
    }

    var body: some View {
        VStack {
            Text("Scale Trainer").font(.title).padding()
            HStack {
                SelectScaleView().padding()
                
                Button(action: {
                    ascending.toggle()
                }) {
                    HStack {
                        Image(systemName: ascending ? "arrow.up" : "arrow.down")
                            .resizable()
                            .foregroundColor(.green)
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 60)
                        Text("\(ascending ? "Ascending" : "Descending")").font(.title)
                    }
                }
                .padding()
                
                Button(action: {
                    practiceMode.toggle()
                    if !practiceMode {
                        timeAllowed = 10.0
                        if fingerMode {
                            timeAllowed += 5
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: practiceMode ? "checkmark.square" : "square")
                        Text("Practice Mode").font(.title)
                    }
                }
                .padding()
                
                Button(action: {
                    fingerMode.toggle()
                }) {
                    HStack {
                        Image("lefthand")
                            .resizable()
                            .foregroundColor(fingerMode ? .green : .gray)
                            .scaledToFit()
                            .frame(height: 60)
                            
                        Text("Check Fingers").font(.title).foregroundColor(fingerMode ? .green : .gray)
                    }
                }
                .padding()
            }
            
            if !practiceMode {
                HStack {
                    Text("     ").padding()
                    HStack {
                        Text("Time Allowed \(Int(self.timeAllowed))").font(.title)
                        Slider(value: $timeAllowed, in: 3...20, step: 1.0)
                    }
                    .padding()
                    Text("     ").padding()
                }
            }

            //ScoreView(score: score).padding()
            
            //ToolsView(score: score, helpMetronome: "")
                        
            KeyboardView(pianoKeys: PianoKeys(startMidi: 60, number: 24, ascending: ascending, fingerMode: fingerMode),
                         hand: 0,
                         ascending: ascending,
                         practiceMode: $practiceMode,
                         fingerMode: fingerMode,
                         timeAllowed: $timeAllowed,
                         userMessage: $userMessage)
            .padding()

            KeyboardView(pianoKeys: PianoKeys(startMidi: 36, number: 24, ascending: ascending, fingerMode: fingerMode),
                         hand: 1,
                         ascending: ascending,
                         practiceMode: $practiceMode,
                         fingerMode: fingerMode,
                         timeAllowed: $timeAllowed,
                         userMessage: $userMessage)
            .padding()
            
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
