import Foundation
import SwiftUI

struct PianoKeyView: View {
    let id:Int
    @ObservedObject var pianoKey:PianoKey
    var cornerRadius: CGFloat

    //var color: Color = .blue
    var borderColor: Color = .black
    var borderWidth: CGFloat = 1
    
    func getColor(_ key:PianoKey) -> Color {
        if key.wasLastKeyPressed {
            return Color(.systemTeal)
        }
        else {
            return pianoKey.color == .white ? Color.white : Color.black
        }
    }
    
    var body: some View {
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
    }
}