import Foundation
import SwiftUI
import CommonLibrary
import Combine

protocol KeyDownAction: View {
    init(key:PianoKey)
}

protocol Action: View {
    init(piano:Piano)
}

struct KeyboardView<InsideKeyView, ActionView>: View where InsideKeyView: InsideKeyViewType, ActionView:Action {
    
    @ObservedObject var piano:Piano
    let keyDisplayView: InsideKeyView
    let action:ActionView

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
    @State var showingSheet = false
    @State var currentMidi = 0

    init(piano:Piano, keyDisplayView: InsideKeyView, action: ActionView) {
        self.piano = piano
        self.keyDisplayView = keyDisplayView
        self.action = action
        
        //self.keyDownAction = keyDownAction
        
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

    func buttonsView() -> some View {
        HStack {
        }
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
                            PianoKeyView(id:index, piano: piano,
                                         pianoKey: piano.keys[index],
                                         insideKeyView: InsideKeyView(keyString: "", key: piano.keys[index]))
                            .frame(width: whiteKeyWidth, height: whiteKeyHeight)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged(
                                        { gesture in
                                            currentMidi = piano.keys[index].midi
                                            showingSheet.toggle()
                                            piano.processGesture(key:piano.keys[index], gesture: gesture)
                                            showInfo(piano.keys[index])
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
                            PianoKeyView(id:index,
                                         piano: piano,
                                         pianoKey: piano.keys[index],
                                         insideKeyView: InsideKeyView(keyString: "", key: piano.keys[index]))
                            .frame(width: blackKeyWidth, height: whiteKeyHeight * 0.60)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged(
                                        { gesture in
                                            //processGesture(pianoKey: piano.keys[index], gesture: gesture) //, timedMode: timedMode)
                                            piano.processGesture(key:piano.keys[index], gesture: gesture)
                                            showInfo(piano.keys[index])
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
                action
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

struct PianoView<InsideKeyView, ActionView>: View where InsideKeyView: InsideKeyViewType, ActionView:Action {
    @ObservedObject var piano:Piano
    let keyDisplayView: InsideKeyView
    let action:ActionView
    
    var body: some View {
        VStack {
            KeyboardView(piano:piano, keyDisplayView: keyDisplayView, action: action)
        }
    }
}
