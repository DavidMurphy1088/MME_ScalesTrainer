import Foundation
import SwiftUI

///View that a key wil display
protocol InsideKeyViewType: View {
    init(key :PianoKey)
}

struct PianoKeyView<PianoUser>: View where PianoUser: PianoUserProtocol {
    let id:Int
    @ObservedObject var piano:Piano
    @ObservedObject var pianoKey:PianoKey
    let user:PianoUser

    @State var lastKeyPressedTime:Date? = nil
    var cornerRadius: CGFloat = 6

    var borderColor: Color = .black
    var borderWidth: CGFloat = 1
    
    func getColor(_ key:PianoKey) -> Color {
        if key == piano.hilightedKey {
            return Color(.systemTeal)
        }
        else {
            return pianoKey.color == .white ? Color.white : Color.black
        }
    }
    
//    func fingerIsCorrect() -> Bool {
//        if !fingerMode {
//            return true
//        }
//        if pianoKey.requiresFingerPrompt {
//            if let userFinger = pianoKey.userFinger {
//                return userFinger == pianoKey.correctFinger
//            }
//            else {
//                return false
//            }
//        }
//        else {
//            return true
//        }
//    }
    
//    func showFingers() -> Bool {
//        if !fingerMode {
//            return false
//        }
//        if !pianoKey.requiresFingerPrompt {
//            return false
//        }
//        return true
//    }
    
//    func fingersCorrect() -> Bool {
//        if let fingerIsCorrect = pianoKey.fingerIsCorrect {
//            return fingerIsCorrect
//        }
//        return false
//    }

    func noteDisplay(pianoKey:PianoKey) -> some View {
        VStack {
        }
    }
        
    func explanationView(pianoKey: PianoKey) -> some View {
        VStack {
//            if let noteIsCorrect = pianoKey.noteIsCorrect {
//                HStack {
//                    Image(systemName: "circle.fill").foregroundColor(noteIsCorrect ? .green : .red)
//                    Text("Note").foregroundColor(Color.white).font(.title)
//                }
//
//                if !noteIsCorrect {
//                    if pianoKey.inScale {
//                        Text("This note was missing").foregroundColor(Color.white)
//                    }
//                    else {
//                        Text("This note is not in the scale").foregroundColor(Color.white)
//                    }
//                }
//                if noteIsCorrect {
//                    if showFingers() {
//                        if pianoKey.requiresFingerPrompt {
//                            HStack {
//                                Image(systemName: "circle.fill").foregroundColor(fingerIsCorrect() ? .green : .red)
//                                Text("Finger").foregroundColor(Color.white).font(.title)
//                            }
//                            if !fingerIsCorrect() {
//                                Text("Correct \(pianoKey.getFingerStr(user: false))").foregroundColor(Color.white)
//                                Text("Your \(pianoKey.getFingerStr(user: true))").foregroundColor(Color.white)
//                            }
//
//                        }
//                    }
//                }
//            }
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
                //noteDisplay(pianoKey: pianoKey)
                //insideKeyView
                user.getKeyDisplayView(key:pianoKey)
            }
        }
//        .overlay(
//            //pianoKey.showInfo ? explanationView(pianoKey: pianoKey) : nil
//        )
        .overlay(
            VStack {
                Spacer()
                Text("\(pianoKey.midi)").bold().foregroundColor(pianoKey.color == .white ? Color.black : Color.white)
            }
        )
    }
}

