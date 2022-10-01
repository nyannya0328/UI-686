//
//  ContentView.swift
//  UI-686
//
//  Created by nyannyan0328 on 2022/10/01.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RefleshView(showIndicator: false) {
            
            VStack(spacing: 20) {
                
                Rectangle()
                    .fill(.red)
                    .frame(height: 150)
                
                Rectangle()
                    .fill(.blue)
                    .frame(height: 150)
                
                
            }
            .padding(15)
            
        } onReflesh: {
            
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
