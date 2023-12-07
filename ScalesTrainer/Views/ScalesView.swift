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

struct PressedActionView: View {
    @ObservedObject var model:ScalesAppModel
    @ObservedObject var piano:Piano
    var buttonTexts:[String]
    
    var imageSize = 25.0
    @State var fingerChoiceToBePresented = false
    
    init(model:ScalesAppModel, piano: Piano, buttonTexts:[String]) {
        self.model = model
        self.piano = piano
        self.buttonTexts = buttonTexts
    }
    
    func saveFinger(_ finger:Int) {
        fingerChoiceToBePresented = false
        piano.playNote(midi: piano.lastMidiPressed)
        model.setFingerForMidi(midi: piano.lastMidiPressed, finger: finger)
    }

    var body: some View {
        VStack {
        }
        .actionSheet(isPresented: $fingerChoiceToBePresented) {
            ActionSheet(
                title: Text("Choose an Option"),
                message: Text("Select an option from below"),
                buttons: [
                    .default(Text("\(buttonTexts[0])")) {saveFinger(0) },
                    .default(Text("\(buttonTexts[1])")) {saveFinger(1) },
                    .default(Text("\(buttonTexts[2])")) {saveFinger(2) },
                    .default(Text("\(buttonTexts[3])")) {saveFinger(3) },
                    .default(Text("\(buttonTexts[4])")) {saveFinger(4) },
                    //.destructive(Text("Delete")) {test()  },
                    .cancel() {  }
                ]
            )
        }
        .onChange(of: piano.lastMidiPressed, perform: {newValue in
            let keyPresses = model.keyPressesForMidi[piano.lastMidiPressed]
            model.addKeyPressedForMidi(midi: piano.lastMidiPressed)
            if keyPresses == 0 {
                if model.checkFingerNumbers {
                    if model.scale.getRequiredFinger(midi: piano.lastMidiPressed) != nil {
                        fingerChoiceToBePresented = true
                    }
                }
                if !fingerChoiceToBePresented {
                    piano.playNote(midi: piano.lastMidiPressed)
                }
            }
        })
    }
}

struct NoteExplanationView: View {
    let key:PianoKey
    var body: some View {
        VStack {
            Text("EX::\(key.midi)")
        }
    }
}

struct ScaleNoteView: View {
    @ObservedObject var model:ScalesAppModel
    @ObservedObject var key:PianoKey
    @State private var isHovering = false
    let imageSize = 26.0
    @State var showExplanation = false
    
    enum ShowState {
        case noShow
        case inScale
        case outOfScale
        case missing
        case wrongFinger
    }
    
    func showNote() -> ShowState {
        let noteInScale = model.scale.isMidiInScale(midi: key.midi)
        if model.questionMode == .notStarted {
            if key.wasPressed  {
                if noteInScale {
                    if model.checkFingerNumbers {
                        if let finger = model.fingerUsedByMidi[key.midi] {
                            print("==========GOTFINGER", finger)
                            if finger != model.scale.getRequiredFinger(midi: key.midi) {
                                return ShowState.wrongFinger
                            }
                        }
                    }
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
                    if let finger = model.fingerUsedByMidi[key.midi] {
                        if finger != model.scale.getRequiredFinger(midi: key.midi) {
                            return ShowState.wrongFinger
                        }
                    }
                    return ShowState.inScale
                }
                else {
                    return ShowState.outOfScale
                }
            }
            else {
                if key.midi < model.scale.startMidi || key.midi > (model.scale.startMidi + model.scale.noteCount) {
                    return ShowState.noShow
                }
                if noteInScale {
                    return .missing
                }
            }
        }
        return ShowState.noShow
    }
    
    var body: some View {
        let show = showNote()
        let padding = key.color == .white ? 80.0 : 0.0
        ZStack {
            ///Any changes here - make sure centered alignment of kb is not wrecked
            if show == .inScale  {
                Image(systemName: "checkmark").resizable().frame(width: imageSize, height: imageSize)
                    .foregroundColor(.green).bold().padding(.top, padding)
            }
            if show == .outOfScale {
                Image("wrong1").resizable().frame(width: imageSize, height: imageSize)
                    .foregroundColor(.red).bold().padding(.top, padding)
            }
            if show == .missing {
                Image(systemName: "scribble.variable").resizable().frame(width: imageSize, height: imageSize)
                    .foregroundColor(.red).bold().padding(.top, padding)
            }
            if show == .wrongFinger {
                Image(systemName: "hand.point.up.left.fill").resizable().frame(width: imageSize, height: imageSize)
                    .foregroundColor(.red).bold().padding(.top, padding)
            }
            //if model.keyPressesForMidi[key.midi] > 1 {
                if [ShowState.missing, ShowState.outOfScale, ShowState.wrongFinger].contains(show) {
                    Button(action: {
                        self.showExplanation = true
                    }) {
                        Image(systemName: "questionmark.circle").resizable().frame(width: imageSize * 1.5, height: imageSize * 1.5)
                            .foregroundColor(.green).bold().padding(.top, 2 * padding)
                    }
                    .popover(isPresented: $showExplanation) {
                        NoteExplanationView(key: key)
                            .padding()
                    }
                }
            //}
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
    
    //@State var chooseFingerAction:ChooseFinger?
    
    init() {
        model = ScalesAppModel.shared
    }

    func getKeyDisplayView(key:PianoKey) -> some View {
        ScaleNoteView(model: model, key: key)
    }
    
    func getFingerTexts() -> [String]{
        var buttonTexts:[String] = []
        buttonTexts.append("Thumb")
        buttonTexts.append("2nd Finger")
        buttonTexts.append("3rd Finger")
        buttonTexts.append("4th Finger")
        buttonTexts.append("5th Finger")
        if !rightHand {
            buttonTexts = buttonTexts.reversed()
        }
        return buttonTexts
    }
    
    func getActionView(piano:Piano) -> some View {
        PressedActionView(model: model, piano: piano, buttonTexts: getFingerTexts())
    }

    func topLineView() -> some View {
        HStack {
            SelectScaleView().padding()
            
            Button(action: {
                rightHand.toggle()
                model.piano = rightHand ? Piano(startMidi: 65, number: 30) : Piano(startMidi: 36, number: model.totalKeys)
                //setChooseFinger()
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
                timeAllowed = 20.0
                if fingerMode {
                    timeAllowed += 10.0
                }
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
                model.checkFingerNumbers = fingerMode
                model.reset()
                model.piano.reset()
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
        model.piano.reset()
        self.model.setQuestionMode(way: .inQuestion)
    }

    func timerEndNotification() {
        model.piano.clearLastPressed()
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
                    model.piano.playScale(scale: model.scale, ascending: ascending)
                }) {
                    Text("Play Scale").font(.title)
                }
                .padding()
            }
        }
    }
    
//    func setChooseFinger() {
//        chooseFingerAction = ChooseFinger(model: model, piano: piano)
//        //chooseFingerAction?.model.scale = model.scale
//        var buttonTexts:[String] = []
//        buttonTexts.append("Thumb")
//        buttonTexts.append("2nd Finger")
//        buttonTexts.append("3rd Finger")
//        buttonTexts.append("4th Finger")
//        buttonTexts.append("5th Finger")
//        if !rightHand {
//            buttonTexts = buttonTexts.reversed()
//        }
//        //print("============= SET CHOOSE _FINGER ")
//        chooseFingerAction?.buttonTexts = buttonTexts
//    }
    
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
            
            PianoView<ScalesView>(piano: model.piano).padding()
            
            //.border(Color .red)
        
        }
        .onAppear() {
            //setChooseFinger()
//            pianoView = PianoView(piano: piano,
//                      keyDisplayView: InsideKeyView(key: PianoKey(midi: 0), timedMode1: timedMode),
//                      action: chooseFingerAction)

        }
    }
}

