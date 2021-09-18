//
//  ContentView.swift
//  PowerfulVirtualBackground
//
//  Created by Toshiki Tomihira on 2021/09/18.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \BackgroundImage.timestamp, ascending: true)],
            animation: .default)
    private var images: FetchedResults<BackgroundImage>
    
    var body: some View {
        VStack(spacing: 16) {
            CameraView()
            Spacer()
            .frame(maxHeight: 20)
            ImageCollectionView(images: images, tappedAdd: {
                if let img = selectImage() {
                    addItem(img)
                }
            }, tappedDelete: { item in
                deleteItem(item)
            })
        }.frame(width: 640, height: 600, alignment: .center)
    }
    
    private func selectImage() -> NSImage? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            return NSImage(contentsOf: url)
        }
        return nil
    }
    
    private func addItem(_ image: NSImage) {
        withAnimation {
            let newItem = BackgroundImage(context: viewContext)
            newItem.timestamp = Date()
            newItem.image = image.tiffRepresentation
            try? viewContext.save()
        }
    }
    
    private func deleteItem(_ item: BackgroundImage) {
        withAnimation {
            viewContext.delete(item)
            try? viewContext.save()
        }
    }
}

struct CameraView: View {
    var body: some View {
        ZStack {
            cameraPreview().animation(.spring())
        }
        .frame(height: 320)
        .cornerRadius(8)
    }
    
    func cameraPreview() -> AnyView {
        if Config.useVirtualCamera, let cameraDevice = AVCaptureDevice.init(uniqueID: "Powerfull Virtual Background Device") {
            return AnyView(CameraPreview(captureDevice: cameraDevice)
            .frame(width: 640, height: 360))
        }
        if !Config.useVirtualCamera, let cameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
            return AnyView(CameraPreview(captureDevice: cameraDevice)
            .frame(width: 640, height: 360))
        }
        return AnyView(Text("No camera")
        .frame(width: 320)
        .background(Color.black.opacity(0.5)))
    }
}

struct ImageCollectionView: View {
    var images: FetchedResults<BackgroundImage>
    var tappedAdd: ()->Void
    var tappedDelete: (BackgroundImage)->Void
    let columns: [GridItem] = [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 15)]
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, alignment: .center, spacing: 15) {
                ForEach(images, id: \BackgroundImage.self) { item in
                    ZStack(alignment: .topTrailing) {
                        let img = NSImage(data: item.image!)!
                        Image(nsImage: img)
                            .resizable()
                            .frame(width: 180, height: 100)
                            .aspectRatio(1, contentMode: .fill)
                            .cornerRadius(8)
                        ZStack {
                            Rectangle().foregroundColor(.red)
                                .cornerRadius(30)
                                .frame(width: 15, height: 15)
                                .padding(4)
                            Text("×")
                                .foregroundColor(.white)
                                .padding(.bottom, 2)
                        }.onTapGesture {
                            tappedDelete(item)
                        }
                    }
                }
                ZStack {
                    Rectangle().foregroundColor(.white)
                        .frame(width: 180, height: 100)
                        .cornerRadius(8)
                    Text("+").foregroundColor(.black)
                }.onTapGesture {
                    tappedAdd()
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
