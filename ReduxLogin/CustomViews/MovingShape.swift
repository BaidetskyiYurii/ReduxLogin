//
//  MovingShape.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 20.07.2024.
//

import SwiftUI

struct MovingShape: View {
    private var color: Color
    private var startX: CGFloat
    private var startY: CGFloat
    private var endX: CGFloat
    private var endY: CGFloat
    private var animationDuration: Double
    
    @State private var currentX: CGFloat
    @State private var currentY: CGFloat
    
    init(color: Color, 
         startX: CGFloat,
         startY: CGFloat,
         endX: CGFloat,
         endY: CGFloat,
         animationDuration: Double) {
        self.color = color
        self.startX = startX
        self.startY = startY
        self.endX = endX
        self.endY = endY
        self.animationDuration = animationDuration
        self._currentX = State(initialValue: startX)
        self._currentY = State(initialValue: startY)
    }
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 200, height: 200)
            .offset(x: currentX, y: currentY)
            .onAppear() {
                withAnimation(Animation.linear(duration: animationDuration).repeatForever(autoreverses: true)) {
                    currentX = endX
                    currentY = endY
                }
            }
    }
}
