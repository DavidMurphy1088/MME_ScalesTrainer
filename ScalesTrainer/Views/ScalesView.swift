import SwiftUI
import CommonLibrary
import Combine

struct NoteExplanationView: View {
    var model:ScalesAppModel
    let key:PianoKey
    var body: some View {
        VStack {
            let status = model.getNoteStatus(key: key)
            if status == .outOfScale {
                Text("This note you played is not the scale of \(model.getScaleName())")
            }
            if status == .missing {
                Text("You didn't play this note but it is required in the scale of \(model.getScaleName())")
            }
            if status == .wrongFinger {
                if let requiredFinger = model.scale.getRequiredFinger(midi: key.midi) {
                    let name = model.scale.getFingerName(finger: requiredFinger)
                    Text("This note should be played with the \(name)").font(.title2)
                    if let userFinger = model.getUsersFingerForMidi(midi: key.midi) {
                        let name = model.scale.getFingerName(finger: userFinger)
                        Text("You played it with your \(name)").font(.title2)
                    }
                }
            }
        }
        //.background(Color .teal)
        .padding()
        .padding()
        .border(Color .black)
    }
}

struct AfterPressedView: View {
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
        model.setUsersFingerForMidi(midi: piano.lastMidiPressed, finger: finger)
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
            if model.questionMode != .inAnswer {
                let keyPresses = model.keyPressesForMidi[piano.lastMidiPressed]
                model.addKeyPressedForMidi(midi: piano.lastMidiPressed)
                if keyPresses == 0 {
                    if model.checkFingerNumbers {
                        if model.scale.getRequiredFinger(midi: piano.lastMidiPressed) != nil {
                            if model.getUsersFingerForMidi(midi: piano.lastMidiPressed) == nil {
                                fingerChoiceToBePresented = true
                            }
                        }
                    }
                }
                if !fingerChoiceToBePresented {
                    piano.playNote(midi: piano.lastMidiPressed)
                }
            }
        })
    }
}

struct ScaleNoteView: View {
    @ObservedObject var model:ScalesAppModel
    @ObservedObject var key:PianoKey
    @State private var isHovering = false
    let imageSize = 30.0
    @State var showExplanation = false

    func getFinger() -> String {
        var fingerStr = ""
        let finger = model.scale.getFinger(midi: key.midi)
        if let finger = finger {
            fingerStr = String(finger+1)
        }
        return fingerStr
    }
    
    var body: some View {
        ///For each key state show the right button and image
        ///The explanation popover must be attached to t each button to hace the popover appear next to the key
        ///On any layout changes here - make sure centered alignment of kb is not wrecked
        let show = model.getNoteStatus(key: key)
        let padding = 0.0
        
        ///Must to ZStack to ensure all note view status images are horizontally aligned irrespective of presence of finger data
        ZStack {
            if model.questionMode != .inQuestion {
                //let l = log()
                VStack {
                    //Text("\(key.midi)").padding().padding()
                    Text("\(getFinger())").padding().font(.title).foregroundColor(key.color == .white ? Color.black : Color.white)
                }
            }
            //.border(.red)
            VStack {
                if show == .inScale  {
                    Image(systemName: "checkmark").resizable().frame(width: imageSize, height: imageSize)
                        .foregroundColor(.green).bold().padding(.top, padding)
                }
                if show == .outOfScale {
                    Button(action: {
                        self.showExplanation = true
                    }) {
                        Image("wrong").resizable().frame(width: imageSize * 1.1, height: imageSize * 1.1)
                            .foregroundColor(.red).bold().padding(.top, padding)
                    }
                    .popover(isPresented: $showExplanation) {
                        NoteExplanationView(model: model, key: key)
                            .padding()
                    }
                }
                if show == .missing {
                    Button(action: {
                        self.showExplanation = true
                    }) {
                        Image(systemName: "eyedropper").resizable().frame(width: imageSize, height: imageSize)
                            .foregroundColor(.red).bold().padding(.top, padding)
                    }
                    .popover(isPresented: $showExplanation) {
                        NoteExplanationView(model: model, key: key)
                            .padding()
                    }
                }
                if show == .wrongFinger {
                    Button(action: {
                        self.showExplanation = true
                    }) {
                        Image(systemName: "hand.point.up.left.fill").resizable().frame(width: imageSize * 1.2, height: imageSize * 1.2)
                            .foregroundColor(.red).bold().padding(.top, padding)
                    }
                    .popover(isPresented: $showExplanation) {
                        NoteExplanationView(model: model, key: key)
                            .padding()
                    }
                }
            }
        }
        //.border(.green)
    }
}

struct ScalesView: PianoUserProtocol, View {
    @ObservedObject var model:ScalesAppModel
    @State var showSelectScale:Bool
    @State var metronome:Metronome
    @State var timeAllowed:Double = 0.0
    @State var userMessage = ""
    @State var fingerMode = false
    @State var ascending = true
    @State var rightHand = true
    let checkSize = 30.0
    let imageSize = 80.0

    init() {
        model = ScalesAppModel.shared
        self.showSelectScale = false
        metronome = Metronome.getMetronomeWithSettings(initialTempo: 60, allowChangeTempo: true, ctx: "")

    }

    init(showSelectScale:Bool) {
        model = ScalesAppModel.shared
        self.showSelectScale = showSelectScale
        metronome = Metronome.getMetronomeWithSettings(initialTempo: 60, allowChangeTempo: true, ctx: "")
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
        AfterPressedView(model: model, piano: piano, buttonTexts: getFingerTexts())
    }

    func topLineView() -> some View {
        HStack {            
            Button(action: {
                rightHand.toggle()
                model.piano = rightHand ? Piano(startMidi: 65, number: 30) : Piano(startMidi: 36, number: model.totalKeys)
            }) {
                HStack {
                    if rightHand {
                        VStack {
                            Text("Right\nHand").font(.title)
                            Image("right_hand").resizable().frame(width: imageSize, height: imageSize)
                                .foregroundColor(.green).bold()
                        }
                    }
                    else {
                        VStack {
                            Text("Left\nHand").font(.title)
                            Image("left_hand").resizable().frame(width: imageSize, height: imageSize)
                                .foregroundColor(.purple).bold()
                        }
                    }
                }
            }
            .padding()

            Button(action: {
                ascending.toggle()
                model.checkFingerNumbers = fingerMode
                model.setQuestionMode(way: .notStarted)
                model.reset()
                model.piano.reset()
            }) {
                HStack {
                    let imageSize = imageSize * 0.8
                    VStack {
                        if ascending {
                            Text("Ascending").font(.title)
                            Image(systemName: "square.and.arrow.up").resizable()
                                .foregroundColor(.green)
                                .frame(width: imageSize, height: imageSize)
                        }
                        else {
                            Text("Descending").font(.title)
                            Image(systemName: "square.and.arrow.down").resizable()
                                .foregroundColor(.purple)
                                .frame(width: imageSize, height: imageSize)
                        }
                    }
                }
            }
            .padding()
            
            Button(action: {
                model.setTimedMode(way: !model.timedMode)
                model.setQuestionMode(way: .notStarted)
                model.reset()
                model.piano.reset()
                timeAllowed = 20.0
                if fingerMode {
                    timeAllowed += 10.0
                }
            }) {
                VStack {
                    if !model.timedMode {
                        Text("Practice").font(.title)
                        Image("relax").resizable()
                            .foregroundColor(.green)
                            .frame(width: imageSize, height: imageSize)
                    }
                    else {
                        Text("Timed").font(.title)
                        Image("clock").resizable()
                            .foregroundColor(.purple)
                            .frame(width: imageSize, height: imageSize)
                    }
                }
            }
            .padding()

            Button(action: {
                fingerMode.toggle()
                model.checkFingerNumbers = fingerMode
                model.setQuestionMode(way: .notStarted)
                model.reset()
                model.piano.reset()
            }) {
                VStack {
                    if !fingerMode {
                        Text("No Fingers").font(.title)
                        Image("not_require_finger").resizable()
                            .foregroundColor(.green)
                            .frame(width: imageSize, height: imageSize)
                    }
                    else {
                        Text("Check Fingers").font(.title)
                        Image("require_finger").resizable()
                            .foregroundColor(.purple)
                            .frame(width: imageSize, height: imageSize)
                    }
                }
            }
            .padding()
        }
    }
    
    func timerStartNotification() {
        model.setQuestionMode(way: .inQuestion)
        model.piano.reset()
        model.reset()
    }

    func timerEndNotification() {
        model.piano.clearLastPressed()
        model.setQuestionMode(way: .inAnswer)
    }
    
    func commandsView() -> some View {
        HStack {
            if model.timedMode {
                HStack {
                    CountdownTimerView(size: 50, timerColor: Color.green, timeLimit: $timeAllowed,
                                       startNotification: timerStartNotification,
                                       endNotification: timerEndNotification)
                    .padding()
                    Text("Time allowed is \(Int(self.timeAllowed)) seconds ").font(.title)
                    Slider(value: $timeAllowed, in: 5...40, step: 1.0)
                    .frame(width: UIScreen.main.bounds.width / 4.0)
                    .padding()
                }
            }
            else {
                Button(action: {
                    model.piano.playScale(scale: model.scale, ascending: ascending)
                }) {
                    Text("Play Scale").font(.title)
                }
                .padding()
                Button(action: {
                    model.reset()
                    model.piano.reset()
                }) {
                    Text("Reset").font(.title)
                }
                .padding()
            }
        }
    }
    
    var body: some View {
        let backColor = Color(red: 0.0 / 255.0, green: 128.0 / 255.0, blue: 128.0 / 255.0, opacity: 0.1)

        VStack {
            Text("Scale Trainer").font(.title).padding()
                .font(.title)
                .bold()
                .foregroundColor(.blue)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(backColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 4)
                )
                .padding()
            
            Button(action: {
                self.showSelectScale = true
            }) {
                Text("Select Scale").font(.title)
            }

            topLineView()
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(backColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 20) // Rounded rectangle shape
                        .stroke(Color.blue, lineWidth: 4) // Set the color and line width of the border
                )
            
            commandsView()
            
            MetronomeView(timeSignature: TimeSignature(top: 4, bottom: 4), helpText: "hT", frameHeight: 140)

            PianoView<ScalesView>(piano: model.piano).padding()
            
            //.border(Color .red)
        
        }
        .sheet(isPresented: $showSelectScale) {
            SelectScaleView(model: model)
        }
        .onAppear() {
        }
    }
}

