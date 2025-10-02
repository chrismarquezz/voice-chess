import SwiftUI

struct RootView: View {
    @State private var showMainTabs = false
    @State private var animateFade = false
    
    let splashDuration: Double = 3.0
    
    var body: some View {
        ZStack {
            if showMainTabs {
                TabView {
                    // Play tab
                    PlayView()
                        .tabItem {
                            Label("Play", systemImage: "gamecontroller")
                        }
                    // Profile tab
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                }
                .transition(.opacity)
                .ignoresSafeArea()
                
            } else {
                LoadingView()
                    .transition(.opacity)
                    .opacity(animateFade ? 0 : 1)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + splashDuration) {
                withAnimation(.easeOut(duration: 1.0)) {
                    animateFade = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showMainTabs = true
                }
            }
        }
    }
}

#Preview {
    RootView()
}
