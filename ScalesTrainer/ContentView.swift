import SwiftUI
import CommonLibrary

struct PianoKey: View {
    var keyColor: Color
    var finger:Int?
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(keyColor)
                .cornerRadius(5)
                .border(.blue, width: 1)
            if let finger = finger {
                VStack {
                    Spacer()
                    Text("\(finger)").foregroundColor(.blue).bold().font(.title)
                    Text("")
                    Text("")
                }
            }
        }
    }
}

struct SelectScaleView: View {
    var body: some View {
        VStack {
            Button(action: {
            }) {
                Text("A\u{266D} Minor").defaultButtonStyle()
            }
        }
    }
}

class Fingers {
    private let midis = [60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81, 83, 84, 86]
    private var fingersLH:[Int:Int] = [:]
    private var fingersRH:[Int:Int] = [:]

    init( ) {
        fingersLH[68] = 3
        fingersLH[70] = 2
        fingersLH[72] = 1
        fingersLH[73] = 4
        fingersLH[75] = 3
        
        fingersRH[72] = 1
    }
    
    func getFinger(index:Int, hand:Int) -> Int? {
        if index < 0 {
            return nil
        }
        var midi = midis[index]
        if index < 5  {
            return nil
        }
        if index > 11 {
            return nil
        }
        midi = midi - (hand == 0 ? 0:1)
        if hand == 1 {
            if fingersLH.keys.contains(midi) {
                return fingersLH[midi]
            }
        }
        if hand == 0 {
            if fingersRH.keys.contains(midi) {
                return fingersRH[midi]
            }
        }
        return midi
//        let offset = midi % fingersLH.count
//        return fingersLH[offset]
    }
}

struct KeyboardView: View{
    private let whiteKeys = 16
    private let blackKeyOffsets = [0, 1, 3, 4, 5, 7, 8, 10,11,12,14]
    @State var offset = 0.0
    var fingers:Fingers = Fingers()
    
    var body: some View {
        ZStack(alignment: .topLeading) { // Aligning to the top and leading edge
            
            // White keys
            HStack(spacing: 0) {
                ForEach(0..<whiteKeys-1, id: \.self) { index in
                    PianoKey(keyColor: .white, finger: fingers.getFinger(index: index, hand: 0))
                        .frame(width: 60, height: 300)
                }
            }
            .border(Color.black, width: 1)
            
            // Black keys
            HStack(spacing: 0) {
                ForEach(0..<whiteKeys-1, id: \.self) { index in
                    if !blackKeyOffsets.contains(index) {
                        Spacer().frame(width: 60) // Spacing for white keys
                    } else {
                        let offset = 20.0
                        Spacer().frame(width: offset) // Spacing for white keys
                            .border(.red, width: 4)
                        PianoKey(keyColor: .black, finger: fingers.getFinger(index: index+1, hand: 1))
                            .frame(width: 40, height: 200)
                        //.offset(x: 30) // Adjust this offset for correct positioning
                    }
                }
            }
            .padding(.leading, 20) // Starting position of the first black key
        }
    }
}

struct ScalesView: View {
    @ObservedObject var score:Score
    
    var body: some View {
        VStack {
            Text("Scale Trainer").font(.title).padding()
            
            SelectScaleView().padding()

            ScoreView(score: score).padding()
            
            Text("Right Hand").font(.title).padding()
            KeyboardView().padding()
            Text("Left Hand").font(.title).padding()
            KeyboardView().padding()
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
            //.padding()
            .onAppear() {
                let staff = Staff(score: score, type: .treble, staffNum: 0, linesInStaff: 5)
                self.score.createStaff(num: 0, staff: staff)
                var ts = score.createTimeSlice()
                ts.addNote(n: Note(timeSlice: ts, num: 72, staffNum: 0))
            }
    }
}
