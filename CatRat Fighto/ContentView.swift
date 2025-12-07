


import SwiftUI
import AVFoundation

struct Room: Identifiable {
    let id: Int
    let name: String
    var containsRat: Bool = false
    var isHighlighted: Bool = false
    var position: CGPoint
    var connectedRooms: [Int]
    var doors: [Door]
}

struct Door: Hashable {
    let fromRoom: Int
    let toRoom: Int
    let position: CGPoint
    let isHorizontal: Bool
    
    func hash(into hasher: inout Hasher) {
        let sortedRooms = [fromRoom, toRoom].sorted()
        hasher.combine(sortedRooms[0])
        hasher.combine(sortedRooms[1])
    }
    
    static func == (lhs: Door, rhs: Door) -> Bool {
        let lhsSorted = [lhs.fromRoom, lhs.toRoom].sorted()
        let rhsSorted = [rhs.fromRoom, rhs.toRoom].sorted()
        return lhsSorted == rhsSorted
    }
}

struct GameLevel: Identifiable {
    let id: Int
    let name: String
    let rooms: [Room]
    let catStartPosition: CGPoint
    let ratRoom: Int
    let basePoints: Int
    let description: String
    let optimalPathLength: Int
    let timeLimit: Int // Time in seconds
}


struct SplashScreenContainerView: View {
    @State private var showContentView = false
    
    var body: some View {
        Group {
            if showContentView {
                ContentView()
            } else {
                SplashScreenView(showContentView: $showContentView)
            }
        }
    }
}

struct SplashScreenView: View {
    @Binding var showContentView: Bool
    @State private var isAnimating = false
    @State private var catPosition = CGPoint(x: 0.2, y: 0.5)
    @State private var ratPosition = CGPoint(x: 0.8, y: 0.5)
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var showTitle = false
    @State private var titleScale: CGFloat = 0.1
    @State private var pawPrints: [PawPrint] = []
    
    struct PawPrint: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        var opacity: Double
        let scale: CGFloat
    }
    
    var body: some View {
        ZStack {
            
            // Background gradient
            GeometryReader { geometry in
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.5)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()
            }
            .ignoresSafeArea()
            
            // Stars in background
            ForEach(0..<50) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .opacity(Double.random(in: 0.3...0.8))
                    .blur(radius: 1)
            }
            
            // Paw prints effect
            ForEach(pawPrints) { paw in
                Image(systemName: "pawprint.fill")
                    .foregroundColor(.white.opacity(0.1))
                    .font(.system(size: 20))
                    .position(x: paw.x, y: paw.y)
                    .scaleEffect(paw.scale)
                    .opacity(paw.opacity)
                    .animation(.easeOut(duration: 1), value: paw.opacity)
            }
            
            // Main fight scene
            ZStack {
                // Dust clouds
                ForEach(0..<5) { i in
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100 + CGFloat(i) * 20)
                        .position(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height * 0.5)
                        .scaleEffect(isAnimating ? 1.5 : 1.0)
                        .opacity(isAnimating ? 0 : 0.3)
                        .animation(
                            Animation.easeOut(duration: 1)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.1),
                            value: isAnimating
                        )
                }
                
                // Cat with fighting animation
                Image("cat")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .position(catPosition)
                    .rotationEffect(.degrees(isAnimating ? -10 : 10))
                    .animation(
                        Animation.easeInOut(duration: 0.15)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                    .shadow(color: .blue.opacity(0.5), radius: 10)
                    .scaleEffect(scale)
                
                // Cat's claws
                ForEach(0..<3) { i in
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 20))
                        .position(
                            x: catPosition.x + CGFloat(i) * 15 - 15,
                            y: catPosition.y - 40
                        )
                        .rotationEffect(.degrees(45))
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1.5 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.1),
                            value: isAnimating
                        )
                }
                
                // Rat with fighting animation
                Image("rat")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .position(ratPosition)
                    .rotationEffect(.degrees(isAnimating ? 10 : -10))
                    .animation(
                        Animation.easeInOut(duration: 0.15)
                            .repeatForever(autoreverses: true)
                            .delay(0.05),
                        value: isAnimating
                    )
                    .shadow(color: .red.opacity(0.5), radius: 10)
                    .scaleEffect(scale)
                
                // Rat's teeth
                ForEach(0..<3) { i in
                    Image(systemName: "triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 15))
                        .position(
                            x: ratPosition.x + CGFloat(i) * 10 - 10,
                            y: ratPosition.y - 35
                        )
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1.3 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.1 + 0.05),
                            value: isAnimating
                        )
                }
                
                // Fight collision effects
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.orange.opacity(0.5), .clear]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .position(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height * 0.5)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 0.5 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 0.25)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Sparks
                ForEach(0..<8) { i in
                    Image(systemName: "sparkle")
                        .foregroundColor([.yellow, .orange, .red].randomElement()!)
                        .font(.system(size: 15))
                        .position(
                            x: UIScreen.main.bounds.width * 0.5 + CGFloat.random(in: -40...40),
                            y: UIScreen.main.bounds.height * 0.5 + CGFloat.random(in: -40...40)
                        )
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1.5 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.1),
                            value: isAnimating
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Game title with animation
            VStack {
              
                if showTitle {
                    VStack(spacing: 10) {
                        Text("CatRat Fighto")
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .blue, radius: 20)
                            .scaleEffect(titleScale)
                        
                        Text("THE GREAT CHASE")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(3)
                            .scaleEffect(titleScale)
                            .opacity(titleScale)
                    }
                }
                
                // Loading indicator
                HStack(spacing: 10) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .scaleEffect(isAnimating ? 1.2 : 0.8)
                            .opacity(isAnimating ? 1 : 0.3)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Start animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1
                catPosition = CGPoint(x: UIScreen.main.bounds.width * 0.35, y: UIScreen.main.bounds.height * 0.5)
                ratPosition = CGPoint(x: UIScreen.main.bounds.width * 0.65, y: UIScreen.main.bounds.height * 0.5)
            }
            
            // Start fighting animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isAnimating = true
                
                // Generate paw prints
                for _ in 0..<20 {
                    pawPrints.append(PawPrint(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                        opacity: 0.3,
                        scale: CGFloat.random(in: 0.5...1.5)
                    ))
                }
                
                // Fade out paw prints
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 1)) {
                        for i in pawPrints.indices {
                            pawPrints[i].opacity = 0
                        }
                    }
                }
            }
            
            // Show title
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showTitle = true
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    titleScale = 1.0
                }
            }
            
            // Transition to ContentView after 3.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showContentView = true
                }
            }
        }
    }
}


struct ContentView: View {
    @StateObject private var gameController = GameController()
    @State private var isAnimating = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                GeometryReader { geometry in
                    Image("background")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.5)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .ignoresSafeArea()
                }
                .ignoresSafeArea()
                
    
                VStack(spacing: 0) {
                    
                    
                    ScrollView {
                        VStack {
                            
                            // Top icons - settings and info
                            HStack {
                                NavigationLink(destination: HowToPlayView()) {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: "info.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.white)
                                                .shadow(color: .blue, radius: 5)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 2
                                                )
                                        )
                                }
                                
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 40)
                            
                            Spacer()
                            
                            // Centered logo and app name with animation
                            VStack(spacing: 20) {
                                HStack(spacing: 15) {
                                    Image("cat")
                                        .resizable()
                                        .frame(width: 70, height: 70)
                                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                                        .animation(
                                            Animation.linear(duration: 20)
                                                .repeatForever(autoreverses: false),
                                            value: isAnimating
                                        )
                                        .shadow(color: .blue, radius: 10)
                                    
                                    VStack(spacing: 5) {
                                        Text("CatRat Fighto")
                                            .font(.system(size: 48, weight: .black, design: .rounded))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .shadow(color: .yellow, radius: 15)
                                            .scaleEffect(isAnimating ? 1.05 : 1.0)
                                            .animation(
                                                Animation.easeInOut(duration: 1.5)
                                                    .repeatForever(autoreverses: true),
                                                value: isAnimating
                                            )
                                        
                                        Text("THE GREAT CHASE")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.8))
                                            .tracking(1.5)
                                    }
                                    
                                    Image("rat")
                                        .resizable()
                                        .frame(width: 70, height: 70)
                                        .rotationEffect(.degrees(isAnimating ? -360 : 0))
                                        .animation(
                                            Animation.linear(duration: 20)
                                                .repeatForever(autoreverses: false),
                                            value: isAnimating
                                        )
                                        .shadow(color: .red, radius: 10)
                                }
                                
                                // Play button - Center of the screen
                                NavigationLink(destination: GameView().environmentObject(gameController)) {
                                    ZStack {
                                        // Glowing effect
                                        Circle()
                                            .fill(Color.yellow)
                                            .frame(width: 120, height: 120)
                                            .blur(radius: 20)
                                            .opacity(0.4)
                                            .scaleEffect(isAnimating ? 1.1 : 0.9)
                                            .animation(
                                                Animation.easeInOut(duration: 1.2)
                                                    .repeatForever(autoreverses: true),
                                                value: isAnimating
                                            )
                                        
                                        // Main button
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.yellow, .orange],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 100, height: 100)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 4)
                                                    .shadow(color: .yellow, radius: 10)
                                            )
                                        
                                        VStack(spacing: 5) {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 3)
                                            
                                            Text("PLAY")
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 2)
                                        }
                                    }
                                }
                                .padding(.top, 30)
                            }
                          
                            Spacer()
                            
                        }
                    }
                    
                    // Bottom navigation icons
                    HStack(spacing: 40) {
                        // Levels button
                        NavigationLink(destination: LevelSelectionView().environmentObject(gameController)) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 70, height: 70)
                                    
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 3
                                        )
                                        .frame(width: 70, height: 70)
                                    
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                        .shadow(color: .blue, radius: 5)
                                }
                                
                                Text("LEVELS")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        
                        // Score display redesign
                        VStack(spacing: 8) {
                            ZStack {
                                // Score card background
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 150, height: 70)
                                
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.yellow.opacity(0.8), .orange.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 3
                                    )
                                    .frame(width: 150, height: 70)
                                
                                HStack(spacing: 15) {
                                    Image(systemName: "trophy.fill")
                                        .font(.title2)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.yellow, .orange],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                                        .animation(
                                            Animation.easeInOut(duration: 0.8)
                                                .repeatForever(autoreverses: true),
                                            value: isAnimating
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("SCORE")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        Text("\(gameController.totalScore)")
                                            .font(.system(size: 28, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .shadow(color: .yellow.opacity(0.5), radius: 5)
                                    }
                                }
                                .padding(.horizontal, 15)
                            }
                            
                            Text("TOTAL")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 2)
                        }
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                
                
            }
            .onAppear {
                isAnimating = true
            }
        }
    }
}

struct MenuCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let isAnimating: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.white)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
        .padding(25)
        .background(
            LinearGradient(
                gradient: Gradient(colors: gradient),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: gradient[0].opacity(0.5), radius: 20, x: 0, y: 10)
        .scaleEffect(isAnimating ? 1.02 : 1.0)
        .animation(
            Animation.easeInOut(duration: 2)
                .repeatForever(autoreverses: true),
            value: isAnimating
        )
    }
}

struct StarsBackground: View {
    @State private var stars: [Star] = []
    
    struct Star {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
        let speed: Double
    }
    
    init() {
        for _ in 0..<50 {
            stars.append(Star(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                size: CGFloat.random(in: 1...3),
                opacity: Double.random(in: 0.1...1),
                speed: Double.random(in: 0.5...2)
            ))
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<stars.count, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: stars[index].size, height: stars[index].size)
                    .position(
                        x: stars[index].x * geometry.size.width,
                        y: stars[index].y * geometry.size.height
                    )
                    .opacity(stars[index].opacity)
                    .blur(radius: 1)
            }
        }
        .ignoresSafeArea()
    }
}

struct LevelSelectionView: View {
    @EnvironmentObject var gameController: GameController
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            
            GeometryReader { geometry in
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.5)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()
            }
            .ignoresSafeArea()
            
            VStack {
                // Animated header
                HStack {
                    Image("cat")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 20)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    Text("SELECT LEVEL")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .blue, radius: 10)
                    
                    Image("rat")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(isAnimating ? -360 : 0))
                        .animation(
                            Animation.linear(duration: 20)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
                .padding(.top, 20)
                .padding(.bottom, 8)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(gameController.levels) { level in
                            LevelCardView(level: level, isLocked: level.id > gameController.unlockedLevels)
                                .overlay(
                                    NavigationLink(
                                        destination: GameView().environmentObject(gameController),
                                        label: { EmptyView() }
                                    ).opacity(level.id <= gameController.unlockedLevels ? 1 : 0)
                                )
                                .simultaneousGesture(
                                    TapGesture().onEnded {
                                        if level.id <= gameController.unlockedLevels {
                                            gameController.currentLevel = level.id - 1
                                            gameController.setupLevel()
                                        }
                                    }
                                )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: CustomBackButton())
        .onAppear { isAnimating = true }
    }
}

struct LevelCardView: View {
    let level: GameLevel
    let isLocked: Bool
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background with gradient
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: isLocked ?
                            [Color.gray.opacity(0.3), Color.gray.opacity(0.1)] :
                            [Color.blue.opacity(0.4), Color.purple.opacity(0.2)]
                        ),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(
                            isLocked ? Color.gray : Color.blue,
                            lineWidth: 2
                        )
                        .shadow(color: isLocked ? .clear : .blue.opacity(0.5), radius: 10)
                )
            
            VStack(spacing: 12) {
                // Level number with badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: isLocked ?
                                    [Color.gray, Color.black.opacity(0.5)] :
                                    [Color.yellow, Color.orange]
                                ),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: isLocked ? .clear : .yellow, radius: 5)
                    
                    Text("\(level.id)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                
                // Level name
                Text(level.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isLocked ? .gray : .white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Time limit
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(isLocked ? .gray : .orange)
                    
                    Text("\(level.timeLimit / 60):\(String(format: "%02d", level.timeLimit % 60))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isLocked ? .gray : .orange)
                }
                
                // Points
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(isLocked ? .gray : .yellow)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    Text("\(level.basePoints) pts")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isLocked ? .gray : .yellow)
                }
                
                // Lock or play indicator
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                        .shadow(color: .green, radius: 5)
                }
            }
            .padding()
        }
        .opacity(isLocked ? 0.7 : 1)
        .scaleEffect(isAnimating ? 1.02 : 1.0)
        .animation(
            Animation.easeInOut(duration: 2)
                .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear { isAnimating = true }
    }
}

struct GameView: View {
    @EnvironmentObject var gameController: GameController
    @Environment(\.dismiss) var dismiss
    @State private var showRatCaughtAnimation = false
    @State private var showGameCompleteCelebration = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Game background
            GeometryReader { geometry in
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.5)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Game header with stats
                GameHeaderView()
                    .environmentObject(gameController)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // Game board area with zoom and scroll
                GeometryReader { geometry in
                    let boardWidth = max(geometry.size.width, 1000)
                    let boardHeight = max(geometry.size.height, 1000)
                    
                    ScrollView([.horizontal, .vertical], showsIndicators: false) {
                        ZStack {
                            // Background for the game board
                            Color.clear
                                .frame(width: boardWidth, height: boardHeight)
                            
                            // Draw corridors with glow effect
                            ForEach(gameController.currentDoors, id: \.self) { door in
                                let fromRoom = gameController.getRoom(by: door.fromRoom)
                                let toRoom = gameController.getRoom(by: door.toRoom)
                                
                                Path { path in
                                    path.move(to: CGPoint(
                                        x: fromRoom.position.x * boardWidth,
                                        y: fromRoom.position.y * boardHeight
                                    ))
                                    path.addLine(to: CGPoint(
                                        x: toRoom.position.x * boardWidth,
                                        y: toRoom.position.y * boardHeight
                                    ))
                                }
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.brown.opacity(0.8), .orange.opacity(0.6)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 6
                                )
                                .shadow(color: .orange.opacity(0.3), radius: 5)
                            }
                            
                            // Draw rooms
                            ForEach(gameController.currentRooms) { room in
                                EnhancedRoomView(room: room)
                                    .position(
                                        x: room.position.x * boardWidth,
                                        y: room.position.y * boardHeight
                                    )
                            }
                            
                            // Draw cat with shadow
                            Image("cat")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                                .position(
                                    x: gameController.catPosition.x * boardWidth,
                                    y: gameController.catPosition.y * boardHeight
                                )
                            
                            // Draw rat if not caught
                            if !gameController.ratCaught, let ratRoom = gameController.currentRooms.first(where: { $0.containsRat }) {
                                Image("rat")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .shadow(color: .gray.opacity(0.5), radius: 5)
                                    .position(
                                        x: ratRoom.position.x * boardWidth,
                                        y: ratRoom.position.y * boardHeight
                                    )
                                    .scaleEffect(gameController.isRatVisible ? 1.0 : 0.8)
                                    .opacity(gameController.isRatVisible ? 1.0 : 0.5)
                                    .animation(
                                        Animation.easeInOut(duration: 0.5)
                                            .repeatForever(autoreverses: true),
                                        value: gameController.isRatVisible
                                    )
                            }
                        }
                        .frame(width: boardWidth, height: boardHeight)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 0.5), 3.0)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                    }
                }
                
                // Floating controls
                if !gameController.isGamePaused && !gameController.ratCaught && !gameController.showGameOver {
                    FloatingControlsView()
                        .environmentObject(gameController)
                        .padding(.vertical, 20)
                }
                
                // Messages display
                if !gameController.message.isEmpty {
                    GameMessageView(message: gameController.message)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
            }
            .blur(radius: gameController.isGamePaused ? 3 : 0)
            
            // Pause overlay
            if gameController.isGamePaused {
                PauseMenuView()
                    .environmentObject(gameController)
            }
            
            // Rat caught celebration
            if showRatCaughtAnimation {
                RatCaughtCelebration(
                    score: gameController.currentScore,
                    onNextLevel: {
                        gameController.nextLevel()
                        showRatCaughtAnimation = false
                    },
                    onMenu: {
                        dismiss()
                    },
                    isLastLevel: gameController.currentLevel == gameController.levels.count - 1
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if !showRatCaughtAnimation {
                            showRatCaughtAnimation = false
                        }
                    }
                }
            }
            
            // Game over overlay
            if gameController.showGameOver {
                GameOverView(
                    onRestart: {
                        gameController.resetGame()
                    },
                    onMenu: {
                        dismiss()
                    }
                )
            }
            
            // Game complete celebration
            if showGameCompleteCelebration {
                GameCompleteCelebration(
                    totalScore: gameController.totalScore,
                    onMenu: {
                        dismiss()
                    }
                )
            }
            
            // Zoom controls
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Button(action: {
                            withAnimation {
                                scale = min(scale + 0.2, 3.0)
                            }
                        }) {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.title2)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            withAnimation {
                                scale = max(scale - 0.2, 0.5)
                            }
                        }) {
                            Image(systemName: "minus.magnifyingglass")
                                .font(.title2)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            withAnimation {
                                scale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        }) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.title2)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: CustomBackButton())
        .onAppear {
            gameController.setupLevel()
        }
        .onChange(of: gameController.showLevelComplete) { oldValue, newValue in
            if newValue {
                showRatCaughtAnimation = true
                gameController.showLevelComplete = false
            }
        }
        .onChange(of: gameController.showGameComplete) { oldValue,newValue in
            if newValue {
                showGameCompleteCelebration = true
                gameController.showGameComplete = false
            }
        }
    }
}

struct TimerDisplayView: View {
    let timeRemaining: Int
    let totalTime: Int
    @State private var pulse = false
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .foregroundColor(timeColor)
                .font(.title3)
            
            Text(formatTime(timeRemaining))
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(timeColor)
                .frame(width: 80)
                .scaleEffect(pulse ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true),
                    value: pulse
                )
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(timeGradient)
                        .frame(width: progressWidth(in: geometry.size.width), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 20)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(timeColor.opacity(0.5), lineWidth: 2)
        )
        .onAppear {
            if timeRemaining <= 10 {
                pulse = true
            }
        }
        .onChange(of: timeRemaining) { oldValue,newValue in
            if newValue <= 10 {
                pulse = true
            } else {
                pulse = false
            }
        }
    }
    
    private var timeColor: Color {
        if timeRemaining <= 10 {
            return .red
        } else if timeRemaining <= 30 {
            return .orange
        } else {
            return .green
        }
    }
    
    private var timeGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                timeRemaining <= 10 ? .red : .orange,
                timeRemaining <= 10 ? .orange : .green
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        let progress = CGFloat(timeRemaining) / CGFloat(totalTime)
        return max(0, progress * totalWidth)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct GameHeaderView: View {
    @EnvironmentObject var gameController: GameController
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Top row
            HStack {
                // Pause button (replacing home button)
                Button(action: {
                    gameController.togglePause()
                }) {
                    Image(systemName: gameController.isGamePaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.3))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                        )
                }
                
                Spacer()
                
                // Level info
                VStack(spacing: 5) {
                    Text(gameController.currentLevelName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Level \(gameController.currentLevel + 1)/\(gameController.levels.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Score display
                VStack(spacing: 5) {
                    HStack(spacing: 5) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        Text("\(gameController.currentScore)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.blue, lineWidth: 1)
                )
                .onAppear { isAnimating = true }
            }
            
            // Timer display
            TimerDisplayView(timeRemaining: gameController.timeRemaining,
                            totalTime: gameController.currentLevelTimeLimit)
        }
    }
}

struct EnhancedRoomView: View {
    let room: Room
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Room glow effect
            if room.isHighlighted {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1)
                            .repeatForever(autoreverses: true),
                        value: isPulsing
                    )
                    .onAppear { isPulsing = true }
                    .onDisappear { isPulsing = false }
            }
            
            // Room shape
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    room.isHighlighted ?
                    LinearGradient(
                        gradient: Gradient(colors: [.yellow.opacity(0.4), .orange.opacity(0.2)]),
                        startPoint: .top,
                        endPoint: .bottom
                    ) :
                    LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.1)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            room.isHighlighted ?
                            LinearGradient(
                                gradient: Gradient(colors: [.yellow, .orange]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 3
                        )
                )
                .shadow(
                    color: room.isHighlighted ? .yellow.opacity(0.5) : .blue.opacity(0.3),
                    radius: 10
                )
            
            // Room content
            VStack(spacing: 5) {
                Text(room.name)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(room.isHighlighted ? .orange : .white)
                
                if room.containsRat {
                    Image(systemName: "pawprint.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}


struct FloatingControlsView: View {
    @EnvironmentObject var gameController: GameController
    @State private var offset = CGSize.zero
    @State private var controlsCollapsed = false
    @GestureState private var dragOffset = CGSize.zero
    
    var body: some View {
        ZStack {
            if controlsCollapsed {
                // Collapsed state - just a small circle
                Button(action: {
                    withAnimation(.spring()) {
                        controlsCollapsed = false
                    }
                }) {
                    Circle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .blue.opacity(0.5), radius: 8)
                }
                .offset(x: offset.width, y: offset.height)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation
                        }
                        .onEnded { value in
                            offset = value.translation
                        }
                )
            } else {
                // Expanded controls
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        // Top-left: Empty space for drag
                        Color.clear.frame(width: 40, height: 40)
                        
                        // Up button
                        CompactControlButton(
                            icon: "arrow.up",
                            action: { gameController.moveCat(direction: .up) },
                            color: .blue
                        )
                        
                        // Top-right: Close button
                        Button(action: {
                            withAnimation(.spring()) {
                                controlsCollapsed = true
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red.opacity(0.8))
                                .frame(width: 30, height: 30)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                    
                    HStack(spacing: 6) {
                        // Left button
                        CompactControlButton(
                            icon: "arrow.left",
                            action: { gameController.moveCat(direction: .left) },
                            color: .blue
                        )
                        
                        // Center: Reset button
                        Button(action: {
                            withAnimation {
                                gameController.resetGame()
                            }
                        }) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.red.opacity(0.7))
                                .clipShape(Circle())
                        }
                        
                        // Right button
                        CompactControlButton(
                            icon: "arrow.right",
                            action: { gameController.moveCat(direction: .right) },
                            color: .blue
                        )
                    }
                    
                    // Down button
                    CompactControlButton(
                        icon: "arrow.down",
                        action: { gameController.moveCat(direction: .down) },
                        color: .blue
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(10)
                .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            offset.width += value.translation.width
                            offset.height += value.translation.height
                            
                            // Keep within screen bounds
                            let screenBounds = UIScreen.main.bounds
                            let controlSize: CGFloat = 150
                            
                            withAnimation(.spring()) {
                                if offset.width < -screenBounds.width/2 + controlSize {
                                    offset.width = -screenBounds.width/2 + controlSize
                                } else if offset.width > screenBounds.width/2 - controlSize {
                                    offset.width = screenBounds.width/2 - controlSize
                                }
                                
                                if offset.height < -screenBounds.height/2 + controlSize {
                                    offset.height = -screenBounds.height/2 + controlSize
                                } else if offset.height > screenBounds.height/2 - controlSize {
                                    offset.height = screenBounds.height/2 - controlSize
                                }
                            }
                        }
                )
            }
        }
        .padding(.horizontal)
    }
}

struct CompactControlButton: View {
    let icon: String
    let action: () -> Void
    let color: Color
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
                action()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 40, height: 40)
                .background(color.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 0.85 : 1.0)
        }
    }
}

struct GameMessageView: View {
    let message: String
    @State private var isVisible = true
    
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.2)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .shadow(color: .blue.opacity(0.3), radius: 10)
            .opacity(isVisible ? 1 : 0)
            .animation(
                Animation.easeInOut(duration: 0.5)
                    .repeatForever(autoreverses: true),
                value: isVisible
            )
            .onAppear { isVisible = true }
    }
}

// Pause Menu View
struct PauseMenuView: View {
    @EnvironmentObject var gameController: GameController
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.white)
                
                Text("GAME PAUSED")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(spacing: 15) {
                    Button(action: {
                        gameController.togglePause()
                    }) {
                        Text("RESUME GAME")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        gameController.resetGame()
                    }) {
                        Text("RESTART LEVEL")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 250)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                }
            }
            .padding(40)
            .background(Color.black.opacity(0.8))
            .cornerRadius(25)
            .shadow(radius: 20)
        }
    }
}

struct RatCaughtCelebration: View {
    let score: Int
    let onNextLevel: () -> Void
    let onMenu: () -> Void
    let isLastLevel: Bool
    @State private var confetti = false
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Trophy with animation
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.yellow, .orange]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(confetti ? 360 : 0))
                    .animation(
                        Animation.spring(response: 0.6, dampingFraction: 0.6),
                        value: scale
                    )
                
                // Title
                Text("LEVEL COMPLETE!")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .yellow, radius: 10)
                
                // Score display
                VStack(spacing: 10) {
                    Text("YOU EARNED")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(score) POINTS")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange, radius: 5)
                }
                
                // Cat and rat icons
                HStack(spacing: 30) {
                    Image("cat")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(confetti ? -360 : 0))
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Image("rat")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(confetti ? 360 : 0))
                }
                
                // Buttons
                VStack(spacing: 15) {
                    if !isLastLevel {
                        Button(action: onNextLevel) {
                            Text("NEXT LEVEL")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.green, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(15)
                                .shadow(color: .green.opacity(0.5), radius: 10)
                        }
                    }
                    
                    Button(action: onMenu) {
                        Text("BACK TO MENU")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(15)
                            .shadow(color: .purple.opacity(0.5), radius: 10)
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal,50)
            .padding(.vertical,40)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(30)
            .shadow(color: .yellow.opacity(0.5), radius: 50)
            .scaleEffect(scale)
            .opacity(opacity)
            
            // Confetti effect
            if confetti {
                ConfettiView()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    confetti = true
                }
            }
        }
    }
}

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    struct ConfettiPiece: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let color: Color
        let rotation: Double
        let speed: Double
    }
    
    init() {
        for _ in 0..<100 {
            confettiPieces.append(ConfettiPiece(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: -50,
                color: [.red, .blue, .green, .yellow, .orange, .purple].randomElement()!,
                rotation: Double.random(in: 0...360),
                speed: Double.random(in: 2...6)
            ))
        }
    }
    
    var body: some View {
        ForEach(confettiPieces) { piece in
            Rectangle()
                .fill(piece.color)
                .frame(width: 10, height: 10)
                .rotationEffect(.degrees(piece.rotation))
                .position(x: piece.x, y: piece.y)
                .animation(
                    Animation.linear(duration: piece.speed)
                        .repeatForever(autoreverses: false),
                    value: piece.y
                )
                .onAppear {
                    withAnimation(.linear(duration: piece.speed)) {
                        _ = piece.y + UIScreen.main.bounds.height + 100
                    }
                }
        }
    }
}

// Game Over View
struct GameOverView: View {
    let onRestart: () -> Void
    let onMenu: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 6) {
                Image(systemName: "clock.badge.xmark")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                
                Text("TIME'S UP!")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("The rat escaped!")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                
                // Cat looking sad
                Image("cat")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                            .offset(y: -30)
                    )
                
                // Buttons
                VStack(spacing: 15) {
                    Button(action: onRestart) {
                        Text("TRY AGAIN")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(15)
                    }
                    
                    Button(action: onMenu) {
                        Text("BACK TO MENU")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(15)
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal,50)
            .padding(.vertical,40)
            .background(Color.red.opacity(0.2))
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.red, lineWidth: 3)
            )
        }
    }
}

// Game Complete Celebration
struct GameCompleteCelebration: View {
    let totalScore: Int
    let onMenu: () -> Void
    @State private var confetti = false
    @State private var scale: CGFloat = 0.1
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.yellow, .orange]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(scale)
                
                Text("GAME COMPLETED!")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("🎉 Congratulations! 🎉")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))
                
                VStack(spacing: 10) {
                    Text("TOTAL SCORE")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(totalScore)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange, radius: 10)
                }
                
                Button(action: onMenu) {
                    Text("BACK TO MENU")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: .blue.opacity(0.5), radius: 10)
                }
                .padding(.top, 20)
            }
            .padding(40)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.9), .purple.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(30)
            .scaleEffect(scale)
            
            // Confetti effect
            if confetti {
                ConfettiView()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                confetti = true
            }
        }
    }
}

struct HowToPlayView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
           
            GeometryReader { geometry in
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.5)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .ignoresSafeArea()
            }
            .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Custom navigation bar that won't change color
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Back")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                 
                    
                    Text("HOW TO PLAY")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .blue.opacity(0.5), radius: 5, x: 0, y: 2)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 25)
                .background(Color(red: 0.08, green: 0.08, blue: 0.18))
                
                // Content ScrollView
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        // Game Objective Section
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "GAME OBJECTIVE", color: .orange)
                            
                            BulletPoint(
                                text: "Find the hidden rat in one of the rooms",
                                color: .orange,
                                icon: "magnifyingglass"
                            )
                            
                            BulletPoint(
                                text: "Explore all rooms until you catch it",
                                color: .orange,
                                icon: "hare.fill"
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Controls Section
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "CONTROLS", color: .blue)
                            
                            BulletPoint(
                                text: "Use the floating control buttons to navigate",
                                color: .blue,
                                icon: "arrow.up.arrow.down"
                            )
                            
                            BulletPoint(
                                text: "Move through rooms and corridors",
                                color: .blue,
                                icon: "arrow.left.arrow.right"
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Scoring Section
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "SCORING SYSTEM", color: .yellow)
                            
                            BulletPoint(
                                text: "Find the rat: Get level points",
                                color: .yellow,
                                icon: "star.fill"
                            )
                            
                            BulletPoint(
                                text: "Wrong rooms: No penalty",
                                color: .yellow,
                                icon: "xmark.circle"
                            )
                            
                            BulletPoint(
                                text: "Complete level: Unlock next level",
                                color: .yellow,
                                icon: "lock.open.fill"
                            )
                            
                            BulletPoint(
                                text: "Total score: All levels combined",
                                color: .yellow,
                                icon: "chart.bar.fill"
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Progress Section
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "PROGRESS & LEVELS", color: .green)
                            
                            BulletPoint(
                                text: "Complete levels to unlock harder challenges",
                                color: .green,
                                icon: "flag.fill"
                            )
                            
                            BulletPoint(
                                text: "Each level has unique room layouts",
                                color: .green,
                                icon: "map.fill"
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Pro Tips Section
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "PRO TIPS", color: .purple)
                            
                            BulletPoint(
                                text: "Plan your route before moving",
                                color: .purple,
                                icon: "lightbulb.fill"
                            )
                            
                            BulletPoint(
                                text: "Remember room connections",
                                color: .purple,
                                icon: "link.circle.fill"
                            )
                            
                            BulletPoint(
                                text: "Try to find the shortest path",
                                color: .purple,
                                icon: "arrow.turn.right.up"
                            )
                            
                            BulletPoint(
                                text: "Watch for highlighted rooms",
                                color: .purple,
                                icon: "sparkles"
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Quick Start Section
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "QUICK START", color: .pink)
                            
                            NumberedPoint(
                                number: "1",
                                text: "Tap PLAY to start game",
                                color: .pink
                            )
                            
                            NumberedPoint(
                                number: "2",
                                text: "Choose a level to begin",
                                color: .pink
                            )
                            
                            NumberedPoint(
                                number: "3",
                                text: "Navigate using controls",
                                color: .pink
                            )
                            
                            NumberedPoint(
                                number: "4",
                                text: "Find the rat to win",
                                color: .pink
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 60)
                    }
                    .padding(.top, 20)
                }
                
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(true)
    }
}

// Supporting Views
struct SectionHeader: View {
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: color.opacity(0.3), radius: 2)
            
            Spacer()
        }
    }
}

struct BulletPoint: View {
    let text: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct NumberedPoint: View {
    let number: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                
                Text(number)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct CustomBackButton: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                Text("Back")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding(8)
            .background(Color.blue.opacity(0.3))
            .cornerRadius(10)
        }
    }
}

class GameController: ObservableObject {
    @Published var currentLevel = 0
    @Published var currentRooms: [Room] = []
    @Published var currentDoors: [Door] = []
    @Published var catPosition: CGPoint = .zero
    @Published var message = ""
    @Published var currentScore = 0
    @Published var totalScore = 0
    @Published var unlockedLevels = 1
    @Published var showLevelComplete = false
    @Published var ratCaught = false
    @Published var isRatVisible = false
    @Published var timeRemaining: Int = 0
    @Published var isGamePaused = false
    @Published var showGameOver = false
    @Published var showGameComplete = false
    
    // Game state
    private var levelStartTime = Date()
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    
    // Sound file names
    private let ratCaughtSound = "rat_caught"
    private let gameOverSound = "game_over"
    private let buttonSound = "button_click"
    
    let levels: [GameLevel] = [
        GameLevel(
            id: 1,
            name: "BEGINNER'S HOUSE",
            rooms: [
                Room(id: 1, name: "LIVING", position: CGPoint(x: 0.3, y: 0.3), connectedRooms: [2], doors: []),
                Room(id: 2, name: "KITCHEN", position: CGPoint(x: 0.7, y: 0.3), connectedRooms: [1], doors: [])
            ],
            catStartPosition: CGPoint(x: 0.3, y: 0.3),
            ratRoom: 2,
            basePoints: 100,
            description: "Simple two-room layout",
            optimalPathLength: 1,
            timeLimit: 30 // 30 seconds
        ),
        GameLevel(
            id: 2,
            name: "COZY APARTMENT",
            rooms: [
                Room(id: 1, name: "LIVING", position: CGPoint(x: 0.2, y: 0.3), connectedRooms: [2, 3], doors: []),
                Room(id: 2, name: "KITCHEN", position: CGPoint(x: 0.5, y: 0.3), connectedRooms: [1, 4], doors: []),
                Room(id: 3, name: "BEDROOM", position: CGPoint(x: 0.2, y: 0.6), connectedRooms: [1, 4], doors: []),
                Room(id: 4, name: "BATHROOM", position: CGPoint(x: 0.5, y: 0.6), connectedRooms: [2, 3], doors: [])
            ],
            catStartPosition: CGPoint(x: 0.2, y: 0.3),
            ratRoom: 4,
            basePoints: 200,
            description: "Four rooms with multiple paths",
            optimalPathLength: 2,
            timeLimit: 60 // 1 minute
        ),
        GameLevel(
            id: 3,
            name: "FAMILY HOUSE",
            rooms: [
                Room(id: 1, name: "ENTRANCE", position: CGPoint(x: 0.2, y: 0.2), connectedRooms: [2, 3], doors: []),
                Room(id: 2, name: "LIVING", position: CGPoint(x: 0.5, y: 0.2), connectedRooms: [1, 4], doors: []),
                Room(id: 3, name: "KITCHEN", position: CGPoint(x: 0.2, y: 0.5), connectedRooms: [1, 4, 5], doors: []),
                Room(id: 4, name: "HALL", position: CGPoint(x: 0.5, y: 0.5), connectedRooms: [2, 3, 6], doors: []),
                Room(id: 5, name: "BEDROOM", position: CGPoint(x: 0.2, y: 0.8), connectedRooms: [3, 6], doors: []),
                Room(id: 6, name: "BATHROOM", position: CGPoint(x: 0.5, y: 0.8), connectedRooms: [4, 5], doors: [])
            ],
            catStartPosition: CGPoint(x: 0.2, y: 0.2),
            ratRoom: 6,
            basePoints: 300,
            description: "Six-room family house",
            optimalPathLength: 3,
            timeLimit: 90 // 1.5 minutes
        ),
        GameLevel(
            id: 4,
            name: "OFFICE BUILDING",
            rooms: [
                Room(id: 1, name: "RECEPTION", position: CGPoint(x: 0.3, y: 0.1), connectedRooms: [2], doors: []),
                Room(id: 2, name: "HALLWAY", position: CGPoint(x: 0.5, y: 0.3), connectedRooms: [1, 3, 5], doors: []),
                Room(id: 3, name: "OFFICE 1", position: CGPoint(x: 0.3, y: 0.5), connectedRooms: [2, 4], doors: []),
                Room(id: 4, name: "OFFICE 2", position: CGPoint(x: 0.7, y: 0.5), connectedRooms: [3, 6], doors: []),
                Room(id: 5, name: "KITCHEN", position: CGPoint(x: 0.5, y: 0.7), connectedRooms: [2, 6], doors: []),
                Room(id: 6, name: "STORAGE", position: CGPoint(x: 0.3, y: 0.9), connectedRooms: [4, 5], doors: [])
            ],
            catStartPosition: CGPoint(x: 0.3, y: 0.1),
            ratRoom: 6,
            basePoints: 400,
            description: "Modern office layout",
            optimalPathLength: 4,
            timeLimit: 120 // 2 minutes
        ),
        GameLevel(
            id: 5,
            name: "GRAND HOTEL",
            rooms: [
                Room(id: 1, name: "LOBBY", position: CGPoint(x: 0.5, y: 0.1), connectedRooms: [2, 3], doors: []),
                Room(id: 2, name: "EAST WING", position: CGPoint(x: 0.3, y: 0.3), connectedRooms: [1, 4], doors: []),
                Room(id: 3, name: "WEST WING", position: CGPoint(x: 0.7, y: 0.3), connectedRooms: [1, 5], doors: []),
                Room(id: 4, name: "ROOM 101", position: CGPoint(x: 0.3, y: 0.5), connectedRooms: [2, 6], doors: []),
                Room(id: 5, name: "ROOM 102", position: CGPoint(x: 0.7, y: 0.5), connectedRooms: [3, 7], doors: []),
                Room(id: 6, name: "ROOM 103", position: CGPoint(x: 0.3, y: 0.7), connectedRooms: [4, 8], doors: []),
                Room(id: 7, name: "ROOM 104", position: CGPoint(x: 0.7, y: 0.7), connectedRooms: [5, 9], doors: []),
                Room(id: 8, name: "SUITE", position: CGPoint(x: 0.5, y: 0.9), connectedRooms: [6, 7], doors: [])
            ],
            catStartPosition: CGPoint(x: 0.5, y: 0.1),
            ratRoom: 8,
            basePoints: 500,
            description: "Luxury hotel challenge",
            optimalPathLength: 5,
            timeLimit: 150 // 2.5 minutes
        ),
        GameLevel(
            id: 6,
            name: "MYSTERY PALACE",
            rooms: [
                Room(id: 1, name: "GATES", position: CGPoint(x: 0.5, y: 0.1), connectedRooms: [2, 3], doors: []),
                Room(id: 2, name: "EAST TOWER", position: CGPoint(x: 0.3, y: 0.3), connectedRooms: [1, 4, 5], doors: []),
                Room(id: 3, name: "WEST TOWER", position: CGPoint(x: 0.7, y: 0.3), connectedRooms: [1, 6, 7], doors: []),
                Room(id: 4, name: "LIBRARY", position: CGPoint(x: 0.2, y: 0.5), connectedRooms: [2, 8], doors: []),
                Room(id: 5, name: "GALLERY", position: CGPoint(x: 0.4, y: 0.5), connectedRooms: [2, 9], doors: []),
                Room(id: 6, name: "KITCHEN", position: CGPoint(x: 0.6, y: 0.5), connectedRooms: [3, 10], doors: []),
                Room(id: 7, name: "DINING", position: CGPoint(x: 0.8, y: 0.5), connectedRooms: [3, 11], doors: []),
                Room(id: 8, name: "STUDY", position: CGPoint(x: 0.2, y: 0.7), connectedRooms: [4, 12], doors: []),
                Room(id: 9, name: "HALL", position: CGPoint(x: 0.4, y: 0.7), connectedRooms: [5, 12], doors: []),
                Room(id: 10, name: "PANTRY", position: CGPoint(x: 0.6, y: 0.7), connectedRooms: [6, 12], doors: []),
                Room(id: 11, name: "BALLROOM", position: CGPoint(x: 0.8, y: 0.7), connectedRooms: [7, 12], doors: []),
                Room(id: 12, name: "THRONE", position: CGPoint(x: 0.5, y: 0.9), connectedRooms: [8, 9, 10, 11], doors: [])
            ],
            catStartPosition: CGPoint(x: 0.5, y: 0.1),
            ratRoom: 12,
            basePoints: 1000,
            description: "Ultimate palace challenge",
            optimalPathLength: 6,
            timeLimit: 180 // 3 minutes
        )
    ]
    
    var currentLevelName: String {
        levels[currentLevel].name
    }
    
    var currentLevelTimeLimit: Int {
        levels[currentLevel].timeLimit
    }
    
    init() {
        setupLevel()
        startRatVisibilityAnimation()
    }
    
    private func startRatVisibilityAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if !self.isGamePaused {
                self.isRatVisible.toggle()
            }
        }
    }
    
    func setupLevel() {
        let level = levels[currentLevel]
        
        // Reset game state
        var rooms = level.rooms
        for i in 0..<rooms.count {
            rooms[i].containsRat = (rooms[i].id == level.ratRoom)
            rooms[i].isHighlighted = false
        }
        currentRooms = rooms
        
        catPosition = level.catStartPosition
        ratCaught = false
        currentScore = 0
        timeRemaining = level.timeLimit
        showGameOver = false
        showGameComplete = false
        isGamePaused = false
        
        // Start timer
        startTimer()
        
        // Generate doors
        var doors: [Door] = []
        for room in rooms {
            for connectedRoomId in room.connectedRooms {
                if let connectedRoom = rooms.first(where: { $0.id == connectedRoomId }) {
                    let door = Door(
                        fromRoom: room.id,
                        toRoom: connectedRoom.id,
                        position: CGPoint(
                            x: (room.position.x + connectedRoom.position.x) / 2,
                            y: (room.position.y + connectedRoom.position.y) / 2
                        ),
                        isHorizontal: abs(room.position.x - connectedRoom.position.x) > abs(room.position.y - connectedRoom.position.y)
                    )
                    doors.append(door)
                }
            }
        }
        currentDoors = Array(Set(doors))
        
        // Set initial message
        message = "Find the rat in the \(level.name)! You have \(timeRemaining) seconds..."
        
        // Highlight starting room
        highlightRoom(at: catPosition)
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.isGamePaused && self.timeRemaining > 0 && !self.ratCaught {
                self.timeRemaining -= 1
                
                // Update message when time is running low
                if self.timeRemaining == 30 {
                    self.message = "30 seconds remaining! Hurry up!"
                } else if self.timeRemaining == 10 {
                    self.message = "10 seconds left! Find the rat quickly!"
                } else if self.timeRemaining <= 5 {
                    self.message = "\(self.timeRemaining) seconds left!"
                }
                
                if self.timeRemaining <= 0 {
                    self.gameOver()
                }
            }
        }
    }
    
    private func gameOver() {
        timer?.invalidate()
        ratCaught = false // Reset rat caught flag
        message = "⏰ Time's up! The rat escaped!"
        showGameOver = true
        
        // Play game over sound
        playSound(named: gameOverSound)
    }
    
    func togglePause() {
        isGamePaused.toggle()
        if isGamePaused {
            timer?.invalidate()
            message = "Game Paused"
        } else {
            startTimer()
            message = "Game Resumed"
        }
        
        // Play button sound
        playSound(named: buttonSound)
    }
    
    func playSound(named soundName: String) {
        // First try to find the sound file
        if let path = Bundle.main.path(forResource: soundName, ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error)")
            }
        } else {
            // If sound file doesn't exist, use system sound
            let systemSound: SystemSoundID
            if soundName == "rat_caught" {
                systemSound = 1001 // Success sound
            } else if soundName == "game_over" {
                systemSound = 1002 // Error sound
            } else {
                systemSound = 1104 // Click sound
            }
            AudioServicesPlaySystemSound(systemSound)
        }
    }
    
    enum Direction {
        case up, down, left, right
    }
    
    func moveCat(direction: Direction) {
        // Don't move if rat is already caught or game is paused
        if ratCaught || isGamePaused {
            return
        }
        
        let moveDistance: CGFloat = 0.05
        var newPosition = catPosition
        
        switch direction {
        case .up:
            newPosition.y = max(0.1, catPosition.y - moveDistance)
        case .down:
            newPosition.y = min(0.9, catPosition.y + moveDistance)
        case .left:
            newPosition.x = max(0.1, catPosition.x - moveDistance)
        case .right:
            newPosition.x = min(0.9, catPosition.x + moveDistance)
        }
        
        if isValidMove(from: catPosition, to: newPosition) {
            catPosition = newPosition
            
            if let room = getRoomAtPosition(newPosition) {
                highlightRoom(at: newPosition)
                checkRoomForRat(room)
            } else {
                message = "Moving through corridor..."
            }
        } else {
            message = "Can't move that way!"
        }
    }
    
    func isValidMove(from: CGPoint, to: CGPoint) -> Bool {
        guard to.x >= 0.05 && to.x <= 0.95 && to.y >= 0.05 && to.y <= 0.95 else {
            return false
        }
        
        let currentRoom = getRoomAtPosition(from)
        let targetRoom = getRoomAtPosition(to)
        
        if let currentRoom = currentRoom, let targetRoom = targetRoom {
            if currentRoom.id == targetRoom.id {
                return true
            }
            if currentDoors.contains(where: { door in
                (door.fromRoom == currentRoom.id && door.toRoom == targetRoom.id) ||
                (door.fromRoom == targetRoom.id && door.toRoom == currentRoom.id)
            }) {
                return true
            }
        }
        
        for door in currentDoors {
            let room1 = getRoom(by: door.fromRoom)
            let room2 = getRoom(by: door.toRoom)
            let corridorStart = room1.position
            let corridorEnd = room2.position
            
            let distance = distancePointToLineSegment(point: to, lineStart: corridorStart, lineEnd: corridorEnd)
            if distance < 0.1 {
                return true
            }
        }
        
        return false
    }
    
    func distancePointToLineSegment(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let A = point.x - lineStart.x
        let B = point.y - lineStart.y
        let C = lineEnd.x - lineStart.x
        let D = lineEnd.y - lineStart.y
        
        let dot = A * C + B * D
        let lenSq = C * C + D * D
        var param = dot / lenSq
        
        var xx, yy: CGFloat
        
        if param < 0 {
            xx = lineStart.x
            yy = lineStart.y
        } else if param > 1 {
            xx = lineEnd.x
            yy = lineEnd.y
        } else {
            xx = lineStart.x + param * C
            yy = lineStart.y + param * D
        }
        
        let dx = point.x - xx
        let dy = point.y - yy
        return sqrt(dx * dx + dy * dy)
    }
    
    func getRoomAtPosition(_ position: CGPoint) -> Room? {
        for room in currentRooms {
            let distance = hypot(room.position.x - position.x, room.position.y - position.y)
            if distance < 0.1 {
                return room
            }
        }
        return nil
    }
    
    func highlightRoom(at position: CGPoint) {
        for i in 0..<currentRooms.count {
            currentRooms[i].isHighlighted = false
        }
        
        if let roomIndex = currentRooms.firstIndex(where: { room in
            let distance = hypot(room.position.x - position.x, room.position.y - position.y)
            return distance < 0.1
        }) {
            currentRooms[roomIndex].isHighlighted = true
        }
        
        objectWillChange.send()
    }
    
    func checkRoomForRat(_ room: Room) {
        if room.containsRat {
            timer?.invalidate()
            ratCaught = true
            calculateFinalScore()
            
            // Play rat caught sound
            playSound(named: ratCaughtSound)
            
            message = "🎉 FOUND THE RAT! You earned \(currentScore) points!"
            showLevelComplete = true
            
            // Unlock next level
            if currentLevel + 1 < levels.count {
                unlockedLevels = max(unlockedLevels, currentLevel + 2)
            }
        } else {
            // No penalty for wrong rooms
            message = "No rat in \(room.name). Keep searching!"
        }
    }
    
    private func calculateFinalScore() {
        let level = levels[currentLevel]
        
        // Calculate bonus based on time remaining
        let timeBonus = (timeRemaining * 10) // 10 points per second remaining
        
        // Base points + time bonus
        currentScore = level.basePoints + timeBonus
        totalScore += currentScore
    }
    
    func getRoom(by id: Int) -> Room {
        return currentRooms.first(where: { $0.id == id }) ?? currentRooms[0]
    }
    
    func nextLevel() {
        if currentLevel < levels.count - 1 {
            currentLevel += 1
            setupLevel()
            showGameComplete = false
        } else {
            // Last level completed
            showGameComplete = true
        }
    }
    
    func resetGame() {
        timer?.invalidate()
        setupLevel()
    }
    
    func exitToMenu() {
        timer?.invalidate()
        isGamePaused = false
       
    }
}
