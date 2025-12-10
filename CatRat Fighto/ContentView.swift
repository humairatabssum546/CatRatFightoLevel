



import SwiftUI
import AVFoundation
import AudioToolbox

// MARK: - Data Models
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

struct Achievement: Identifiable, Codable {
    let id: Int
    let title: String
    let description: String
    let icon: String
    let requirement: String
    let pointsReward: Int
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    let category: AchievementCategory
    
    enum AchievementCategory: String, Codable {
        case levelCompletion
        case score
        case speed
        case perfection
        case special
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, icon, requirement, pointsReward, isUnlocked, unlockedDate, category
    }
}

struct DailyChallenge: Identifiable, Codable {
    let id: Int
    let title: String
    let description: String
    let challengeType: ChallengeType
    let target: Int
    let rewardPoints: Int
    var progress: Int = 0
    var isCompleted: Bool = false
    let date: Date
    
    enum ChallengeType: String, Codable {
        case completeLevels
        case scorePoints
        case quickCompletion
        case perfectRun
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, challengeType, target, rewardPoints, progress, isCompleted, date
    }
}

struct UserStats: Codable {
    var totalGamesPlayed: Int = 0
    var totalRatsCaught: Int = 0
    var totalDistanceTraveled: CGFloat = 0
    var fastestLevelCompletion: [Int: Int] = [:] // levelId: time in seconds
    var perfectRuns: [Int: Bool] = [:] // levelId: perfect completion
    var consecutiveDaysPlayed: Int = 0
    var lastPlayDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case totalGamesPlayed, totalRatsCaught, totalDistanceTraveled, fastestLevelCompletion, perfectRuns, consecutiveDaysPlayed, lastPlayDate
    }
}

// MARK: - Splash Screen
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

// MARK: - Game Controller
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
    
    @Published var isGameOver = false  // Add this flag
    
    // Mini Games Properties
      @Published var miniGamesScore = 0
      @Published var memoryMatchHighScore = 0
    
    // New properties for achievements and challenges
    @Published var achievements: [Achievement] = []
    @Published var dailyChallenges: [DailyChallenge] = []
    @Published var userStats = UserStats()
    @Published var showAchievementUnlocked: Bool = false
    @Published var unlockedAchievement: Achievement?
    @Published var todaysChallenge: DailyChallenge?
    
    // Game state
    private var levelStartTime = Date()
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var wrongRoomsCount = 0
    
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
        // Load saved data first
        loadSavedData()
        
        setupLevel()
        startRatVisibilityAnimation()
        initializeAchievements()
        loadDailyChallenges()
        loadUserStats()
        checkDailyLogin()
        
        loadMiniGamesProgress() // Add this line
    }
    
    
    
    // Mini Games Functions
       func updateMiniGameScore(points: Int) {
           miniGamesScore += points
           
           // Update high score if needed
           if points > memoryMatchHighScore {
               memoryMatchHighScore = points
               saveMiniGamesProgress()
           }
           
           // Save progress
           saveMiniGamesProgress()
       }
       
       private func saveMiniGamesProgress() {
           UserDefaults.standard.set(miniGamesScore, forKey: "miniGamesScore")
           UserDefaults.standard.set(memoryMatchHighScore, forKey: "memoryMatchHighScore")
       }
       
       private func loadMiniGamesProgress() {
           if let savedScore = UserDefaults.standard.object(forKey: "miniGamesScore") as? Int {
               miniGamesScore = savedScore
           }
           
           if let savedHighScore = UserDefaults.standard.object(forKey: "memoryMatchHighScore") as? Int {
               memoryMatchHighScore = savedHighScore
           }
       }
       

    
    private func startRatVisibilityAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if !self.isGamePaused {
                self.isRatVisible.toggle()
            }
        }
    }

    func setupLevel() {
        wrongRoomsCount = 0
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
        
        isGameOver = false  // Reset this flag

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
                  
                  if self.timeRemaining <= 0 && !self.isGameOver {
                      self.gameOver()
                  }
              }
          }
      }
      
      private func gameOver() {
          // Prevent multiple game over triggers
          guard !isGameOver else { return }
          
          isGameOver = true
          timer?.invalidate()
          ratCaught = false // Reset rat caught flag
          message = "⏰ Time's up! The rat escaped!"
          showGameOver = true
          
          // Play game over sound only once
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
            
            let completionTime = levels[currentLevel].timeLimit - timeRemaining
            let wasPerfect = wrongRoomsCount == 0
            
            calculateFinalScore()
            completeLevel(levelId: currentLevel, completionTime: completionTime, wasPerfect: wasPerfect)
            
            // Play rat caught sound
            playSound(named: ratCaughtSound)
            
            message = "🎉 FOUND THE RAT! You earned \(currentScore) points!"
            showLevelComplete = true
            
            // Unlock next level
            if currentLevel + 1 < levels.count {
                unlockedLevels = max(unlockedLevels, currentLevel + 2)
                saveProgress() // Save when unlocking new level
            }
            
            saveProgress() // Save after completing level
        } else {
            wrongRoomsCount += 1
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
        
        // Update daily challenge for score points
        updateScoreForDailyChallenge(points: currentScore)
        
        saveProgress() // Save score
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
    
    // MARK: - Save/Load Progress
    
    private func loadSavedData() {
        // Load total score
        if let savedScore = UserDefaults.standard.object(forKey: "totalScore") as? Int {
            totalScore = savedScore
        }
        
        // Load unlocked levels
        if let savedUnlockedLevels = UserDefaults.standard.object(forKey: "unlockedLevels") as? Int {
            unlockedLevels = savedUnlockedLevels
        }
        
        // Load current level
        if let savedCurrentLevel = UserDefaults.standard.object(forKey: "currentLevel") as? Int {
            currentLevel = savedCurrentLevel
        }
    }
    
    private func saveProgress() {
        // Save total score
        UserDefaults.standard.set(totalScore, forKey: "totalScore")
        
        // Save unlocked levels
        UserDefaults.standard.set(unlockedLevels, forKey: "unlockedLevels")
        
        // Save current level
        UserDefaults.standard.set(currentLevel, forKey: "currentLevel")
        
        // Save achievements
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
        
        // Save user stats
        if let encoded = try? JSONEncoder().encode(userStats) {
            UserDefaults.standard.set(encoded, forKey: "userStats")
        }
    }
    
    func resetAllProgress() {
        // Reset all game data
        totalScore = 0
        unlockedLevels = 1
        currentLevel = 0
        
        // Reset achievements
        for i in 0..<achievements.count {
            achievements[i].isUnlocked = false
            achievements[i].unlockedDate = nil
        }
        
        // Reset user stats
        userStats = UserStats()
        
        // Reset daily challenges
        dailyChallenges = []
        generateDailyChallenges()
        
        // Save the reset state
        saveProgress()
        saveUserStats()
        saveDailyChallenges()
        
        // Reset game
        setupLevel()
    }
    
    // MARK: - Achievements and Daily Challenges
    
    private func initializeAchievements() {
        achievements = [
            // Level Completion Achievements
            Achievement(
                id: 1,
                title: "First Hunt",
                description: "Complete your first level",
                icon: "trophy.fill",
                requirement: "Complete Level 1",
                pointsReward: 50,
                category: .levelCompletion
            ),
            Achievement(
                id: 2,
                title: "Apartment Explorer",
                description: "Complete the Cozy Apartment",
                icon: "building.2.fill",
                requirement: "Complete Level 2",
                pointsReward: 100,
                category: .levelCompletion
            ),
            Achievement(
                id: 3,
                title: "Family Hunter",
                description: "Complete the Family House",
                icon: "house.fill",
                requirement: "Complete Level 3",
                pointsReward: 150,
                category: .levelCompletion
            ),
            Achievement(
                id: 4,
                title: "Office Raider",
                description: "Complete the Office Building",
                icon: "briefcase.fill",
                requirement: "Complete Level 4",
                pointsReward: 200,
                category: .levelCompletion
            ),
            Achievement(
                id: 5,
                title: "Hotel Conqueror",
                description: "Complete the Grand Hotel",
                icon: "bed.double.fill",
                requirement: "Complete Level 5",
                pointsReward: 250,
                category: .levelCompletion
            ),
            Achievement(
                id: 6,
                title: "Palace Master",
                description: "Complete the Mystery Palace",
                icon: "crown.fill",
                requirement: "Complete Level 6",
                pointsReward: 500,
                category: .levelCompletion
            ),
            
            // Score Achievements
            Achievement(
                id: 7,
                title: "Score Starter",
                description: "Reach 500 total points",
                icon: "star.fill",
                requirement: "500 total points",
                pointsReward: 100,
                category: .score
            ),
            Achievement(
                id: 8,
                title: "Score Hunter",
                description: "Reach 2000 total points",
                icon: "star.circle.fill",
                requirement: "2000 total points",
                pointsReward: 250,
                category: .score
            ),
            Achievement(
                id: 9,
                title: "Score Master",
                description: "Reach 5000 total points",
                icon: "star.square.fill",
                requirement: "5000 total points",
                pointsReward: 500,
                category: .score
            ),
            
            // Speed Achievements
            Achievement(
                id: 10,
                title: "Speedy Cat",
                description: "Complete any level in under 30 seconds",
                icon: "hare.fill",
                requirement: "Finish level in < 30s",
                pointsReward: 150,
                category: .speed
            ),
            Achievement(
                id: 11,
                title: "Lightning Hunter",
                description: "Complete any level in under 15 seconds",
                icon: "bolt.fill",
                requirement: "Finish level in < 15s",
                pointsReward: 300,
                category: .speed
            ),
            
            // Perfection Achievement - REMOVED problematic one
            Achievement(
                id: 12,
                title: "Perfect Hunter",
                description: "Find the rat on first try",
                icon: "checkmark.circle.fill",
                requirement: "First try success",
                pointsReward: 200,
                category: .perfection
            ),
            
            // Special Achievements
            Achievement(
                id: 13,
                title: "Daily Player",
                description: "Play for 3 consecutive days",
                icon: "flame.fill",
                requirement: "3 consecutive days",
                pointsReward: 100,
                category: .special
            ),
            Achievement(
                id: 14,
                title: "Week Warrior",
                description: "Play for 7 consecutive days",
                icon: "calendar",
                requirement: "7 consecutive days",
                pointsReward: 500,
                category: .special
            ),
            Achievement(
                id: 15,
                title: "Master Hunter",
                description: "Catch 50 rats total",
                icon: "pawprint.fill",
                requirement: "50 rats caught",
                pointsReward: 1000,
                category: .special
            )
        ]
        
        // Load unlocked achievements from UserDefaults
        loadAchievements()
    }
    
    private func loadDailyChallenges() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Check if we already have today's challenges
        if let savedDate = UserDefaults.standard.object(forKey: "dailyChallengesDate") as? Date,
           Calendar.current.isDate(savedDate, inSameDayAs: today),
           let savedData = UserDefaults.standard.data(forKey: "dailyChallenges"),
           let savedChallenges = try? JSONDecoder().decode([DailyChallenge].self, from: savedData) {
            
            dailyChallenges = savedChallenges
            todaysChallenge = dailyChallenges.first
            return
        }
        
        // Generate new daily challenges
        generateDailyChallenges()
    }
    
    private func generateDailyChallenges() {
        let today = Calendar.current.startOfDay(for: Date())
        
        let challengeTypes: [DailyChallenge.ChallengeType] = [
            .completeLevels,
            .scorePoints,
            .quickCompletion,
            .perfectRun
        ]
        
        let randomType = challengeTypes.randomElement() ?? .completeLevels
        
        let challenge: DailyChallenge
        
        switch randomType {
        case .completeLevels:
            let target = Int.random(in: 1...3)
            challenge = DailyChallenge(
                id: 1,
                title: "Level Master",
                description: "Complete \(target) levels today",
                challengeType: .completeLevels,
                target: target,
                rewardPoints: target * 50,
                date: today
            )
            
        case .scorePoints:
            let target = [500, 1000, 1500].randomElement() ?? 1000
            challenge = DailyChallenge(
                id: 2,
                title: "Score Collector",
                description: "Score \(target) points today",
                challengeType: .scorePoints,
                target: target,
                rewardPoints: target / 2,
                date: today
            )
            
        case .quickCompletion:
            let target = Int.random(in: 1...3)
            challenge = DailyChallenge(
                id: 3,
                title: "Speed Demon",
                description: "Complete \(target) levels in under 60 seconds",
                challengeType: .quickCompletion,
                target: target,
                rewardPoints: 200,
                date: today
            )
            
        case .perfectRun:
            let target = 1
            challenge = DailyChallenge(
                id: 4,
                title: "Perfect Hunter",
                description: "Complete a level without wrong rooms",
                challengeType: .perfectRun,
                target: target,
                rewardPoints: 300,
                date: today
            )
        }
        
        dailyChallenges = [challenge]
        todaysChallenge = challenge
        
        // Save to UserDefaults
        saveDailyChallenges()
    }
    
    private func saveDailyChallenges() {
        let today = Calendar.current.startOfDay(for: Date())
        if let encoded = try? JSONEncoder().encode(dailyChallenges) {
            UserDefaults.standard.set(encoded, forKey: "dailyChallenges")
            UserDefaults.standard.set(today, forKey: "dailyChallengesDate")
        }
    }
    
    private func loadUserStats() {
        if let savedData = UserDefaults.standard.data(forKey: "userStats"),
           let savedStats = try? JSONDecoder().decode(UserStats.self, from: savedData) {
            userStats = savedStats
        }
    }
    
    private func saveUserStats() {
        if let encoded = try? JSONEncoder().encode(userStats) {
            UserDefaults.standard.set(encoded, forKey: "userStats")
        }
    }
    
    private func loadAchievements() {
        if let savedData = UserDefaults.standard.data(forKey: "achievements"),
           let savedAchievements = try? JSONDecoder().decode([Achievement].self, from: savedData) {
            // Merge with current achievements
            for i in 0..<achievements.count {
                if let saved = savedAchievements.first(where: { $0.id == achievements[i].id }) {
                    achievements[i].isUnlocked = saved.isUnlocked
                    achievements[i].unlockedDate = saved.unlockedDate
                }
            }
        }
    }
    
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
    }
    
    private func checkDailyLogin() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastPlayDate = userStats.lastPlayDate {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            
            if Calendar.current.isDate(lastPlayDate, inSameDayAs: yesterday) {
                // Consecutive day
                userStats.consecutiveDaysPlayed += 1
            } else if !Calendar.current.isDate(lastPlayDate, inSameDayAs: today) {
                // Not consecutive, reset
                userStats.consecutiveDaysPlayed = 1
            }
        } else {
            // First time playing
            userStats.consecutiveDaysPlayed = 1
        }
        
        userStats.lastPlayDate = today
        saveUserStats()
        
        // Check for daily login achievements
        checkAchievements()
    }
    
    func updateDailyChallengeProgress() {
        guard var challenge = todaysChallenge else { return }
        
        switch challenge.challengeType {
        case .completeLevels:
            challenge.progress += 1
        case .scorePoints:
            // Updated when score changes
            break
        case .quickCompletion:
            // Check if level was completed quickly
            let completionTime = levels[currentLevel].timeLimit - timeRemaining
            if completionTime < 60 {
                challenge.progress += 1
            }
        case .perfectRun:
            if wrongRoomsCount == 0 {
                challenge.progress += 1
            }
        }
        
        if challenge.progress >= challenge.target && !challenge.isCompleted {
            challenge.isCompleted = true
            // Award points
            totalScore += challenge.rewardPoints
            showMessage("🎉 Daily Challenge Complete! +\(challenge.rewardPoints) points!")
            saveProgress()
        }
        
        // Update in array
        if let index = dailyChallenges.firstIndex(where: { $0.id == challenge.id }) {
            dailyChallenges[index] = challenge
            todaysChallenge = challenge
            saveDailyChallenges()
        }
    }
    
    func updateScoreForDailyChallenge(points: Int) {
        guard var challenge = todaysChallenge,
              challenge.challengeType == .scorePoints else { return }
        
        challenge.progress += points
        
        if challenge.progress >= challenge.target && !challenge.isCompleted {
            challenge.isCompleted = true
            totalScore += challenge.rewardPoints
            showMessage("🎉 Daily Challenge Complete! +\(challenge.rewardPoints) points!")
            saveProgress()
        }
        
        if let index = dailyChallenges.firstIndex(where: { $0.id == challenge.id }) {
            dailyChallenges[index] = challenge
            todaysChallenge = challenge
            saveDailyChallenges()
        }
    }
    
    func resetDailyChallenges() {
        dailyChallenges = []
        generateDailyChallenges()
    }
    
    private func showMessage(_ message: String) {
        self.message = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.message == message {
                self.message = ""
            }
        }
    }
    
    func checkAchievements() {
        var newAchievements: [Achievement] = []
        
        for i in 0..<achievements.count {
            if !achievements[i].isUnlocked && checkAchievementRequirement(achievements[i]) {
                var updatedAchievement = achievements[i]
                updatedAchievement.isUnlocked = true
                updatedAchievement.unlockedDate = Date()
                achievements[i] = updatedAchievement
                newAchievements.append(updatedAchievement)
                
                // Award points
                totalScore += updatedAchievement.pointsReward
                
                // Show achievement unlocked
                unlockedAchievement = updatedAchievement
                showAchievementUnlocked = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.showAchievementUnlocked = false
                }
            }
        }
        
        if !newAchievements.isEmpty {
            saveAchievements()
            saveProgress()
        }
    }
    
    private func checkAchievementRequirement(_ achievement: Achievement) -> Bool {
        switch achievement.id {
        case 1: // First Hunt
            return userStats.totalRatsCaught >= 1
        case 2: // Apartment Explorer
            return currentLevel >= 1 // Level 2 completed (0-indexed)
        case 3: // Family Hunter
            return currentLevel >= 2
        case 4: // Office Raider
            return currentLevel >= 3
        case 5: // Hotel Conqueror
            return currentLevel >= 4
        case 6: // Palace Master
            return currentLevel >= 5
        case 7: // Score Starter
            return totalScore >= 500
        case 8: // Score Hunter
            return totalScore >= 2000
        case 9: // Score Master
            return totalScore >= 5000
        case 10: // Speedy Cat
            return userStats.fastestLevelCompletion.values.contains { $0 < 30 }
        case 11: // Lightning Hunter
            return userStats.fastestLevelCompletion.values.contains { $0 < 15 }
        case 12: // Perfect Hunter
            return userStats.perfectRuns.values.contains(true)
        case 13: // Daily Player
            return userStats.consecutiveDaysPlayed >= 3
        case 14: // Week Warrior
            return userStats.consecutiveDaysPlayed >= 7
        case 15: // Master Hunter
            return userStats.totalRatsCaught >= 50
        default:
            return false
        }
    }
    
    // Update the level completion logic to track stats
    func completeLevel(levelId: Int, completionTime: Int, wasPerfect: Bool) {
        userStats.totalGamesPlayed += 1
        userStats.totalRatsCaught += 1
        
        // Track fastest completion
        if let currentFastest = userStats.fastestLevelCompletion[levelId] {
            if completionTime < currentFastest {
                userStats.fastestLevelCompletion[levelId] = completionTime
            }
        } else {
            userStats.fastestLevelCompletion[levelId] = completionTime
        }
        
        // Track perfect runs
        if wasPerfect {
            userStats.perfectRuns[levelId] = true
        }
        
        saveUserStats()
        checkAchievements()
        updateDailyChallengeProgress()
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var gameController = GameController()
    @State private var isAnimating = false
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
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
                                
                                Spacer()
                                
                                // Daily Challenge button with indicator
                                NavigationLink(destination: DailyChallengeView().environmentObject(gameController)) {
                                    ZStack(alignment: .topTrailing) {
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Image(systemName: "calendar.badge.clock")
                                                    .font(.system(size: 28))
                                                    .foregroundColor(.white)
                                                    .shadow(color: .orange, radius: 5)
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [.orange.opacity(0.5), .yellow.opacity(0.5)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 2
                                                    )
                                            )
                                        
                                        // Show indicator if there's an active challenge not completed
                                        if let challenge = gameController.todaysChallenge,
                                           !challenge.isCompleted {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 12, height: 12)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: 2)
                                                )
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                // Achievements button
                                NavigationLink(destination: AchievementsView().environmentObject(gameController)) {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: "trophy.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.white)
                                                .shadow(color: .yellow, radius: 5)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [.yellow.opacity(0.5), .orange.opacity(0.5)],
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
                                
                                // Reset Game Button
                                Button(action: {
                                    showResetConfirmation = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 14))
                                        Text("Reset Game")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .padding(.top, 10)
                                
                            
                                
                                // Mini Games button
                                NavigationLink(destination: MiniGamesView().environmentObject(gameController)) {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white.opacity(0.15))
                                                .frame(width: 70, height: 70)

                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [.green, .teal],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    ),
                                                    lineWidth: 3
                                                )
                                                .frame(width: 70, height: 70)

                                            Image(systemName: "gamecontroller.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.white)
                                                .shadow(color: .green, radius: 5)
                                        }

                                        Text("BRAIN TRAIN")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                
                            
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
            .alert("Reset Game Progress?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    gameController.resetAllProgress()
                }
            } message: {
                Text("This will reset all your progress including scores, achievements, and unlocked levels. This action cannot be undone.")
            }
        }
    }
}



// MARK: - Level Selection View
struct LevelSelectionView: View {
    @EnvironmentObject var gameController: GameController
    @State private var isAnimating = false
    @State private var navigateToGame = false

    var body: some View {
        ZStack {
            // Background
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
                            NavigationLink(
                                destination: GameView()
                                    .environmentObject(gameController)
                                    .onAppear {
                                        // Set the selected level when navigating
                                        gameController.currentLevel = level.id - 1
                                        gameController.setupLevel()
                                    },
                                label: {
                                    LevelCardView(level: level, isLocked: level.id > gameController.unlockedLevels)
                                }
                            )
                            .disabled(level.id > gameController.unlockedLevels)
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



// MARK: - Game View
struct GameView: View {
    @EnvironmentObject var gameController: GameController
    @Environment(\.dismiss) var dismiss
    @State private var showRatCaughtAnimation = false
    @State private var showGameCompleteCelebration = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    @State private var hasShownGameOver = false  // Add this flag
    
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
            
            
            
            // Game over overlay - Add condition to check hasShownGameOver
            if gameController.showGameOver && !hasShownGameOver {
                GameOverView(
                    onRestart: {
                        hasShownGameOver = false
                        gameController.resetGame()
                    },
                    onMenu: {
                        hasShownGameOver = false
                        dismiss()
                    }
                )
                .onAppear {
                    hasShownGameOver = true
                }
            }
            
            
            
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
            
            // Achievement unlocked overlay
            if gameController.showAchievementUnlocked {
                AchievementUnlockedView(
                    achievement: gameController.unlockedAchievement ?? Achievement(
                        id: 0,
                        title: "",
                        description: "",
                        icon: "",
                        requirement: "",
                        pointsReward: 0,
                        category: .levelCompletion
                    ),
                    isPresented: $gameController.showAchievementUnlocked
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
            hasShownGameOver = false  // Reset when view appears
        }
        
        
        .onChange(of: gameController.showLevelComplete) { oldValue, newValue in
            if newValue {
                showRatCaughtAnimation = true
                gameController.showLevelComplete = false
            }
        }
        
        .onChange(of: gameController.showGameComplete) { oldValue, newValue in
            if newValue {
                showGameCompleteCelebration = true
                gameController.showGameComplete = false
            }
        }
        
        
        
        .onChange(of: gameController.showGameOver) { oldValue, newValue in
            if !newValue {
                hasShownGameOver = false  // Reset when game over is dismissed
            }
        }
        
    }
}

// MARK: - Game Components
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

// MARK: - Daily Challenge View with Reset Button
struct DailyChallengeView: View {
    @EnvironmentObject var gameController: GameController
    @Environment(\.dismiss) var dismiss
    @State private var timeRemaining = ""
    @State private var timer: Timer?
    @State private var showResetConfirmation = false
    
    var body: some View {
        ZStack {
            // Background
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
                // Custom Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    Text("DAILY CHALLENGE")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .orange.opacity(0.5), radius: 5)
                    
                    Spacer()
                    
                    // Timer display
                    VStack(spacing: 4) {
                        Text(timeRemaining)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("Resets in")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.3))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 15)
                .background(Color(red: 0.08, green: 0.08, blue: 0.18))
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 15) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.orange, .yellow]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            
                            Text("Today's Special Challenge")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Complete daily challenges to earn bonus points!")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                            
                            // Reset Challenge Button
                            Button(action: {
                                showResetConfirmation = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 14))
                                    Text("Reset Today's Challenge")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .padding(.top, 10)
                        }
                        .padding(.top, 20)
                        
                        if let challenge = gameController.todaysChallenge {
                            // Challenge Card
                            VStack(spacing: 20) {
                                // Challenge header
                                HStack {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(challenge.title)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Text(challenge.description)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    Spacer()
                                    
                                    // Reward badge
                                    VStack(spacing: 4) {
                                        Text("REWARD")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.yellow.opacity(0.8))
                                        
                                        HStack(spacing: 4) {
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.yellow)
                                            
                                            Text("\(challenge.rewardPoints)")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.yellow)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(15)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                
                                // Progress bar
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("PROGRESS")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        Spacer()
                                        
                                        Text("\(challenge.progress)/\(challenge.target)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            // Background
                                            Rectangle()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(height: 12)
                                                .cornerRadius(6)
                                            
                                            // Progress
                                            Rectangle()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [.orange, .yellow]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: progressWidth(in: geometry.size.width, challenge: challenge), height: 12)
                                                .cornerRadius(6)
                                                .shadow(color: .orange.opacity(0.5), radius: 3)
                                            
                                            // Completion indicator
                                            if challenge.isCompleted {
                                                HStack {
                                                    Spacer()
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.green)
                                                        .background(Circle().fill(Color.white).frame(width: 20, height: 20))
                                                }
                                                .padding(.trailing, 4)
                                            }
                                        }
                                    }
                                    .frame(height: 12)
                                }
                                
                                // Status indicator
                                HStack {
                                    Spacer()
                                    
                                    if challenge.isCompleted {
                                        HStack(spacing: 8) {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(.green)
                                            
                                            Text("COMPLETED")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.green)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(20)
                                    } else {
                                        HStack(spacing: 8) {
                                            Image(systemName: "clock.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.orange)
                                            
                                            Text("IN PROGRESS")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.orange)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(20)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .padding(25)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.2)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                            )
                            .padding(.horizontal, 20)
                            
                            // Challenge Tips
                            VStack(alignment: .leading, spacing: 15) {
                                Text("💡 TIPS FOR TODAY")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    TipRow(
                                        icon: "gamecontroller.fill",
                                        text: getTipForChallenge(challenge)
                                    )
                                    
                                    TipRow(
                                        icon: "clock.fill",
                                        text: "Challenge resets daily at midnight"
                                    )
                                    
                                    TipRow(
                                        icon: "star.fill",
                                        text: "Complete to earn bonus points!"
                                    )
                                }
                            }
                            .padding(25)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(20)
                            .padding(.horizontal, 20)
                        } else {
                            // No challenge available
                            VStack(spacing: 20) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                
                                Text("No Challenge Available")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Check back tomorrow for new challenges!")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(40)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(25)
                            .padding(.horizontal, 20)
                        }
                        
                        // Stats Summary
                        VStack(alignment: .leading, spacing: 15) {
                            Text("📊 YOUR STATS")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 15) {
                                StatCard(
                                    title: "Total Games",
                                    value: "\(gameController.userStats.totalGamesPlayed)",
                                    icon: "gamecontroller.fill",
                                    color: .blue
                                )
                                
                                StatCard(
                                    title: "Rats Caught",
                                    value: "\(gameController.userStats.totalRatsCaught)",
                                    icon: "pawprint.fill",
                                    color: .green
                                )
                                
                                StatCard(
                                    title: "Consecutive Days",
                                    value: "\(gameController.userStats.consecutiveDaysPlayed)",
                                    icon: "flame.fill",
                                    color: .orange
                                )
                                
                                StatCard(
                                    title: "Achievements",
                                    value: "\(gameController.achievements.filter { $0.isUnlocked }.count)",
                                    icon: "trophy.fill",
                                    color: .yellow
                                )
                            }
                        }
                        .padding(25)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            updateTimeRemaining()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                updateTimeRemaining()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .alert("Reset Today's Challenge?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                gameController.resetDailyChallenges()
            }
        } message: {
            Text("This will reset today's challenge progress and generate a new one. Your progress will be lost.")
        }
    }
    
    private func progressWidth(in totalWidth: CGFloat, challenge: DailyChallenge) -> CGFloat {
        let progress = CGFloat(challenge.progress) / CGFloat(challenge.target)
        return min(totalWidth * progress, totalWidth)
    }
    
    private func updateTimeRemaining() {
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        let components = calendar.dateComponents([.hour, .minute, .second], from: now, to: tomorrow)
        
        if let hour = components.hour, let minute = components.minute, let second = components.second {
            timeRemaining = String(format: "%02d:%02d:%02d", hour, minute, second)
        }
    }
    
    private func getTipForChallenge(_ challenge: DailyChallenge) -> String {
        switch challenge.challengeType {
        case .completeLevels:
            return "Play through multiple levels to complete this challenge faster"
        case .scorePoints:
            return "Focus on completing levels quickly to earn more points"
        case .quickCompletion:
            return "Plan your route before starting to save time"
        case .perfectRun:
            return "Take your time and think before moving to avoid wrong rooms"
        }
    }
}


// MARK: - Other necessary structs (I'll include the most important ones)
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
        .onChange(of: timeRemaining) { oldValue, newValue in
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

struct CustomBackButton: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left")
                    .font(.headline)
              
            }
            .foregroundColor(.white)
            .padding(8)
            .background(Color.blue.opacity(0.3))
            .cornerRadius(10)
        }
    }
}



// MARK: - Enhanced Room View
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

// MARK: - Floating Controls View
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

// MARK: - Compact Control Button
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

// MARK: - Game Message View
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

// MARK: - Achievements View
struct AchievementsView: View {
    @EnvironmentObject var gameController: GameController
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: Achievement.AchievementCategory?
    
    var categories: [Achievement.AchievementCategory] = [
        .levelCompletion,
        .score,
        .speed,
        .perfection,
        .special
    ]
    
    var categoryNames: [Achievement.AchievementCategory: String] = [
        .levelCompletion: "Levels",
        .score: "Score",
        .speed: "Speed",
        .perfection: "Perfection",
        .special: "Special"
    ]
    
    var categoryIcons: [Achievement.AchievementCategory: String] = [
        .levelCompletion: "flag.fill",
        .score: "star.fill",
        .speed: "bolt.fill",
        .perfection: "checkmark.circle.fill",
        .special: "sparkles"
    ]
    
    var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return gameController.achievements.filter { $0.category == category }
        }
        return gameController.achievements
    }
    
    var unlockedCount: Int {
        gameController.achievements.filter { $0.isUnlocked }.count
    }
    
    var totalPoints: Int {
        gameController.achievements
            .filter { $0.isUnlocked }
            .reduce(0) { $0 + $1.pointsReward }
    }
    
    var body: some View {
        ZStack {
            // Background
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
            
            // Content
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                          
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    Text("ACHIEVEMENTS")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .blue.opacity(0.5), radius: 5)
                    
                    Spacer()
                    
                    // Progress indicator
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(unlockedCount)/\(gameController.achievements.count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(totalPoints) pts")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 15)
                .background(Color(red: 0.08, green: 0.08, blue: 0.18))
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button(action: {
                            selectedCategory = nil
                        }) {
                            CategoryChip(
                                title: "All",
                                icon: "trophy.fill",
                                isSelected: selectedCategory == nil,
                                count: gameController.achievements.count,
                                unlocked: unlockedCount
                            )
                        }
                        
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                let categoryAchievements = gameController.achievements.filter { $0.category == category }
                                let unlockedInCategory = categoryAchievements.filter { $0.isUnlocked }.count
                                
                                CategoryChip(
                                    title: categoryNames[category] ?? "",
                                    icon: categoryIcons[category] ?? "trophy.fill",
                                    isSelected: selectedCategory == category,
                                    count: categoryAchievements.count,
                                    unlocked: unlockedInCategory
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                }
                .background(Color.white.opacity(0.05))
                
                // Achievements List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementCard(achievement: achievement)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let unlocked: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                
                Text("\(unlocked)/\(count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .yellow : .white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            isSelected ?
            AnyView(LinearGradient(
                gradient: Gradient(colors: [.blue, .purple]),
                startPoint: .leading,
                endPoint: .trailing
            )) :
            AnyView(Color.white.opacity(0.1))
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.blue.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon with status
            ZStack {
                Circle()
                    .fill(
                        achievement.isUnlocked ?
                        LinearGradient(
                            gradient: Gradient(colors: [.yellow, .orange]),
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [.gray.opacity(0.3), .gray.opacity(0.1)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(
                                achievement.isUnlocked ? Color.yellow : Color.gray,
                                lineWidth: 2
                            )
                    )
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.isUnlocked ? .white : .gray)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            .onAppear {
                if achievement.isUnlocked {
                    isAnimating = true
                }
            }
            
            // Achievement details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(achievement.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.9))
                    
                    Spacer()
                    
                    if achievement.isUnlocked {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            
                            Text("\(achievement.pointsReward)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(10)
                    }
                }
                
                Text(achievement.description)
                    .font(.system(size: 14))
                    .foregroundColor(achievement.isUnlocked ? .white.opacity(0.8) : .white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
                
                // Requirement and status
                HStack {
                    Text(achievement.requirement)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(achievement.isUnlocked ? .green : .white.opacity(0.5))
                    
                    Spacer()
                    
                    if achievement.isUnlocked, let date = achievement.unlockedDate {
                        Text(unlockedDateString(date))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            Group {
                if achievement.isUnlocked {
                    LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.2)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    Color.white.opacity(0.05)
                }
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    achievement.isUnlocked ? Color.blue.opacity(0.5) : Color.white.opacity(0.1),
                    lineWidth: 1
                )
        )
    }
    
    private func unlockedDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Tip Row
struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.orange)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(15)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Pause Menu View
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

// MARK: - Rat Caught Celebration
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

// MARK: - Confetti View
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

struct GameOverView: View {
    let onRestart: () -> Void
    let onMenu: () -> Void
    @State private var hasPlayedSound = false  // Add this to track if sound played

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
                    Button(action: {
                        onRestart()
                    }) {
                        Text("TRY AGAIN")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(15)
                    }

                    Button(action: {
                        onMenu()
                    }) {
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
        .onAppear {
            // Ensure we only show the game over once
            if !hasPlayedSound {
                hasPlayedSound = true
            }
        }
    }
}


// MARK: - Game Complete Celebration
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

// MARK: - Achievement Unlocked View
struct AchievementUnlockedView: View {
    let achievement: Achievement
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }
                
                VStack(spacing: 20) {
                    // Trophy animation
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [.yellow.opacity(0.3), .clear]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(scale)
                        
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.yellow, .orange]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .scaleEffect(scale)
                    }
                    
                    // Title
                    VStack(spacing: 10) {
                        Text("ACHIEVEMENT UNLOCKED!")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.yellow)
                            .multilineTextAlignment(.center)
                        
                        Text(achievement.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Description
                    Text(achievement.description)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    // Reward
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.yellow)
                        
                        Text("+\(achievement.pointsReward) POINTS")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Tap to continue
                    Text("Tap anywhere to continue")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 10)
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
                .shadow(color: .yellow.opacity(0.3), radius: 30)
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        scale = 1.0
                        opacity = 1
                    }
                }
            }
            .transition(.opacity)
        }
    }
}

// MARK: - Menu Card (Optional - if used)
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

// MARK: - How to Play Supporting Views
struct HowToPlayView: View {
    @Environment(\.dismiss) var dismiss

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
                // Custom navigation bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }

                    Spacer()

                    Text("HOW TO PLAY")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
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

// MARK: - How to Play Supporting Views
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

// MARK: - Stars Background (Optional)
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


// MARK: - Mini Games Menu View
struct MiniGamesView: View {
    @EnvironmentObject var gameController: GameController
    @Environment(\.dismiss) var dismiss
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background
            GeometryReader { geometry in
                Image("puzzle_background")
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
                // Custom Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                           
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    Text("BRAIN TRAIN")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .green.opacity(0.5), radius: 5)
                    
                    Spacer()
                    
                    // Mini Games Points
                    VStack(spacing: 4) {
                        Text("POINTS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green.opacity(0.8))
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                            
                            Text("\(gameController.miniGamesScore)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.3))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 15)
                .background(Color(red: 0.08, green: 0.08, blue: 0.18))
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 15) {
                            HStack(spacing: 15) {
                                Image("cat")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                                    .animation(
                                        Animation.linear(duration: 20)
                                            .repeatForever(autoreverses: false),
                                        value: isAnimating
                                    )
                                
                                Image(systemName: "puzzlepiece.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.green, .teal]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                
                                Image("rat")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .rotationEffect(.degrees(isAnimating ? -360 : 0))
                                    .animation(
                                        Animation.linear(duration: 20)
                                            .repeatForever(autoreverses: false),
                                        value: isAnimating
                                    )
                            }
                            
                            Text("CatRat BRAIN TRAIN")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Fun BRAIN TRAIN featuring our favorite characters!")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Memory Match Game Card
                        NavigationLink(destination: MemoryMatchGameView().environmentObject(gameController)) {
                            GameCardView(
                                title: "MEMORY MATCH",
                                subtitle: "Match cat and rat cards",
                                icon: "photo.fill.on.rectangle.fill",
                                gradient: [.purple, .pink],
                                isLocked: false,
                                highScore: gameController.memoryMatchHighScore
                            )
                            .padding(.horizontal, 20)
                        }
                      
                    
                        // Instructions
                        VStack(alignment: .leading, spacing: 15) {
                            Text("🎮 HOW TO PLAY")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                TipRow(
                                    icon: "star.fill",
                                    text: "Earn points by completing BRAIN TRAIN"
                                )
                                
                                TipRow(
                                    icon: "trophy.fill",
                                    text: "Beat high scores to unlock achievements"
                                )
                                
                                TipRow(
                                    icon: "gamecontroller.fill",
                                    text: "More games coming in future updates!"
                                )
                            }
                        }
                        .padding(25)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { isAnimating = true }
    }
}


// MARK: - Game Card View
struct GameCardView: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let isLocked: Bool
    let highScore: Int
    @State private var isAnimating = false
    
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
                
                if highScore > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                        
                        Text("High Score: \(highScore)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: gradient),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
            }
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
        .shadow(color: gradient[0].opacity(0.5), radius: 20)
        .onAppear { if !isLocked { isAnimating = true } }
    }
}


// MARK: - Memory Match Game
struct MemoryMatchGameView: View {
    @EnvironmentObject var gameController: GameController
    @Environment(\.dismiss) var dismiss
    @StateObject private var memoryGame = MemoryMatchGame()
    @State private var showGameOver = false
    @State private var showWinScreen = false
    
    var body: some View {
        ZStack {
            // Background
            GeometryReader { geometry in
                Image("puzzle_background")
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
                // Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                           
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    Text("MEMORY MATCH")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Game Stats
                    VStack(spacing: 4) {
                        Text("MOVES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("\(memoryGame.moves)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 15)
                .background(Color(red: 0.08, green: 0.08, blue: 0.18))
                
                // Timer
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                    
                    Text(timeString(from: memoryGame.timeRemaining))
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("PAIRS: \(memoryGame.matchedPairs)/\(memoryGame.totalPairs)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Game Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ForEach(memoryGame.cards) { card in
                        MemoryCardView(card: card)
                            .aspectRatio(1, contentMode: .fit)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    memoryGame.selectCard(card)
                                    
                                    if memoryGame.matchedPairs == memoryGame.totalPairs {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            showWinScreen = true
                                            gameController.updateMiniGameScore(points: memoryGame.calculateScore())
                                        }
                                    }
                                }
                            }
                    }
                }
                .padding(20)
                
                // Game Controls
                HStack(spacing: 20) {
                    Button(action: {
                        memoryGame.resetGame()
                    }) {
                        Text("RESTART")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        memoryGame.togglePause()
                    }) {
                        Text(memoryGame.isPaused ? "RESUME" : "PAUSE")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(15)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .blur(radius: memoryGame.isPaused ? 3 : 0)
            
            // Pause Overlay
            if memoryGame.isPaused {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 20) {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text("GAME PAUSED")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Button(action: {
                                memoryGame.togglePause()
                            }) {
                                Text("RESUME")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 12)
                                    .background(Color.green)
                                    .cornerRadius(15)
                            }
                        }
                    )
            }
            
            // Win Screen
            if showWinScreen {
                GameWinScreen(
                    moves: memoryGame.moves,
                    time: memoryGame.timeRemaining,
                    score: memoryGame.calculateScore(),
                    onPlayAgain: {
                        memoryGame.resetGame()
                        showWinScreen = false
                    },
                    onMenu: {
                        dismiss()
                    }
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            memoryGame.startGame()
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Memory Match Game Model
class MemoryMatchGame: ObservableObject {
    @Published var cards: [MemoryCard] = []
    @Published var moves = 0
    @Published var matchedPairs = 0
    @Published var timeRemaining = 60
    @Published var isPaused = false
    @Published var selectedCards: [MemoryCard] = []
    
    var totalPairs: Int { cards.count / 2 }
    private var timer: Timer?
    
    init() {
        setupGame()
    }
    
    func setupGame() {
        let symbols = ["cat", "rat", "pawprint", "bone", "fish", "cheese", "mouse", "bird"]
        
        var newCards: [MemoryCard] = []
        for symbol in symbols {
            let card1 = MemoryCard(id: UUID(), symbol: symbol, isFaceUp: false, isMatched: false)
            let card2 = MemoryCard(id: UUID(), symbol: symbol, isFaceUp: false, isMatched: false)
            newCards.append(contentsOf: [card1, card2])
        }
        
        cards = newCards.shuffled()
        resetGame()
    }
    
    func startGame() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused, self.timeRemaining > 0 else { return }
            self.timeRemaining -= 1
            
            if self.timeRemaining == 0 {
                self.gameOver()
            }
        }
    }
    
    func selectCard(_ card: MemoryCard) {
        guard !card.isFaceUp, !card.isMatched, selectedCards.count < 2, !isPaused else { return }
        
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index].isFaceUp = true
            selectedCards.append(cards[index])
            
            if selectedCards.count == 2 {
                moves += 1
                checkForMatch()
            }
        }
    }
    
    private func checkForMatch() {
        guard selectedCards.count == 2 else { return }
        
        let card1 = selectedCards[0]
        let card2 = selectedCards[1]
        
        if card1.symbol == card2.symbol {
            // Match found
            if let index1 = cards.firstIndex(where: { $0.id == card1.id }),
               let index2 = cards.firstIndex(where: { $0.id == card2.id }) {
                cards[index1].isMatched = true
                cards[index2].isMatched = true
                matchedPairs += 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.selectedCards.removeAll()
                }
            }
        } else {
            // No match
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if let index1 = self.cards.firstIndex(where: { $0.id == card1.id }),
                   let index2 = self.cards.firstIndex(where: { $0.id == card2.id }) {
                    self.cards[index1].isFaceUp = false
                    self.cards[index2].isFaceUp = false
                }
                self.selectedCards.removeAll()
            }
        }
    }
    
    func calculateScore() -> Int {
        let timeBonus = timeRemaining * 10
        let movesBonus = max(0, 100 - moves * 5)
        let pairsBonus = matchedPairs * 50
        
        return timeBonus + movesBonus + pairsBonus
    }
    
    func resetGame() {
        timer?.invalidate()
        moves = 0
        matchedPairs = 0
        timeRemaining = 60
        selectedCards.removeAll()
        
        for i in 0..<cards.count {
            cards[i].isFaceUp = false
            cards[i].isMatched = false
        }
        
        cards = cards.shuffled()
        startGame()
    }
    
    func togglePause() {
        isPaused.toggle()
        if isPaused {
            timer?.invalidate()
        } else {
            startGame()
        }
    }
    
    private func gameOver() {
        timer?.invalidate()
        // Game over logic here
    }
}

struct MemoryCard: Identifiable {
    let id: UUID
    let symbol: String
    var isFaceUp: Bool
    var isMatched: Bool
}

struct MemoryCardView: View {
    let card: MemoryCard
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            if card.isFaceUp || card.isMatched {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: card.isMatched ? [.green, .teal] : [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                    )
                
                if card.symbol == "cat" {
                    Image("cat")
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                } else if card.symbol == "rat" {
                    Image("rat")
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                } else {
                    Image(systemName: symbolToIcon(card.symbol))
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .yellow]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                    )
                
                Image(systemName: "questionmark")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        .onChange(of: card.isFaceUp) { oldValue, newValue in
            if newValue {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    rotation = 360
                }
            } else {
                rotation = 0
            }
        }
    }
    
    private func symbolToIcon(_ symbol: String) -> String {
        switch symbol {
        case "pawprint": return "pawprint.fill"
        case "bone": return "bone.fill"
        case "fish": return "fish.fill"
        case "cheese": return "circle.fill"
        case "mouse": return "computermouse.fill"
        case "bird": return "bird.fill"
        default: return "questionmark"
        }
    }
}




// MARK: - Game Win Screen
struct GameWinScreen: View {
    let moves: Int
    let time: Int
    let score: Int
    let onPlayAgain: () -> Void
    let onMenu: () -> Void
    @State private var confetti = false
    @State private var scale: CGFloat = 0.1
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Trophy
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
                
                Text("YOU WIN!")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .yellow, radius: 10)
                
                // Stats
                VStack(spacing: 15) {
                    StatRow(icon: "arrow.right.arrow.left", label: "Moves", value: "\(moves)")
                    StatRow(icon: "timer", label: "Time Left", value: "\(time) sec")
                    StatRow(icon: "star.fill", label: "Score", value: "\(score)")
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                
                // Buttons
                VStack(spacing: 15) {
                    Button(action: onPlayAgain) {
                        Text("PLAY AGAIN")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(15)
                    }
                    
                    Button(action: onMenu) {
                        Text("BACK TO MENU")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                }
            }
            .padding(40)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.purple.opacity(0.8), .blue.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(30)
            .scaleEffect(scale)
            .shadow(color: .yellow.opacity(0.5), radius: 50)
            
            // Confetti
            if confetti {
                ConfettiView()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                confetti = true
            }
        }
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.yellow)
                
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}
