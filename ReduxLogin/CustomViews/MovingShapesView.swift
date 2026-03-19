//
//  MovingShapesView.swift
//  ReduxLogin
//
//  Created by Baidetskyi Yurii on 20.07.2024.
//

import SwiftUI

struct MovingShapesView: View {
    var body: some View {
        ZStack {
            MovingShape(color: .blue.opacity(0.6), 
                        startX: -350, startY: 50,
                        endX: 450,
                        endY: 500,
                        animationDuration: 4.0)
            MovingShape(color: .yellow.opacity(0.6), 
                        startX: 100,
                        startY: -650,
                        endX: -100,
                        endY: 550,
                        animationDuration: 3.0)
            MovingShape(color: .pink.opacity(0.4), 
                        startX: 150,
                        startY: -600,
                        endX: -250,
                        endY: 0,
                        animationDuration: 5.0)
        }
        .blur(radius: 50)
    }
}

#Preview {
    MovingShapesView()
}
