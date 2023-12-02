import Foundation
import SwiftUI

struct PianoKeyView: View {
    let id:Int
    @ObservedObject var pianoKey:PianoKey
    @Binding var questionMode:QuestionMode

    var cornerRadius: CGFloat = 6

    var borderColor: Color = .black
    var borderWidth: CGFloat = 1
    var imageSize = 25.0
    
    func getColor(_ key:PianoKey) -> Color {
        if key.wasLastKeyPressed {
            return Color(.systemTeal)
        }
        //return Color(.white)
        else {
            return pianoKey.color == .white ? Color.white : Color.black
        }
    }
    
    func noteText(pianoKey:PianoKey) -> some View {
        VStack {

            Spacer()
//            if pianoKey.color == .white {
//                Text("").foregroundColor(pianoKey.color == KeyColor.white ? Color.black : Color.white).padding().padding()
//            }
            //let midi = "\(pianoKey.midi)"
            if let correct = pianoKey.isCorrect {
                let wrongFinger = pianoKey.requiresFingerPrompt && pianoKey.inScale && (pianoKey.userFinger != pianoKey.correctFinger)
                //let wrongNote = !correct && !wrongFinger

                VStack {
                    if correct {
                        Image(systemName: "checkmark").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.green).bold()
                    }
                    else {
                        if wrongFinger {
                            Image(systemName: "hand.raised").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red).bold()
                        }
                        else {
                            if pianoKey.inScale {
                                Image(systemName: "scribble.variable").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red).bold()
                            }
                            else {
                                Image(systemName: "questionmark").resizable().frame(width: imageSize, height: imageSize).foregroundColor(.red).bold()
                            }
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    func explanationView(pianoKey: PianoKey) -> some View {
        VStack {
            if let correct = pianoKey.isCorrect {
                let wrongFinger = pianoKey.requiresFingerPrompt && pianoKey.inScale && (pianoKey.userFinger != pianoKey.correctFinger)
                let wrongNote = !correct && !wrongFinger

                HStack {
                    Text("Notes").foregroundColor(Color.white).font(.title).padding(.top)
                    Image(systemName: "circle.fill")
                        .foregroundColor(wrongNote ? .red : .green)
                }
                if wrongNote {
                    if pianoKey.inScale {
                        Text("This note was missing")
                    }
                    else {
                        Text("This note is not in the scale")
                    }
                }
                if !wrongNote {
                    HStack {
                        Text("Fingers").foregroundColor(Color.white).font(.title)
                        Image(systemName: "circle.fill")
                            .foregroundColor(wrongFinger ? .red : .green)
                    }
                    if pianoKey.getFingerStr(user: false).count > 0 {
                        Text("Correct \(pianoKey.getFingerStr(user: false))")
                        Text("Yours   \(pianoKey.getFingerStr(user: true))")
                    }
                }
            }
        }
        .frame(width: 200, height: 200) // Larger than the underlying Image
        .background(Color.blue.opacity(1.0))
        .cornerRadius(10)
        .offset(x: 0, y: -250)
        .zIndex(10)
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let rect = CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.size.height)
                Path { path in
                    // Start from the top left corner
                    path.move(to: CGPoint(x: rect.minX, y: rect.minY))
                    
                    // Draw the top edge
                    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                    
                    // Draw the right edge
                    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
                    
                    // Draw the bottom right rounded corner
                    path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
                                radius: cornerRadius,
                                startAngle: Angle(degrees: 0),
                                endAngle: Angle(degrees: 90),
                                clockwise: false)
                    
                    // Draw the bottom edge
                    path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
                    
                    // Draw the bottom left rounded corner
                    path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
                                radius: cornerRadius,
                                startAngle: Angle(degrees: 90),
                                endAngle: Angle(degrees: 180),
                                clockwise: false)
                    
                    // Draw the left edge and close the path
                    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
                }
                .fill(getColor(pianoKey))
                .overlay(
                    Path { path in
                        // Draw the same path for the border
                        path.addRoundedRect(in: rect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
                    }
                    .stroke(borderColor, lineWidth: borderWidth)
                )
            }
            VStack {
                noteText(pianoKey: pianoKey)
            }
        }
        .overlay(
            (pianoKey.showInfo && questionMode == .inAnswer) ? explanationView(pianoKey: pianoKey) : nil
        )
    }
}
