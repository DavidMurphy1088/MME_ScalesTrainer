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

struct KeyActionView: KeyDownAction {
    //let keyString: String
    @ObservedObject var key:PianoKey
    var imageSize = 25.0
    @State var scale = Scale(name: "A\u{266D} Harmonic Minor")
    
    init(key:PianoKey) {
        //self.keyString = keyString
        self.key = key
    }
    
    var body: some View {
        VStack {
            Text("XV")
        }
    }
}

struct ChooseFinger: Action {
    @ObservedObject var piano:Piano
    var imageSize = 25.0
    @State var isPresented = false
    var scale:Scale? = nil
    var buttonTexts:[String] = []
    
    init(piano: Piano) {
        self.piano = piano
    }
    
    func test() {
        isPresented = false
        piano.playNote(midi: piano.lastKeyPressed)
    }

    var body: some View {
        VStack {
            Text("AAAA")
            
        }
        .actionSheet(isPresented: $isPresented) {
            ActionSheet(
                title: Text("Choose an Option"),
                message: Text("Select an option from below"),
                buttons: [
                    .default(Text("\(buttonTexts[0])")) {test() },
                    .default(Text("\(buttonTexts[1])")) {test() },
                    .default(Text("\(buttonTexts[2])")) {test() },
                    .default(Text("\(buttonTexts[3])")) {test() },
                    .default(Text("\(buttonTexts[4])")) {test() },
                    //.destructive(Text("Delete")) {test()  },
                    .cancel() {test()  }
                ]
            )
        }
        .onChange(of: piano.lastKeyPressed, perform: {newValue in
            if let scale = scale {
                let finger = scale.getRequiredFinger(midi: piano.lastKeyPressed)
                if let finger = finger {
                    isPresented = true
                }
                else {
                    piano.playNote(midi: piano.lastKeyPressed)
                }
                print("====================== CHOOSE", piano.lastKeyPressed, "InScale", scale.isMidiInScale(midi: piano.lastKeyPressed), newValue)
            }
            else {
                piano.playNote(midi: piano.lastKeyPressed)
            }
        })
    }
}

//struct ScalesKeyDisplayView: InsideKeyViewType {
//    let id = UUID()
//    @ObservedObject var key:PianoKey
//    var imageSize = 25.0
//    @State var scale = Scale(name: "A\u{266D} Harmonic Minor")
//
//    init(key: PianoKey) {
//        self.key = key
//    }
//
//    var body: some View {
//        Spacer()
//        let noteInScale = scale.isMidiInScale(midi: key.midi)
//
//        if key.wasPressed  {
//            VStack {
////                    if noteInScale  {
////                        Image(systemName: "checkmark").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.green).bold()
////                    }
////                    else {
////                        if true {
////                            Image(systemName: "questionmark").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red).bold()
////                        }
////                        else {
////                            Image(systemName: "scribble.variable").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red).bold()
////                        }
////                    }
//                }
//                //else {
//                    //                    if showFingers() {
//                    //                        if fingersCorrect() {
//                    //                            Image(systemName: "checkmark").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.green).bold()
//                    //                        }
//                    //                        else {
//                    //                            //Image("lefthand").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red).bold()
//                    //                            Image(systemName: "hand.raised.fill").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red).bold()
//                    //                        }
//                    //                    }
//                    //                    else {
//                    //                        Image(systemName: "checkmark").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.green).bold()
//                    //                    }
//                //}
//            //.padding(.bottom, 30)
//        }
//    }
//}

struct ScaleNoteView: View {
    @ObservedObject var model:ScalesAppModel
    @ObservedObject var key:PianoKey
    let imageSize = 26.0

    enum ShowState {
        case noShow
        case inScale
        case outOfScale
        case missing
    }
    
    func showNote() -> ShowState {
        //print("===========LOG", model.timedMode)
        let noteInScale = model.scale.isMidiInScale(midi: key.midi)
        if model.questionMode == .notStarted {
            if key.wasPressed  {
                if noteInScale {
                    return ShowState.inScale
                }
                else {
                    return ShowState.outOfScale
                }
            }
            else {
                return ShowState.noShow
            }
        }
        if model.questionMode == .inQuestion {
            return ShowState.noShow
        }
        if model.questionMode == .inAnswer {
            if key.wasPressed  {
                if noteInScale {
                    return ShowState.inScale
                }
                else {
                    return ShowState.outOfScale
                }
            }
            else {
                if noteInScale {
                    return .missing
                }
            }
        }
        return ShowState.noShow
    }
    
    var body: some View {
        let show = showNote()
        VStack {
            if key.color == .white {
                Text("").padding().padding().padding()
            }
            if show == .inScale  {
                Image(systemName: "checkmark").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.green).bold()
            }
            if show == .outOfScale {
                Image(systemName: "questionmark").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red).bold()
            }
            if show == .missing {
                Image(systemName: "scribble.variable").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red).bold()
            }
        }
    }
}

struct ScalesView: PianoUserProtocol, View {
    @ObservedObject var model:ScalesAppModel
    @State var timeAllowed:Double = 0.0
    @State var userMessage = ""
    @State var fingerMode = false
    @State var ascending = true
    @State var rightHand = true
    let checkSize = 30.0
    
    @State var piano = Piano(startMidi: 65, number: 30)
    @State var chooseFingerAction:ChooseFinger?
    
    init() {
        model = ScalesAppModel.shared
    }

    func getKeyDisplayView(key:PianoKey) -> some View {
        ScaleNoteView(model: model, key: key)
    }
    
    func topLineView() -> some View {
        HStack {
            SelectScaleView().padding()
            
            Button(action: {
                rightHand.toggle()
                piano = rightHand ? Piano(startMidi: 65, number: 30) : Piano(startMidi: 36, number: 30)
                setChooseFinger()
            }) {
                HStack {
                    Image(systemName: rightHand ? "checkmark.square" : "square").resizable().frame(width: checkSize, height: checkSize)
                    //Text("\(leftHand ? "Left " : "Right")").font(.title)
                    Text("Right\nHand").font(.title)
                }
            }
            .padding()

            Button(action: {
                ascending.toggle()
            }) {
                HStack {
//                        Image(systemName: ascending ? "arrow.up" : "arrow.down")
//                            .resizable()
//                            .foregroundColor(.green)
//                            .aspectRatio(contentMode: .fit)
//                            .frame(height: 40)
                    Image(systemName: ascending ? "checkmark.square" : "square").resizable().frame(width: checkSize, height: checkSize)
                    //Text("\(ascending ? "Ascending " : "Descending")").font(.title)
                    Text("Ascending").font(.title)
                }
            }
            .padding()
            
            Button(action: {
                model.setTimedMode(way: !model.timedMode)
                model.setQuestionMode(way: .inQuestion)
//                if model.timedMode {
//
//                    model.setQuestionMode(way: .inQuestion)
                    timeAllowed = 5.0
                    if fingerMode {
                        timeAllowed += 5
                    }
//                }
//                else {
//                    model.questionMode = .notStarted
//                }
            }) {
                HStack {
                    Image(systemName: model.timedMode ? "checkmark.square" : "square").resizable().frame(width: checkSize, height: checkSize)
                    Text("Timed Mode").font(.title)
                }
            }
            .padding()
            .onAppear() {
                //keyDisplayView.timedMode = timedMode
            }
            
            Button(action: {
                fingerMode.toggle()
            }) {
                HStack {
                    Image(systemName: fingerMode ? "checkmark.square" : "square").resizable().frame(width: checkSize, height: checkSize)
                    Text("Check Fingering").font(.title)//.foregroundColor(fingerMode ? .green : .gray)
                }
            }
            .padding()
        }
    }
    
    func timerStartNotification() {
        piano.reset()
        self.model.setQuestionMode(way: .inQuestion)
    }

    func timerEndNotification() {
        self.model.setQuestionMode(way: .inAnswer)
    }
    
    func commandsView() -> some View {
        HStack {
            if model.timedMode {
//                Button(action: {
//                    model.questionMode = QuestionMode.inQuestion
//                }) {
//                    Text("Start Scale").font(.title)
//                }
//                .padding()
                if model.timedMode {
                    CountdownTimerView(size: 50, timerColor: Color.green, timeLimit: $timeAllowed,
                                       startNotification: timerStartNotification,
                                       endNotification: timerEndNotification).padding()
                }
            }
            else {
                Button(action: {
                    piano.playScale(scale: model.scale, ascending: ascending)
                }) {
                    Text("Play Scale").font(.title)
                }
                .padding()
            }
        }
    }
    
    func setChooseFinger() {
        chooseFingerAction = ChooseFinger(piano: piano)
        chooseFingerAction?.scale = model.scale
        var buttonTexts:[String] = []
        buttonTexts.append("Thumb")
        buttonTexts.append("2nd Finger")
        buttonTexts.append("3rd Finger")
        buttonTexts.append("4th Finger")
        buttonTexts.append("5th Finger")
        if !rightHand {
            buttonTexts = buttonTexts.reversed()
        }
        //print("============= SET CHOOSE _FINGER ")
        chooseFingerAction?.buttonTexts = buttonTexts
    }
    
    var body: some View {
        VStack {
            Text("Scale Trainer").font(.title).padding()
            
            topLineView()
            
            commandsView()

            if model.timedMode {
                HStack {
                    Text("     ").padding()
                    HStack {
                        Text("Time allowed is \(Int(self.timeAllowed)) seconds ").font(.title)
                        Slider(value: $timeAllowed, in: 5...40, step: 1.0)
                    }
                    .padding()
                    Text("     ").padding()
                }
            }
            
            PianoView<ScalesView>(piano: piano).padding()
            
            //.border(Color .red)
        
        }
        .onAppear() {
            setChooseFinger()
//            pianoView = PianoView(piano: piano,
//                      keyDisplayView: InsideKeyView(key: PianoKey(midi: 0), timedMode1: timedMode),
//                      action: chooseFingerAction)

        }
    }
}

