import SwiftUI
import CommonLibrary
import Combine
import Foundation

struct SelectKeyView: View {
    @ObservedObject var model:ScalesAppModel
    @Binding var selectedKey:Key
    @State var hiliteKey:Key? = nil

    func getKeyName() -> String {
        return selectedKey.getKeyName(withType: false)
    }
    
    var body: some View {
        VStack {
            Text("\(getKeyName())").font(.title).padding()
            HStack {
                List {
                    ForEach(model.sharpKeys, id: \.id) { key in
                        HStack {
                            Text(key.getKeyName(withType: false))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) // Make HStack fill the row
                        .contentShape(Rectangle())
                        .onTapGesture {
                            DispatchQueue.main.async {
                                self.selectedKey = key
                                self.hiliteKey = key
                            }
                        }
                        .background(key == hiliteKey ? Color.teal : Color.clear)
                    }
                }
                List {
                    ForEach(model.flatKeys, id: \.id) { key in
                        HStack {
                            Text(key.getKeyName(withType: false))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) // Make HStack fill the row
                        .contentShape(Rectangle())
                        .onTapGesture {
                            DispatchQueue.main.async {
                                self.selectedKey = key
                                self.hiliteKey = key
                            }
                        }
                        .background(key == hiliteKey ? Color.teal : Color.clear)
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
    @ObservedObject var model:ScalesAppModel
    @Binding var selectedScaleType:ScaleType
    @State var hiliteType:ScaleType? = nil
    
    func getHilight(_ sType:ScaleType) -> Bool {
        if let hil = self.hiliteType {
            return hil.idx == sType.idx
        }
        else {
            return false
        }
    }
    
    var body: some View {
        Text("Scale \(selectedScaleType.getName())").font(.title).padding()
        List {
            ForEach(model.scaleTypes, id: \.id) { scaleType in
                HStack {
                    Text(scaleType.getName())
                        .foregroundColor(.black)
                    Spacer()
                }
                .background(getHilight(scaleType) ? Color.teal : Color.clear)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) // Make HStack fill the row
                .contentShape(Rectangle())
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
                SelectKeyView(model: model, selectedKey: $model.key)
            }
            VStack {
                SelectScaleTypeView(model: model, selectedScaleType: $model.scaleType)
            }
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                    let scaleType = model.scaleType
                    let key = model.key
                    model.setScale(key: key, scaleType: scaleType)
                    //model.setAllKeysUnPressed()
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

