import SwiftUI

struct MenuView: View {
    
    // Animation states
    @State private var showPieces = false
    @State private var showMenuContent = false
    @State private var floatOffset1: CGFloat = 0
    @State private var floatOffset2: CGFloat = 0
    @State private var rotation1: Double = 0
    @State private var rotation2: Double = 0
    
    var body: some View {
        ZStack {
            // Background color
            Color.white.ignoresSafeArea()
            
            // Animated background chess pieces
            Text("♖ ♗ ♔ ♕ ♘ ♙")
                .font(.system(size: 700))
                .foregroundColor(.gray.opacity(0.2))
                .rotationEffect(.degrees(-15 + rotation1))
                .offset(x: showPieces ? -130 : -300,
                        y: showPieces ? -250 + floatOffset1 : -400)
                .opacity(showPieces ? 1 : 0)
                .animation(.easeOut(duration: 1.2).delay(0.2), value: showPieces)
            
            Text("♞ ♚ ♛ ♜ ♝")
                .font(.system(size: 700))
                .foregroundColor(.gray.opacity(0.2))
                .rotationEffect(.degrees(10 + rotation2))
                .offset(x: showPieces ? 120 : 300,
                        y: showPieces ? 200 + floatOffset2 : 400)
                .opacity(showPieces ? 1 : 0)
                .animation(.easeOut(duration: 1.2).delay(0.4), value: showPieces)
            
            // Title only (fade-in)
            Text("Voice Chess")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.black)
                .opacity(showMenuContent ? 1 : 0)
                .animation(.easeIn(duration: 0.5).delay(1), value: showMenuContent)
        }
        .onAppear {
            // Trigger initial fade-in
            showPieces = true
            showMenuContent = true
            
            // Start infinite floating/rotation animation
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                floatOffset1 = 20
                rotation1 = 3
            }
            
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatOffset2 = -20
                rotation2 = -3
            }
        }
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
