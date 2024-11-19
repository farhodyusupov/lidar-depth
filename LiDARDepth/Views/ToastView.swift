//
//  ToastView.swift
//  LiDARDepth
//
//  Created by Farkhod on 11/18/24.
//  Copyright © 2024 Apple. All rights reserved.
//


//
//  ToastView.swift
//  LiDARDepth
//
//  Created by 윤소희 on 11/15/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14))
            .padding()
            .background(Color.black.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal, 20)
    }
}

struct ToastModifier: ViewModifier {
    let message: String
    let duration: TimeInterval
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                ToastView(message: message)
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    }
            }
        }
    }
}