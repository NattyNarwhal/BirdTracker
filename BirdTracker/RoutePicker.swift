//
//  RoutePicker.swift
//  BirdTracker
//
//  Created by Calvin Buckley on 2025-09-12.
//

import SwiftUI
import AVKit

#if os(iOS)
struct RoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let rpv = AVRoutePickerView()
        rpv.delegate = context.coordinator
        return rpv
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
    }
    
    typealias UIViewType = AVRoutePickerView
    
    class Coordinator: NSObject, AVRoutePickerViewDelegate {
        func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        }
        
        func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
}
#endif
