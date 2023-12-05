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
    @Binding var selectedFinger: Int?
    let boxHeight:Double
    
    var body: some View {
        VStack {
            HStack {
                HStack {
                    Image("lefthand")
                        .resizable()
                        .scaledToFit()
                        .frame(height: boxHeight)
                    Text("Which finger ?  ").font(.title)
                }

                HStack {
                    ForEach(0..<5) { index in
                        ZStack {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 2.0 * boxHeight, height: boxHeight)
                                .onTapGesture {
                                    selectedFinger = 4 - index
                                }

                            Text("\(5 - index)")
                        }
                    }
                }
            }
        }
    }
}

enum QuestionMode {
    case notStarted
    case inQuestion
    case inAnswer
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

struct ScalesView: View {
    @State var timeAllowed:Double = 0.0
    @State var userMessage = ""
    @State var timedMode = false
    @State var fingerMode = false
    @State var ascending = true
    @State var rightHand = true
    let checkSize = 30.0
    @State var scale = Scale(name: "A\u{266D} Harmonic Minor")
    @State var piano = Piano(startMidi: 65, number: 30) //, ascending: <#Bool#>, rightHand: <#Bool#>)
    
//    init(score:Score) {
//        self.score = score
//    }
    
    func topLineView() -> some View {
        HStack {
            SelectScaleView().padding()
            
            Button(action: {
                rightHand.toggle()
                piano = rightHand ? Piano(startMidi: 65, number: 30) : Piano(startMidi: 36, number: 30)
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
                timedMode.toggle()
                if timedMode {
                    timeAllowed = 15.0
                    if fingerMode {
                        timeAllowed += 5
                    }
                }
            }) {
                HStack {
                    Image(systemName: timedMode ? "checkmark.square" : "square").resizable().frame(width: checkSize, height: checkSize)
                    Text("Timed Mode").font(.title)
                }
            }
            .padding()
            
            Button(action: {
                fingerMode.toggle()
            }) {
                HStack {
//                        Image("lefthand")
//                            .resizable()
//                            .foregroundColor(fingerMode ? .green : .gray)
//                            .scaledToFit()
//                            .frame(height: 60)
                    Image(systemName: fingerMode ? "checkmark.square" : "square").resizable().frame(width: checkSize, height: checkSize)
                    Text("Check Fingering").font(.title)//.foregroundColor(fingerMode ? .green : .gray)
                }
            }
            .padding()
        }
    }
    
    func commandsView() -> some View {
        HStack {
            //if !timedMode || questionMode == .inAnswer {
                Button(action: {
                    piano.playScale(scale: scale, ascending: ascending)
                }) {
                    Text("Play Scale").font(.title)
                }
                .padding()
            //}
        }
    }
    
    func testAction(a:Int) {
        print("====================action", a)
    }
    
    var body: some View {
        VStack {
            Text("Scale Trainer").font(.title).padding()
            
            topLineView()
            
            commandsView()

            if timedMode {
                HStack {
                    Text("     ").padding()
                    HStack {
                        Text("Time Allowed \(Int(self.timeAllowed))").font(.title)
                        Slider(value: $timeAllowed, in: 8...40, step: 1.0)
                    }
                    .padding()
                    Text("     ").padding()
                }
            }
            
            PianoView(piano: piano,
                      keyDisplayView: InsideKeyView(keyString: "", key: PianoKey(midi: 0)),
                      action: ChooseFinger(piano: piano)
                      )
            .padding()
            //.border(Color .red)
        
        }
        .onAppear() {
        }
    }
}

struct ChooseFinger: Action {
    @ObservedObject var piano:Piano
    var imageSize = 25.0
    @State var isPresented = false
    init(piano: Piano) {
        self.piano = piano
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
                    .default(Text("Option 1")) {  },
                    .default(Text("Option 2")) { },
                    .destructive(Text("Delete")) {  },
                    .cancel() {  }
                ]
            )
            
        }
        .onChange(of: piano.lastKeyPressed, perform: {newValue in
            print("====================== CHOOSE", newValue)
            isPresented = true
        })
    }
}

struct InsideKeyView: InsideKeyViewType {
    let keyString: String
    @ObservedObject var key:PianoKey
    var imageSize = 25.0
    @State var scale = Scale(name: "A\u{266D} Harmonic Minor")

    init(keyString: String, key:PianoKey) {
        self.keyString = keyString
        self.key = key
    }

    var body: some View {
        //Text("X\(key.midi)").foregroundColor(.red).bold()
        Spacer()
        let noteInScale = scale.isMidiInScale(midi: key.midi)
        if key.wasPressed  {
            VStack {
                if noteInScale  {
                    Image(systemName: "checkmark").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.green).bold()
                }
                else {
                    if true {
                        Image(systemName: "questionmark").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red).bold()
                    }
                    else {
                        Image(systemName: "scribble.variable").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red).bold()
                    }
                }
                //else {
                    //                    if showFingers() {
                    //                        if fingersCorrect() {
                    //                            Image(systemName: "checkmark").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.green).bold()
                    //                        }
                    //                        else {
                    //                            //Image("lefthand").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red).bold()
                    //                            Image(systemName: "hand.raised.fill").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red).bold()
                    //                        }
                    //                    }
                    //                    else {
                    //                        Image(systemName: "checkmark").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.green).bold()
                    //                    }
                //}
            }
            .padding(.bottom, 30)
        }
    }
}

