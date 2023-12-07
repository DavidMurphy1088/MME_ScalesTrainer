
import SwiftUI

enum QuestionMode {
    case notStarted
    case inQuestion
    case inAnswer
}

class ScalesAppModel : ObservableObject {
    @Published var timedMode:Bool = false
    @Published var questionMode = QuestionMode.notStarted    
    @Published var piano:Piano
    @Published var fingerUsedByMidi:[Int?]
    @Published var keyPressesForMidi:[Int]
    @Published var showSheet = false

    let totalKeys = 31
    var scale = Scale(name: "A\u{266D} Harmonic Minor")
    var checkFingerNumbers = false
    
    static let shared:ScalesAppModel = ScalesAppModel()
    
    init() {
        self.piano = Piano(startMidi: 65, number: totalKeys)
        fingerUsedByMidi = Array(repeating: nil, count: 65 + totalKeys + 1)
        keyPressesForMidi = Array(repeating: 0, count: 65 + totalKeys + 1)
    }
    
    func reset() {
        DispatchQueue.main.async {
            for i in 0..<self.fingerUsedByMidi.count {
                self.fingerUsedByMidi[i] = nil
                self.keyPressesForMidi[i] = 0
            }
        }
    }
    
    func setTimedMode(way:Bool) {
        DispatchQueue.main.async {
            self.timedMode = way
        }
    }
    
    func setQuestionMode(way:QuestionMode) {
        DispatchQueue.main.async {
            self.questionMode = way
        }
    }
    
//    func setShowExplanation(midi:Int) {
//        DispatchQueue.main.async {
//            self.showExplanation = midi
//        }
//    }

    func setFingerForMidi(midi:Int, finger:Int) {
        DispatchQueue.main.async {
            self.fingerUsedByMidi[midi] = finger
            if midi == 69 {
                self.showSheet = true
            }
        }
    }
    
    func addKeyPressedForMidi(midi:Int) {
        DispatchQueue.main.async {
            self.keyPressesForMidi[midi] += 1
        }
    }
}

@main
struct ScalesTrainerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ScalesView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
