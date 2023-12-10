import SwiftUI
import CommonLibrary
import Combine
import Foundation

struct SelectKeyView: View {
    @Binding var selectedKey:Key
    @State var hiliteKey:Key? = nil
    let sharpKeys = Key.getAllKeys(type: .sharp)
    let flatKeys = Key.getAllKeys(type: .flat)

    func getKeyName() -> String {
        return selectedKey.getKeyName(withType: false)
    }
    
    var body: some View {
        VStack {
            Text("\(getKeyName())").font(.title).padding()
            HStack {
                List {
                    ForEach(sharpKeys, id: \.id) { key in
                        Text(key.getKeyName(withType: false))
                            .foregroundColor(.black)
                            .background(key == hiliteKey ? Color.teal : Color.clear)
                            .onTapGesture {
                                DispatchQueue.main.async {
                                    self.selectedKey = key
                                    self.hiliteKey = key
                                }
                            }
                    }
                }
                List {
                    ForEach(flatKeys, id: \.id) { key in
                        Text(key.getKeyName(withType: false))
                            .foregroundColor(.black)
                            .background(key == hiliteKey ? Color.teal : Color.clear)
                            .onTapGesture {
                                DispatchQueue.main.async {
                                    self.selectedKey = key
                                    self.hiliteKey = key
                                }
                            }
                    }
                }
            }
        }
        .onAppear() {
            hiliteKey = selectedKey
        }
    }
}

struct SelectScaleTypeView: View {
    @Binding var selectedScaleType:ScaleType
    @State var hiliteType:ScaleType? = nil

    var scaleTypes:[ScaleType] = ScaleType.getAllTypes()

    var body: some View {
        Text("Scale \(selectedScaleType.getName())").font(.title).padding()
        List {
            ForEach(scaleTypes, id: \.id) { scaleType in
                Text(scaleType.getName())
                    .foregroundColor(.black)
                    .background(scaleType == hiliteType ? Color.teal : Color.clear)
                    .onTapGesture {
                        DispatchQueue.main.async {
                            self.selectedScaleType = scaleType
                            self.hiliteType = scaleType
                        }
                    }
            }
        }
        .onAppear() {
            hiliteType = selectedScaleType
        }
    }
}

struct SelectScaleView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var model:ScalesAppModel
    var oldKey:Key
    var oldType:ScaleType

    init(model:ScalesAppModel) {
        self.model = model
        oldKey = model.key
        oldType = model.scaleType
    }
    
    var body: some View {
        VStack {
            VStack {
                SelectKeyView(selectedKey: $model.key)
            }
            VStack {
                SelectScaleTypeView(selectedScaleType: $model.scaleType)
            }
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                    let scaleType = model.scaleType
                    let key = model.key
                    model.setScale(key: key, scaleType: scaleType)
                    model.reset()
                }) {
                    HStack {
                        Text("Ok")
                    }
                }
                .padding()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                    model.key = oldKey
                    model.scaleType = oldType
                }) {
                    HStack {
                        Text("Cancel")
                    }
                }
                .padding()
            }
        }

    }
}

