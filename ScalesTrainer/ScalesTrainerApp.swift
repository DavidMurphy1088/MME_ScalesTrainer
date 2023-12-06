
import SwiftUI

enum QuestionMode {
    case notStarted
    case inQuestion
    case inAnswer
}

class ScalesAppModel : ObservableObject {
    @Published var timedMode:Bool = false
    @Published var questionMode = QuestionMode.notStarted
    var scale = Scale(name: "A\u{266D} Harmonic Minor")

    init() {
    }
    
    static let shared:ScalesAppModel = ScalesAppModel()
    
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
