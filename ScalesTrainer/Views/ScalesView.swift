import SwiftUI
import CommonLibrary
import Combine

import SwiftUI

struct CustomModifier: ViewModifier {
    var backgroundColor: Color

    func body(content: Content) -> some View {
        content
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(backgroundColor))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue, lineWidth: 4))
    }
}

// Extend View to include a method to apply the custom modifier
extension View {
    func customBlock() -> some View {
        self.modifier(CustomModifier(backgroundColor: Color(red: 0.0 / 255.0, green: 128.0 / 255.0, blue: 128.0 / 255.0, opacity: 0.1)
))
    }
}

struct NoteExplanationView: View {
    var model:ScalesAppModel
    let key:PianoKey
    var body: some View {
        VStack {
            let status = model.getNoteStatus(pianoKey: key)
            if status == .outOfScale {
                //Text("This note you played is not the scale of \(model.getScaleName())")
                Text("This note you played is not in the \(model.getScaleName())")
            }
            if status == .missing {
                Text("You didn't play this note but it is required in the \(model.getScaleName())")
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
        self.model.afterActionSubmitted()
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

            ///Check if UI has to be presented to ask for the user's finger choice
            if model.getQuestionState() != .inAnswer {
                if model.checkFingerMode {
                    if let lastMidiPressed = piano.lastMidiPressed {
                        if model.scale.getRequiredFinger(midi: lastMidiPressed) != nil {
                            if model.getUsersFingerForMidi(midi: lastMidiPressed) == nil {
                                fingerChoiceToBePresented = true
                                self.model.beforeActionSubmitted()
                            }
                        }
                    }
                }
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
    @ObservedObject var keyState:KeyState

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
    
    func showFinger(midi:Int) -> Bool {
        return model.showingFingers
//        let show = getShowStatus(midi: key.midi)
//        if show == .nextToPlay {
//            return true
//        }
//        if model.statesForMidi[midi]?.scaleNoteHilite == true {
//            return true
//        }
//        if model.checkFingerMode {
//            return true
//        }
//        if model.showingFingers  {
//            //if midi == model.piano?.lastMidiPressed {
//                return true
//            //}
//        }
////        model.checkFingerMode || showFinger ?
////        show == .nextToPlay
//        return false
    }
    
    var body: some View {
        ///For each key state show the right button and image
        ///The explanation popover must be attached to t each button to hace the popover appear next to the key
        ///On any layout changes here - make sure centered alignment of kb is not wrecked
        let show = model.getNoteStatus(pianoKey: key)
        let padding = 0.0
        
        ///Must use ZStack to ensure all note view status images are horizontally aligned irrespective of presence of finger data
        ZStack {
            if showFinger(midi: key.midi) {
                VStack {
                    if false {
                        Text("\(key.midi)").foregroundColor(key.color == .white ? Color.black : Color.white)
                    }
                    else {
                        Text("").padding().font(.title)
                    }
                    Text("\(getFinger())")
                        //.padding()
                        .font(.title).foregroundColor(key.color == .white ? Color.black : Color.white)
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
                    let size = imageSize * 0.7
                    Image("finger_point").resizable().frame(width: size, height: size)
                    .foregroundColor(.yellow).bold().padding(.top, padding)
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
                        Image(systemName: "hand.point.up.left.fill").resizable().frame(width: imageSize * 1.0, height: imageSize * 1.0)
                            .foregroundColor(.red).bold().padding(.top, padding)
                    }
                    .popover(isPresented: $showExplanation) {
                        NoteExplanationView(model: model, key: key)
                            .padding()
                    }
                }
                Text(" ")//.padding()
            }
        }
        //.border(.green)
    }
}

struct ScalesView: PianoUserProtocol, View {    
    @ObservedObject var model:ScalesAppModel
    @State var showSelectScale:Bool
    @State var userMessage = ""
    @State var checkFingerMode = false
    @State var seeNextNoteMode = false
    @State var ascending = true
    @State var rightHand = true
    @State private var isExamFlashing = false
    @State private var showMetronome = false

    let checkSize = 30.0
    let imageSize = 50.0

    init() {
        model = ScalesAppModel.shared
        self.showSelectScale = false
    }

    init(showSelectScale:Bool) {
        model = ScalesAppModel.shared
        self.showSelectScale = showSelectScale
    }

    func getKeyDisplayView(key:PianoKey) -> some View {
        VStack {
            if let state = model.statesForMidi[key.midi] {
                ScaleNoteView(model: model, key: key, keyState: state)
            }
        }
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
//        VStack {
//            if let midi = piano.lastMidiPressed {
//                if let keyState = model.statesForMidi[midi] {
                    AfterPressedHandler(model: model,
                                        piano: piano,
                                        buttonTexts: getFingerTexts())
//                }
//            }
//        }
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
                model.checkFingerMode = checkFingerMode
                model.setQuestionState(state: .notStarted)
                model.reset()
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
                seeNextNoteMode.toggle()
                model.seeNextFingerMode = seeNextNoteMode
                model.setQuestionState(state: .notStarted)
                model.reset()
            }) {
                VStack {
                    if seeNextNoteMode {
                        Text("Next Note\nShowing").font(.title)
                        Image("finger_point").resizable()
                            .bold()
                            .foregroundColor(.yellow)
                            .frame(width: imageSize, height: imageSize * 0.7)
                    }
                    else {
                        Text("Next Note\nHidden").font(.title)
                        Image(systemName: "eye.slash").resizable()
                            .foregroundColor(.green)
                            .frame(width: imageSize, height: imageSize * 0.7)
                    }
                }
            }
            .padding()

            Button(action: {
                checkFingerMode.toggle()
                model.checkFingerMode = checkFingerMode
                model.setQuestionState(state: .notStarted)
                model.reset()
            }) {
                VStack {
                    if !checkFingerMode {
                        Text("Dont Check\nFingering").font(.title)
                        Image("not_require_finger").resizable()
                            .foregroundColor(.green)
                            .frame(width: imageSize, height: imageSize)
                    }
                    else {
                        Text("Check Fingering").font(.title)
                        Image("require_finger").resizable()
                            .foregroundColor(.purple)
                            .frame(width: imageSize, height: imageSize)
                    }
                }
            }
            .padding()

            Button(action: {
                if model.appMode == AppMode.practiceMode {
                    model.startExam()
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

    func commandsView() -> some View {
        HStack {
            HStack {
                if model.appMode == AppMode.practiceMode {
                    
                    Button(action: {
                        if model.showingFingers {
                            model.setShowingFingers(way: false)
                        }
                        else {
                            model.setShowingFingers(way: true)
                        }
                    }) {
                        if model.showingFingers {
                            Text("Hide Fingers").font(.title)
                        }
                        else {
                            Text("Show Fingers").font(.title)
                        }
                    }
                    .customBlock()
                    .padding()
                    
                    Button(action: {
                        if model.practiceState == .playingScale {
                            model.stopScale()
                            model.setPracticeState(state: .none)
                        }
                        else {
                            model.setPracticeState(state: .playingScale)
                            model.playScale()
                        }
                    }) {
                        if model.practiceState == .playingScale {
                            Text("Stop Scale").font(.title)
                        }
                        else {
                            Text("Play Scale").font(.title)
                        }
                    }
                    .customBlock()
                    .padding()

                    Button(action: {
                        if model.getQuestionState() == .inQuestion {
                            model.stopTicking()
                            model.setQuestionState(state: .notStarted)
                        }
                        else {
                            model.reset()
                            model.startTicking()
                            model.setQuestionState(state: .inQuestion)
                        }
                    }) {
                        if model.getQuestionState() == .inQuestion {
                            Text("Stop").font(.title)
                        }
                        else {
                            Text("Timed Scale").font(.title)
                        }
                    }
                    .customBlock()
                    .padding()
                    
                    //if model.lastPressedKey != nil {
                        Button(action: {
                            model.reset()
                        }) {
                            Text("Clear").font(.title)
                        }
                        .customBlock()
                        .padding()
                    //}
                    
                    Button(action: {
                        self.showMetronome.toggle()
                    }) {
                        Text("Metronome").font(.title)
                    }
                    .customBlock()
                    .padding()
                    .popover(isPresented: $showMetronome) {
                        HStack {
                            metronomeView()
                                .customBlock()
                                .padding()
                        }
                        .padding()
                    }

               }
                else {
                    Image("exam_icon").resizable()
                        .foregroundColor(.purple)
                        .bold()
                        .opacity(isExamFlashing ? 1.0 : 0.0)
                        .frame(width: imageSize * 2.0, height: imageSize * 2.0)
                        .onAppear() {
                            withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                isExamFlashing.toggle()
                            }
                        }
                }
            }
            .padding()
        }
    }
    
    func metronomeView() -> some View {
        VStack {
            //let imageSize = imageSize / 2.0
            HStack {
                Button(action: {
                    model.setDoubleTempo(way: !model.doubleTempo)
                }) {
                    if model.doubleTempo {
                        Image("note_eighth").resizable()
                            .foregroundColor(.red)
                            .frame(width: imageSize, height: imageSize)
                    }
                    else {
                        Image("note_quarter").resizable()
                            .foregroundColor(.black)
                            .frame(width: imageSize, height: imageSize)
                    }
                }
                
                MetronomeView(timeSignature: TimeSignature(top: 4, bottom: 4), helpText: "Set the tempo for your scale",
                              frameHeight: 80, backgroundColor: Color .white)
                .frame(width: UIScreen.main.bounds.width * 0.50, height: UIScreen.main.bounds.height * 0.10)
            }
        }
    }
    
    func headingView() -> some View {
        HStack {
            Text("Scale Trainer-\(model.getScaleName())").font(.title).padding()
            .font(.title)
            .bold()
            .foregroundColor(.blue)
            Button(action: {
                self.showSelectScale = true
            }) {
                Text("Select Scale").font(.title)
            }
        }
        .customBlock()
    }
    
    var body: some View {
        VStack {
            headingView()
                .padding()
            
            topLineView()
//                .padding()
//                .background(RoundedRectangle(cornerRadius: 12).fill(backgroundColor))
//                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.blue, lineWidth: 4))
                .customBlock()
            
            commandsView()
                //.customBlock()
            

            if let piano = model.piano {
                PianoView<ScalesView>(piano: piano).padding()
            }
            Text("© 2024 Musicmaster Education Limited")
        }
        .sheet(isPresented: $showSelectScale) {
            SelectScaleView(model: model)
        }
        .sheet(isPresented: $model.showExamResults) {
            ExamResultsView(model: model)
        }
        .onAppear() {
        }
    }
}

