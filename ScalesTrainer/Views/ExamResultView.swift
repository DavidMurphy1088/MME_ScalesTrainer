import SwiftUI
import CommonLibrary
import Combine
import SwiftUI
import Foundation

struct ExamResultsView: View {
    @Environment(\.presentationMode) var presentationMode
    let model:ScalesAppModel
    
    func gradeLetter() -> String {
        guard let correct = model.examResultCorrectCount else {
            return ""
        }
        guard let scaleCount = model.examResultNoteCount else {
            return ""
        }
        guard let wrong = model.examResultWrongCount else {
            return ""
        }
        let score = max(correct - wrong, 0)
        
        let percent = (score * 100) / scaleCount
        
        var grade:String
        switch percent {
        case 93...100:
            return "A+"
        case 86..<93:
            return "A"
        case 80..<86:
            return "A-"
        case 73..<80:
            return "B+"
        case 66..<73:
            return "B"
        case 60..<66:
            return "B-"
        case 53..<60:
            return "C+"
        case 46..<53:
            return "C"
        case 40..<46:
            return "C-"
        default:
            return "F"
        }
        return grade
    }
    
    func getImage() -> Int {
        let correct = model.examResultCorrectCount
        var face = 0x1F60A
        let letter = gradeLetter()
        if letter.contains("B") {
            face = 0x1F642
        }
        if letter.contains("C") {
            face = 0x1F610
        }
        if letter.contains("F") {
            face = 0x1F641
        }
        return face
    }
    
    var body: some View {
        if let correct = model.examResultCorrectCount {
            Text("Exam Results").font(.title).foregroundColor(Color .blue).bold().padding()
            Text("Exam Grade \(gradeLetter())").font(.title2).padding()
            Text("Correct Notes \(correct)").font(.title2).padding()
            if let wrong = model.examResultWrongCount {
                Text("Wrong Notes \(wrong)").font(.title2).padding()
            }
            Text(String(UnicodeScalar(getImage())!))
                        .font(.system(size: 100))
        }
    }
}
