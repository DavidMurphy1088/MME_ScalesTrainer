import Foundation
import SwiftUI
import CommonLibrary
import Combine

struct KeyboardView: View {
    @ObservedObject var piano:Piano
    let keyDisplayView: any KeyDisplayViewType
    
    //@Binding var rightHand:Bool
    //let ascending:Bool
    //@Binding var timedMode:Bool
    //let fingerMode:Bool
    //@Binding var timeAllowed:Double
    //@Binding var userMessage:String

    //@State var timeRemaining:Double = 0.0
    //@State var offset = 0.0
    
    @State var whiteKeyWidth = 1.0
    @State var blackKeyWidth = 0.0
    
    @State var clickNumber = 0
    //@State var timer: AnyCancellable?
    
    @State var whiteKeyHeight = 0.0
    //@State var requiresFingerPrompt = false
    //@State var selectedFinger:Int? = nil
    //@State var questionMode:QuestionMode = .notStarted
    @State var anyKeyPressed:Bool = false
    @State var handViewHeight = 0.0


//    init(piano:Piano, rightHand:Binding<Bool>, ascending:Bool, timedMode:Binding<Bool>, fingerMode:Bool, timeAllowed:Binding<Double>, userMessage:Binding<String>) {
    init(piano:Piano, keyDisplayView: any KeyDisplayViewType) {
        self.piano = piano
        self.keyDisplayView = keyDisplayView
        
//        _rightHand = rightHand
//        self.ascending = ascending
//        _userMessage = userMessage
        
//        _timeAllowed = timeAllowed
//        _timedMode = timedMode
//        self.fingerMode = fingerMode
    }
    
//    func startTimer() {
//        self.timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
//            .sink { _ in
//                if self.timeRemaining > 0 {
//                    self.timeRemaining -= 1
//                } else {
//                    self.timer?.cancel()
//                    self.clickNumber = 0
//                    self.timeRemaining = timeAllowed
//                    self.questionMode = .inAnswer
//                    pianoKeys.gradeScale()
//                }
//            }
//    }
    
    func getBlackSpacing(index:Int) -> CGFloat {
        if index >= piano.keys.count-1 {
            return 0
        }
        if piano.keys[index].color == .white && piano.keys[index+1].color == .white {
            return whiteKeyWidth
        }
        return 0.0
    }
    
    func getName(ascending:Bool) -> String {
        var name = "piano" //rightHand ? "Right Hand" : "Left Hand"
        //name = name + (ascending ? " Ascending" : " Descending")
        return name
    }

//    func startOver() {
//        pianoKeys.reset()
//        requiresFingerPrompt = false
//        selectedFinger = nil
//        if timedMode {
//            //startTimer()
//            questionMode = .inQuestion
//        }
//    }
    
    func buttonsView() -> some View {
        HStack {
//            Text(getName(ascending: ascending)).font(.title).padding()

//            if !timedMode {
//                //if pianoKeys.wasAnyKeyPressed() {
//                    Button(action: {
//                        DispatchQueue.main.async {
//                            startOver()
//                        }
//                    }) {
//                        Text("Clear").font(.title)
//                    }
//                    .padding()
//                //}
//            }
//            else {
//                if self.questionMode == .inAnswer {
//                    Button(action: {
//                        DispatchQueue.main.async {
//                            startOver()
//                        }
//                    }) {
//                        Text("Try Again").font(.title)
//                    }
//                    .padding()
//                }
//            }
//
//            if timedMode {
//                Button(action: {
//                    startOver()
//                }) {
//                    if questionMode == .notStarted {
//                        Text("Start Scale").font(.title)
//                    }
//                }
//                .padding()
//                if questionMode == .inQuestion {
//                    CircularProgressView(progress: CGFloat(self.timeRemaining) / 30.0, timeRemaining: Int(timeRemaining))
//                        .frame(width: 50, height: 50)
//                        .padding(20)
//                }
//            }
            

        }
    }
    
    func processGesture(pianoKey:PianoKey, gesture:DragGesture.Value) { //}, timedMode:Bool) {
//        if timedMode {
//            if questionMode == .notStarted {
//                return
//            }
//        }
//        if !timedMode {
//            pianoKeys.setWasLastKeyPressed(pressedKey: pianoKey)
//        }
//        else {
//            if questionMode == .inQuestion {
//                pianoKeys.setWasLastKeyPressed(pressedKey: pianoKey)
//            }
//        }
//        requiresFingerPrompt = false
//        selectedFinger = nil
//        if questionMode == .inQuestion {
//            if fingerMode {
//                if pianoKey.requiresFingerPrompt {
//                    if pianoKey.userFinger == nil {
//                        requiresFingerPrompt = true
//                        return
//                    }
//                }
//            }
//        }
//        if !timedMode {
//            pianoKey.grade()
//        }
        piano.processGesture(key:pianoKey, gesture: gesture)
    }
    
    func showInfo(_ pianoKey:PianoKey)  {
        var show = false
//        if timedMode {
//            if questionMode == .inAnswer {
//                if pianoKey.inScale || pianoKey.wasPressed {
//                    show = true
//                }
//            }
//        }
//        else {
//            if let noteCorrect = pianoKey.noteIsCorrect {
//                if !noteCorrect {
//                    show = true
//                }
//            }
//            if fingerMode {
//                if let fingerIsCorrect = pianoKey.fingerIsCorrect {
//                    if !fingerIsCorrect {
//                        show = true
//                    }
//                }
//            }
//        }

        piano.setShowInfo(midi: pianoKey.midi, way: show)
    }
    
    var body: some View {
        VStack {
            buttonsView()
            ZStack(alignment: .topLeading) { // Aligning to the top and leading edge

                ///White notes
                HStack(spacing: 0) {
                    ForEach(0..<piano.keys.count, id: \.self) { index in
                        if piano.keys[index].color == .white {
                            PianoKeyView(id:index, pianoKey: piano.keys[index],
                                         keyDisplayView: keyDisplayView) //, questionMode: $questionMode, fingerMode: fingerMode)
                            .frame(width: whiteKeyWidth, height: whiteKeyHeight)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged(
                                        { gesture in
                                            DispatchQueue.main.async {
                                                processGesture(pianoKey: piano.keys[index], gesture: gesture) //, timedMode: timedMode)
                                                showInfo(piano.keys[index])
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
                    ForEach(0..<piano.keys.count, id: \.self) { index in
                        if piano.keys[index].color == .black {
                            PianoKeyView(id:index, pianoKey: piano.keys[index],
                                         keyDisplayView: keyDisplayView) //, questionMode: $questionMode, fingerMode: fingerMode)
                            .frame(width: blackKeyWidth, height: whiteKeyHeight * 0.60)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged(
                                        { gesture in
                                            DispatchQueue.main.async {
                                                processGesture(pianoKey: piano.keys[index], gesture: gesture) //, timedMode: timedMode)
                                                showInfo(piano.keys[index])
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
            let screenSize = UIScreen.main.bounds
            let screenWidth = screenSize.width
            ///Some keys (black) are narrower
            self.whiteKeyWidth = (screenWidth * 1.6) / Double(piano.keys.count)
            self.whiteKeyHeight = screenSize.height / 5.0
            self.handViewHeight = self.whiteKeyHeight * 0.20
            
            blackKeyWidth = whiteKeyWidth * 0.7
            //self.timeRemaining = self.timeAllowed
            //pianoKeys.reset()
            Settings.shared.useUpstrokeTaps = false
//            if !timedMode {
//                questionMode = .inQuestion
//            }
        }
//        .onChange(of: timedMode) { mode in
//            self.questionMode = .notStarted
//        }
//        .onChange(of: timeAllowed) { mode in
//            self.timeRemaining = timeAllowed
//        }
//        .onChange(of: selectedFinger) { finger in
//            if finger == nil {
//                return
//            }
//            if let lastPianoKeyPressed = pianoKeys.getLastKeyPressed() {
//                lastPianoKeyPressed.userFinger = finger
//                av.play(note: UInt8(lastPianoKeyPressed.midi))
//                if !timedMode {
//                    lastPianoKeyPressed.grade()
//                    if let noteIsCorrect = lastPianoKeyPressed.noteIsCorrect {
//                        if !noteIsCorrect {
//                            showInfo(lastPianoKeyPressed)
//                        }
//                        else {
//                            if let fingerIsCorrect = lastPianoKeyPressed.fingerIsCorrect {
//                                if !fingerIsCorrect {
//                                    showInfo(lastPianoKeyPressed)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//            requiresFingerPrompt = false
//            selectedFinger = nil
//        }
        
//        HandView(
//            selectedFinger: $selectedFinger,
//            boxHeight: self.handViewHeight)
//        .opacity(requiresFingerPrompt ? 1.0 : 0.0)
//        //.opacity(requiresFingerPrompt ? 1.0 : 1.0)
    }
        
}

struct PianoView<Content>: View where Content: KeyDisplayViewType {
//struct PianoView: View {
    @ObservedObject var piano:Piano
    let keyDisplayView: Content
    
    var body: some View {
        VStack {
//            KeyboardView(pianoKeys: Piano(rightHand:rightHand, startMidi: rightHand ? 60 : 36, number: 36, ascending: ascending),
//                         rightHand: $rightHand,
//                         ascending: ascending,
//                         timedMode: $timedMode,
//                         fingerMode: fingerMode,
//                         timeAllowed: $timeAllowed,
//                         userMessage: $userMessage)
            KeyboardView(piano:piano, keyDisplayView: keyDisplayView)
            keyDisplayView
        }
    }
}
