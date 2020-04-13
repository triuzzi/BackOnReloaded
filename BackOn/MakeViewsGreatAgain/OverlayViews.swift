//
//  OverlayView.swift
//  BackOn
//
//  Created by Vincenzo Riccio on 19/02/2020.
//  Copyright © 2020 Riccio Vincenzo, Sorrentino Giancarlo, Triuzzi Emanuele, Zanfardino Gennaro. All rights reserved.
//

import Foundation
import SwiftUI
import MapKit


struct myOverlay: View {
    @Binding var isPresented: Bool
    let opacity: Double = 0.6
    let alignment: Alignment = .bottom
    let toOverlay: AnyView
    
    var body: some View {
        VStack {
            if self.isPresented {
                Color
                    .black
                    .opacity(opacity)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture{withAnimation{self.isPresented = false}}
                    .overlay(toOverlay, alignment: alignment)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .animation(.easeInOut)
            } else {
                EmptyView()
                    .animation(.easeInOut)
            }
        }
    }
}

struct SheetView<Content: View>: View {
    let radius: CGFloat = 16
    let indicatorHeight: CGFloat = 6
    let indicatorWidth: CGFloat = 60
    let snapRatio: CGFloat = 0.40
    let minHeightRatio: CGFloat = 0.3
    
    @Binding var isOpen: Bool
    let maxHeight: CGFloat
    let minHeight: CGFloat
    let content: Content
    
    @GestureState private var translation: CGFloat = 0
    
    private var offset: CGFloat {
        isOpen ? 0 : maxHeight - minHeight
    }
    
    private var indicator: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Color.secondary)
            .frame(width: indicatorWidth, height: indicatorHeight)
            .onTapGesture{self.isOpen.toggle()}
    }
    
    init(isOpen: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.minHeight = 0 //invece di mostrarla chiusa, la spinge fuori dallo schermo
        self.maxHeight = UIScreen.main.bounds.height - 450 //valore da cambiare
        self.content = content()
        self._isOpen = isOpen
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.content
                .frame(width: geometry.size.width, height: self.maxHeight, alignment: .top)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(self.radius)
                .frame(height: geometry.size.height, alignment: .bottom)
                .offset(y: max(self.offset + self.translation, 0))
                .animation(.interactiveSpring(response:  0.45, dampingFraction:  0.86, blendDuration:  0.7))
                .gesture(
                    DragGesture().updating(self.$translation) { value, state, _ in
                        state = value.translation.height
                    }.onEnded { value in
                        let snapDistance = self.maxHeight * self.snapRatio
                        guard abs(value.translation.height) > snapDistance else {return}
                        self.isOpen = value.translation.height < 0
                        if !self.isOpen {
                            (UIApplication.shared.delegate as! AppDelegate).discoverTabController.closeSheet()
                        }
                    }
                )
        }.edgesIgnoringSafeArea(.bottom)
    }
}
