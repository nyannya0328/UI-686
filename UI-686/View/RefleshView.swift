//
//  RefleshView.swift
//  UI-686
//
//  Created by nyannyan0328 on 2022/10/01.
//

import SwiftUI

struct RefleshView<Content : View>: View {
    
    var content : Content
    
    var showIndicator : Bool = false
    
    var onReflesh : ()async->()
    
    init(showIndicator: Bool,@ViewBuilder content : @escaping()->Content,  onReflesh: @escaping ()async -> ()) {
        self.content = content()
        self.showIndicator = showIndicator
        self.onReflesh = onReflesh
    }
    
    
    
    @StateObject var model : ScrolDelegate = .init()
    var body: some View {
        ScrollView(.vertical,showsIndicators: showIndicator){
            
            
            VStack(spacing:0){
                
                Rectangle()
                    .fill(.clear)
                    .frame(height: 150 * model.progress )
                
                content
            }
            .offset(coordinateSpace: "SCROLLER") { offset in
                model.contentOffset = offset
                if !model.isEligible{
                    
                  
                    
                    var progress = offset / 150
                    
                    progress = (progress < 0 ? 0 : progress)
                    progress = (progress > 1 ? 1 : progress)
                    
                    model.scrollOffset = offset
                    model.progress = progress
                    
                }
                
                if model.isEligible && !model.isRefleshing{
                    
                    model.isRefleshing = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                
                
            }
            
            
            
        }
        .overlay(alignment: .top) {
            
            ZStack{
                
                Capsule()
                    .fill(.red)
                
            }
             .frame(width: 126,height: 37)
             .offset(y:11)
             .frame(maxHeight: .infinity,alignment: .top)
             .overlay(alignment: .top) {
             
                 Canvas { context, size in
                     
                     context.addFilter(.alphaThreshold(min: 0.5,color: .black))
                     context.addFilter(.blur(radius: 10))
                     
                     context.drawLayer { cxt in
                         
                         for index in [1,2]{
                             
                             if let resovedImage = context.resolveSymbol(id: index){
                                 
                                 cxt.draw(resovedImage, at: CGPoint(x: size.width / 2, y: 30))
                             }
                             
                             
                         }
                     }
                     
                 } symbols: {
                     CanavasSymbol()
                         .tag(1)
                     
                     CanavasSymbol(isCircle: true)
                         .tag(2)
                     
                     
                     
                 }
                 .allowsHitTesting(false)
                 
                 

                 
                 
             }
             .overlay(alignment: .top) {
                 
                 RefleshView()
                     .offset(y:11)
             }
             .ignoresSafeArea()
            
        }
        .coordinateSpace(name: "SCROLLER")
        .onAppear{model.addGesture()}
        .onDisappear{model.removeGesture()}
        .onChange(of: model.isRefleshing) { newValue in
            
            if newValue{
                
                Task{
                    
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await onReflesh()
                    withAnimation(.easeOut(duration: 0.3)){
                        
                        model.progress = 0
                        model.isEligible = false
                        model.isRefleshing = false
                        model.scrollOffset = 0
                    }
                    
                }
            }
            
        }
    }
    @ViewBuilder
    func RefleshView ()->some View{
        
        let conterOffset = model.isEligible ? (model.contentOffset > 95 ? model.contentOffset : 95) : model.scrollOffset
        
        let offset = model.scrollOffset > 0 ? conterOffset : 0
        
        ZStack{
            
            
             Image(systemName: "arrow.down")
                .font(.callout.bold())
                .foregroundColor(.white)
             .frame(width: 38,height: 38)
                .rotationEffect(.init(degrees: model.progress * 180))
                .opacity(model.isEligible ? 0 : 1)
            
            ProgressView()
                .tint(.white)
             .frame(width:30 ,height:30 )
             .opacity(model.isEligible ? 1 : 0)
        }
        .animation(.easeIn(duration: 0.3), value: model.isEligible)
        .opacity(model.progress)
        .offset(y:offset)
    
        
        
    }
    @ViewBuilder
    func CanavasSymbol(isCircle : Bool = false)-> some View{
        
        
        if isCircle{
            
            let conterOffset = model.isEligible ? (model.contentOffset > 95 ? model.contentOffset : 95) : model.scrollOffset
            
            let offset = model.scrollOffset > 0 ? conterOffset : 0
            
            let scaling = ((model.progress / 1) * 0.21)
            
            
         Circle()
            .fill(.black)
             .frame(width: 47,height: 47)
             .scaleEffect(0.79 + scaling,anchor: .center)
             .offset(y:offset)
            
            
            
        }
        else{
            
            Capsule()
             .fill(.black)
             .frame(width: 126,height: 37)
        }
        
        
    }
}

struct RefleshView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class ScrolDelegate : NSObject,ObservableObject,UIGestureRecognizerDelegate{
    
    @Published var isEligible : Bool = false
    @Published var isRefleshing : Bool = false
    
    @Published var scrollOffset : CGFloat = 0
    @Published var contentOffset : CGFloat = 0
    @Published var progress : CGFloat = 0
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
    
    func addGesture(){
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onGestureChange(gesture:)))
        
        panGesture.delegate = self
        
        getRoot().view.addGestureRecognizer(panGesture)
        
    }
    
    func removeGesture(){
        
        
        getRoot().view.gestureRecognizers?.removeAll()
    }
    
    @objc
    func onGestureChange(gesture : UIPanGestureRecognizer){
        
        if gesture.state == .cancelled || gesture.state == .ended{
            
            if !isRefleshing{
                
                if scrollOffset > 150{
                    
                    isEligible = true
                }
                else{
                    
                    isEligible = false
                }
                
            }
        }
        
        
    }
    
}


extension View{
    
    @ViewBuilder
    func offset(coordinateSpace : String, offset : @escaping(CGFloat)->()) -> some View{
        
        self
            .overlay {
            
                GeometryReader{proxy in
                        
                    let rect = proxy.frame(in: .named(coordinateSpace)).minY
                
                    Color.clear
                        .preference(key:OffsetKey.self, value: rect)
                        .onPreferenceChange(OffsetKey.self) { value in
                            
                            offset(value)
                        }
                }
            }
        
    }
    
}

func getRoot()->UIViewController{
    
    guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else{return .init()}
    
    guard let root = screen.windows.first?.rootViewController else{return .init()}
    
    return root
}

struct OffsetKey : PreferenceKey{
    
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
