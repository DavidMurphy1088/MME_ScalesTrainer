import SwiftUI
import CommonLibrary
import Combine

struct NoteExplanationView: View {
    var model:ScalesAppModel
    let key:PianoKey
    var body: some View {
        VStack {
            let status = model.getNoteShowStatus(pianoKey: key)
            if status == .outOfScale {
                Text("This note you played is not the scale of \(model.getScaleName())")
            }
            if status == .missing {
                Text("You didn't play this note but it is required in the scale of \(model.getScaleName())")
            }
            if status == .tooEarly {
                Text("This note was played too early")
            }
            if status == .tooLate {
                Text("This note was played too late")
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

///Handling of key state after a piano key is tapped
///Prompt for finger number if required
struct AfterPressedHandler: View {
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
        if let lastMidiPressed = piano.lastMidiPressed {
            piano.playNote(midi: lastMidiPressed)
            model.setUsersFingerForMidi(midi: lastMidiPressed, finger: finger)
        }
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
            if let lastMidiPressed = piano.lastMidiPressed {
                model.saveTap(midi: lastMidiPressed)
            }
            if model.questionState != .inAnswer {
//                if keyPresses == 0 {
//                    if model.fingerMode {
//                        if model.scale.getRequiredFinger(midi: piano.lastMidiPressed) != nil {
//                            if model.getUsersFingerForMidi(midi: piano.lastMidiPressed) == nil {
//                                fingerChoiceToBePresented = true
//                            }
//                        }
//                    }
//                }
                if !fingerChoiceToBePresented {
                    if let lastMidiPressed = piano.lastMidiPressed {
                        piano.playNote(midi: lastMidiPressed)
                    }
                }
            }
        })
    }
}

struct ScaleNoteView: View {
    @ObservedObject var model:ScalesAppModel
    @ObservedObject var key:PianoKey
    @State private var isHovering = false
    let imageSize = 40.0
    @State var showExplanation = false
    @State var isNextFlashing = false

    func getFinger() -> String {
        var fingerStr = ""
        let finger = model.scale.getFinger(midi: key.midi)
        if let finger = finger {
            fingerStr = String(finger+1)
        }
        return fingerStr
    }
    
    func getShowStatus(midi:Int) -> NoteDisplayState  {
        let state = model.getNoteShowStatus(pianoKey: key)
//        if [60,62,64].contains(midi) {
//            print("=========== getShowStatus For_midi", midi, "State", state)
//            model.piano?.debug("getShowStatus", midi: midi)
//        }
        return state
    }
    
    var body: some View {
        ///For each key state show the right button and image
        ///The explanation popover must be attached to t each button to hace the popover appear next to the key
        ///On any layout changes here - make sure centered alignment of kb is not wrecked
        let show = getShowStatus(midi: key.midi)
        let padding = 0.0
        
        ///Must use ZStack to ensure all note view status images are horizontally aligned irrespective of presence of finger data
        ZStack {
            //let keyPress = model.statesForMidi[key.midi]
            if model.fingerMode {
                VStack {
                    if false {
                        Text("\(key.midi)").foregroundColor(key.color == .white ? Color.black : Color.white)
                    }
                    else {
                        Text("").padding().font(.title)
                        Text("").padding().font(.title)
                    }
                    Text("\(getFinger())").padding().font(.title).foregroundColor(key.color == .white ? Color.black : Color.white)
                }
            }

            VStack {
                if show == .correct {
                    Image(systemName: "checkmark").resizable().frame(width: imageSize * 0.8, height: imageSize)
                                                .foregroundColor(.green).bold().padding(.top, padding)
                }
                if show == .tooEarly {
                    let size = imageSize * 1.0
                    Button(action: {
                        self.showExplanation = true
                    }) {
                        Image(systemName: "hare.fill").resizable().frame(width: size, height: size)
                            .foregroundColor(.yellow)
                    }
                    .popover(isPresented: $showExplanation) {
                        NoteExplanationView(model: model, key: key)
                            .padding()
                    }
                }
                
                if show == .nextToPlay {
                    let size = imageSize * 1.0
                    Image("finger_point").resizable().frame(width: size, height: size)
                    .foregroundColor(.green).bold().padding(.top, padding)
                    .opacity(isNextFlashing ? 1.0 : 0.0)
                    .onAppear() {
                        withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            isNextFlashing.toggle()
                        }
                    }
                }
                if show == .tooLate {
                    let size = imageSize * 1.0
                    Button(action: {
                        self.showExplanation = true
                    }) {
                        Image(systemName: "tortoise.fill").resizable().frame(width: size, height: size)
                            .foregroundColor(.yellow)
                    }
                    .popover(isPresented: $showExplanation) {
                        NoteExplanationView(model: model, key: key)
                            .padding()
                    }
                }

                if show == .outOfScale {
                    Button(action: {
                        self.showExplanation = true
                    }) {
                        Image("wrong").resizable().frame(width: imageSize, height: imageSize)
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
                        Image("missing").resizable().frame(width: imageSize, height: imageSize)
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
    @State var userMessage = ""
    @State var fingerMode = false
    @State var seeNextFingerMode = true
    @State var ascending = true
    @State var rightHand = true
    @State private var isExamFlashing = false
    
    let checkSize = 30.0
    let imageSize = 80.0

    init() {
        model = ScalesAppModel.shared
        self.showSelectScale = false
    }

    init(showSelectScale:Bool) {
        model = ScalesAppModel.shared
        self.showSelectScale = showSelectScale
        //metronome = Metronome.getMetronomeWithSettings(initialTempo: 60, allowChangeTempo: true, ctx: "")
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
    
    func getActionHandler(piano:Piano) -> some View {
        AfterPressedHandler(model: model, piano: piano, buttonTexts: getFingerTexts())
    }

    func topLineView() -> some View {
        HStack {            
            Button(action: {
                rightHand.toggle()
                model.piano = rightHand ? Piano(startMidi: 65, number: 30) : Piano(startMidi: 36, number: model.pianoTotalKeys)
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
                model.fingerMode = fingerMode
                model.setQuestionState(state: .notStarted)
                model.setAllKeysUnPressed()
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
                seeNextFingerMode.toggle()
                model.seeNextFingerMode = seeNextFingerMode
                model.setQuestionState(state: .notStarted)
                model.setAllKeysUnPressed()
            }) {
                VStack {
                    if seeNextFingerMode {
                        Text("Next Finger Showing").font(.title)
                        Image(systemName: "eye").resizable()
                            .foregroundColor(.green)
                            .frame(width: imageSize, height: imageSize * 0.7)
                    }
                    else {
                        Text("Next Finger Hidden").font(.title)
                        Image(systemName: "eye.slash").resizable()
                            .foregroundColor(.purple)
                            .frame(width: imageSize, height: imageSize * 0.7)
                    }
                }
            }
            .padding()

            Button(action: {
                fingerMode.toggle()
                model.fingerMode = fingerMode
                model.setQuestionState(state: .notStarted)
                model.setAllKeysUnPressed()
            }) {
                VStack {
                    if !fingerMode {
                        Text("Check Fingers").font(.title)
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

            Button(action: {
                if model.appMode == AppMode.practiceMode {
                    model.setAppMode(mode: .examMode)
                    model.setQuestionState(state: .notStarted)
                }
                else {
                    model.setAppMode(mode: .practiceMode)
                    model.setQuestionState(state: .notStarted)
                }
            }) {
                ZStack {
                    if model.appMode == .practiceMode {
                        VStack {
                            Text("Practice Mode").font(.title)
                            Image("relax").resizable()
                                .foregroundColor(.green)
                                .frame(width: imageSize, height: imageSize)
                            
                        }
                    }
                    else {
                        //.opacity(model.practiceMode ? 1.0 : 0.0)
                        VStack {
                            Text("Exam Mode").font(.title)
                            Image("exam_icon").resizable()
                                .foregroundColor(.purple)
                                .frame(width: imageSize, height: imageSize)
                        }
                        //.opacity(model.practiceMode ? 0.0 : 1.0)
                    }
                }
            }
            .padding()
        }
    }
    
    func commandsView(backgroundColor:Color) -> some View {
        HStack {
            HStack {
                if model.appMode == AppMode.practiceMode {
                    Button(action: {
                        if model.questionState == .inQuestion {
                            model.metronome.stopTicking()
                            model.debugStates("end of scale practice")
                            model.setQuestionState(state: .notStarted)
                        }
                        else {
                            model.setAllKeysUnPressed()
                            model.metronome.startTicking(timeSignature: TimeSignature(top: 4, bottom: 4))
                            model.setQuestionState(state: .inQuestion)
                        }
                    }) {
                        if model.questionState == .inQuestion {
                            Text("Stop").font(.title)
                        }
                        else {
                            Text("Start Metronome Scale").font(.title)
                        }
                    }
                    .padding()

                    if model.lastPressedKey != nil {
                        Button(action: {
                            model.setAllKeysUnPressed()
                        }) {
                            Text("Clear").font(.title)
                        }
                        .padding()
                    }
                    
                    //                    if let scale = model.scale {
                    //                        Button(action: {
                    //                            //scale(scale: model.scale, ascending: ascending)
                    //                        }) {
                    //                            Text("Play Scale").font(.title)
                    //                        }
                    //                        .padding()
                    //                    }
                }
                else {
                    Image("exam_icon").resizable()
                        .foregroundColor(.purple)
                        .opacity(isExamFlashing ? 1.0 : 0.0)
                        .frame(width: imageSize, height: imageSize)
                        .onAppear() {
                            withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                isExamFlashing.toggle()
                            }
                        }
                }
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(backgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 4)
            )
            .padding()
            
            MetronomeView(timeSignature: TimeSignature(top: 4, bottom: 4), helpText: "Set the tempo for your scale", 
                          frameHeight: 80, backgroundColor: backgroundColor)
            .frame(width: UIScreen.main.bounds.width * 0.50)
            .background(RoundedRectangle(cornerRadius: 12).fill(backgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 4)
            )
            .padding()
        }
    }
    
    func headingView(backgroundColor:Color) -> some View {
        HStack {
            HStack {
                Text("Scale Trainer-\(model.getScaleName())").font(.title).padding()
            }
            .font(.title)
            .bold()
            .foregroundColor(.blue)
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(backgroundColor))
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
        }
    }
    
    var body: some View {
        let backgroundColor = Color(red: 0.0 / 255.0, green: 128.0 / 255.0, blue: 128.0 / 255.0, opacity: 0.1)

        VStack {
            headingView(backgroundColor: backgroundColor)
            
            topLineView()
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(backgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 20) // Rounded rectangle shape
                        .stroke(Color.blue, lineWidth: 4) // Set the color and line width of the border
                )
            
            commandsView(backgroundColor: backgroundColor)
            
            if let piano = model.piano {
                PianoView<ScalesView>(piano: piano).padding()
            }
            
            //.border(Color .red)
        
        }
        .sheet(isPresented: $showSelectScale) {
            SelectScaleView(model: model)
        }
        .onAppear() {
        }
    }
}

