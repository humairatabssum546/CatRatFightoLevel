



import SwiftUI
import AVFoundation
import AudioToolbox

// MARK: - Enhanced Data Models
struct Room: Identifiable {
    let id: Int
    let name: String
    var containsRat: Bool = false
    var containsBoost: Bool = false
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

struct Rat: Identifiable {
    let id: Int
    var currentRoom: Int
    var isCaught: Bool = false
    var points: Int
    var speed: TimeInterval
    var color: String
    var lastMoveTime: Date = Date()
}

//struct Boost: Identifiable {
//    let id = UUID()
//    let type: BoostType
//    let value: CGFloat
//    let position: CGPoint
//    var isCollected: Bool = false
//    
//    enum BoostType: String {
//        case milk = "🥛"
//        case fish = "🐟"
//        case cheese = "🧀"
//        case energy = "⚡"
//    }
//}


struct Boost: Identifiable {
    let id = UUID()
    let type: BoostType
    let value: CGFloat
    var position: CGPoint
    var isCollected: Bool = false
    
    enum BoostType: String {
        case milk = "🥛"
        case fish = "🐟"
        case cheese = "🧀"
        case energy = "⚡"
    }
}





struct GameLevel: Identifiable {
    let id: Int
    let name: String
    let rooms: [Room]
    let catStartPosition: CGPoint
    let rats: [Rat]
    let boosts: [Boost]
    let basePoints: Int
    let description: String
    let optimalPathLength: Int
    let timeLimit: Int
    let ratMoveInterval: TimeInterval
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
        case ratsCaught
        case energyCollected
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
        case catchRats
        case collectEnergy
    }
}

struct UserStats: Codable {
    var totalGamesPlayed: Int = 0
    var totalRatsCaught: Int = 0
    var totalDistanceTraveled: CGFloat = 0
    var fastestLevelCompletion: [Int: Int] = [:]
    var perfectRuns: [Int: Bool] = [:]
    var consecutiveDaysPlayed: Int = 0
    var lastPlayDate: Date?
    var totalEnergyCollected: Int = 0
    var totalBoostsCollected: Int = 0
    var totalRatsByColor: [String: Int] = [:]
}


// ToastView.swift
import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType
    
    enum ToastType: String, Equatable {
        case success
        case warning
        case info
        case error
        
        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .info: return .blue
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(type.color.opacity(0.9))
        .cornerRadius(12)
        .shadow(color: type.color.opacity(0.5), radius: 10)
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct ToastModifier: ViewModifier {
    
    
    @Binding var toast: ToastItem?
       @State private var workItem: DispatchWorkItem?
       
       struct ToastItem: Identifiable, Equatable { // ✅ Equatable شامل کریں
           let id = UUID()
           let message: String
           let type: ToastView.ToastType
           let duration: Double
           
           // ✅ Equatable کے لیے required function
           static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
               return lhs.id == rhs.id &&
                      lhs.message == rhs.message &&
                      lhs.type == rhs.type
           }
       }
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    if let toast = toast {
                        VStack {
                            ToastView(message: toast.message, type: toast.type)
                                .onAppear {
                                    let task = DispatchWorkItem {
                                        withAnimation {
                                            self.toast = nil
                                        }
                                    }
                                    self.workItem = task
                                    DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
                                }
                            Spacer()
                        }
                        .padding(.top, 50)
                    }
                }
            )
            .onChange(of: toast) { _, newValue in
                if let newValue = newValue {
                    workItem?.cancel()
                    let task = DispatchWorkItem {
                        withAnimation {
                            self.toast = nil
                        }
                    }
                    workItem = task
                    DispatchQueue.main.asyncAfter(deadline: .now() + newValue.duration, execute: task)
                }
            }
    }
}

extension View {
    func toastView(toast: Binding<ToastModifier.ToastItem?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}


// MARK: - Rat Caught Animation View
struct RatCaughtAnimationView: View {
    let ratColor: String
    let points: Int
    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var catRotation: Double = 0
    @State private var ratRotation: Double = 0
    @State private var showBlood = false
    @State private var bloodOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // Main animation
            VStack(spacing: 20) {
                ZStack {
                    // Blood effect
                    if showBlood {
                        ForEach(0..<8) { i in
                            Circle()
                                .fill(Color.red)
                                .frame(width: CGFloat.random(in: 20...40))
                                .position(
                                    x: CGFloat.random(in: 100...300),
                                    y: CGFloat.random(in: 100...300)
                                )
                                .opacity(bloodOpacity)
                                .animation(
                                    Animation.easeOut(duration: 0.5)
                                        .delay(Double(i) * 0.1),
                                    value: showBlood
                                )
                        }
                        
                        // Blood splatter
                        Image(systemName: "drop.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                            .rotationEffect(.degrees(45))
                            .opacity(bloodOpacity)
                            .scaleEffect(isAnimating ? 1.5 : 1.0)
                    }
                    
                    // Cat and Rat fight scene
                    HStack(spacing: 40) {
                        // Cat attacking
                        VStack {
                            Image("cat")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(catRotation))
                                .scaleEffect(isAnimating ? 1.2 : 1.0)
                                .shadow(color: .orange, radius: 10)
                                .overlay(
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.orange)
                                        .offset(y: -50)
                                        .opacity(isAnimating ? 1 : 0)
                                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                                )
                            
                            Text("😼")
                                .font(.system(size: 30))
                                .scaleEffect(isAnimating ? 1.5 : 1.0)
                        }
                        
                        // Fight icon
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                            .scaleEffect(isAnimating ? 1.5 : 1.0)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        
                        // Rat being caught
                        VStack {
                            Image("rat")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(ratRotation))
                                .scaleEffect(isAnimating ? 0.8 : 1.0)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30)
                                        .stroke(Color.red, lineWidth: 3)
                                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                                        .opacity(isAnimating ? 0 : 1)
                                )
                            
                            Text("💀")
                                .font(.system(size: 30))
                                .opacity(isAnimating ? 1 : 0)
                                .scaleEffect(isAnimating ? 1.5 : 0.5)
                        }
                    }
                }
                .scaleEffect(scale)
                
                // Message
                VStack(spacing: 10) {
                    Text("RAT CAUGHT!")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .red, radius: 10)
                    
                    Text("\(ratColor.capitalized) Rat")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                    
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        
                        Text("+\(points) POINTS")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                            .shadow(color: .orange, radius: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.yellow, lineWidth: 2)
                    )
                }
                .opacity(opacity)
            }
            .padding(30)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.9), .red.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(30)
            .shadow(color: .red.opacity(0.5), radius: 20)
        }
        .onAppear {
            // Start animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1
            }
            
            // Cat attack animation
            withAnimation(Animation.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
                catRotation = 15
                isAnimating = true
            }
            
            // Rat shake animation
            withAnimation(Animation.easeInOut(duration: 0.2).repeatCount(5, autoreverses: true)) {
                ratRotation = -10
            }
            
            // Blood effect after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.easeIn(duration: 0.3)) {
                    showBlood = true
                    bloodOpacity = 0.7
                }
                
                // Hide blood after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        bloodOpacity = 0
                    }
                }
            }
            
            // Auto dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.3)) {
                    scale = 0.1
                    opacity = 0
                }
            }
        }
    }
}

// MARK: - Enhanced Game Controller
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
    @Published var isRatVisible = false
    @Published var timeRemaining: Int = 0
    @Published var isGamePaused = false
    @Published var showGameOver = false
    @Published var showGameComplete = false
    @Published var isGameOver = false
    
    @Published var toast: ToastModifier.ToastItem?
    
    
    
    @Published var showRatCaughtAnimation = false
     @Published var ratCaughtAnimationColor = ""
     @Published var ratCaughtAnimationPoints = 0
    
    // New properties for enhanced gameplay
    @Published var rats: [Rat] = []
    @Published var boosts: [Boost] = []
    @Published var catEnergy: CGFloat = 100.0
    @Published var catSpeed: CGFloat = 0.05
    @Published var catSpeedMultiplier: CGFloat = 1.0
    @Published var catEnergyDrainRate: CGFloat = 0.1
    @Published var remainingRats: Int = 0
    @Published var collectedBoosts: Int = 0
    @Published var ratMoveTimer: Timer?
    @Published var activeRats: [Rat] = []
    
    // Mini Games Properties
    @Published var miniGamesScore = 0
    @Published var memoryMatchHighScore = 0
    
    // Achievements and challenges
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
    private var ratMoveInterval: TimeInterval = 5.0
    
    // Sound file names
    private let ratCaughtSound = "rat_caught"
    private let gameOverSound = "game_over"
    private let buttonSound = "button_click"
    private let boostSound = "boost_collected"
    private let energySound = "energy_collected"
    
    var currentLevelTimeLimit: Int {
        return levels[currentLevel].timeLimit
    }
    
    let levels: [GameLevel] = [

        
        GameLevel(
               id: 1,
               name: "BEGINNER'S HOUSE",
               rooms: [
                   Room(id: 1, name: "LIVING", position: CGPoint(x: 0.3, y: 0.3), connectedRooms: [2], doors: []),
                   Room(id: 2, name: "KITCHEN", position: CGPoint(x: 0.7, y: 0.3), connectedRooms: [1], doors: [])
               ],
               catStartPosition: CGPoint(x: 0.3, y: 0.3),
               rats: [
                   Rat(id: 1, currentRoom: 2, points: 100, speed: 8.0, color: "gray")
               ],
               boosts: [
                   // ✅ Boost کو room کے قریب رکھیں
                   Boost(type: .milk, value: 20, position: CGPoint(x: 0.4, y: 0.4))
               ],
               basePoints: 100,
               description: "Simple two-room layout",
               optimalPathLength: 1,
               timeLimit: 30,
               ratMoveInterval: 15.0
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
            rats: [
                Rat(id: 1, currentRoom: 4, points: 150, speed: 7.0, color: "gray"),
                Rat(id: 2, currentRoom: 3, points: 100, speed: 6.5, color: "brown")
            ],
            boosts: [
                Boost(type: .milk, value: 20, position: CGPoint(x: 0.3, y: 0.4)),
                Boost(type: .fish, value: 30, position: CGPoint(x: 0.6, y: 0.5))
            ],
            basePoints: 200,
            description: "Four rooms with multiple paths",
            optimalPathLength: 2,
            timeLimit: 60,
            ratMoveInterval: 13.0
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
            rats: [
                Rat(id: 1, currentRoom: 6, points: 200, speed: 6.0, color: "gray"),
                Rat(id: 2, currentRoom: 5, points: 150, speed: 5.5, color: "brown"),
                Rat(id: 3, currentRoom: 4, points: 100, speed: 5.0, color: "white")
            ],
            boosts: [
                Boost(type: .milk, value: 20, position: CGPoint(x: 0.4, y: 0.3)),
                Boost(type: .fish, value: 30, position: CGPoint(x: 0.6, y: 0.6)),
                Boost(type: .cheese, value: 25, position: CGPoint(x: 0.3, y: 0.7))
            ],
            basePoints: 300,
            description: "Six-room family house",
            optimalPathLength: 3,
            timeLimit: 90,
            ratMoveInterval: 11.0
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
            rats: [
                Rat(id: 1, currentRoom: 6, points: 250, speed: 5.0, color: "gray"),
                Rat(id: 2, currentRoom: 4, points: 200, speed: 4.5, color: "brown"),
                Rat(id: 3, currentRoom: 3, points: 150, speed: 4.0, color: "white"),
                Rat(id: 4, currentRoom: 5, points: 100, speed: 3.5, color: "black")
            ],
            boosts: [
                Boost(type: .milk, value: 20, position: CGPoint(x: 0.4, y: 0.4)),
                Boost(type: .fish, value: 30, position: CGPoint(x: 0.6, y: 0.6)),
                Boost(type: .cheese, value: 25, position: CGPoint(x: 0.5, y: 0.8)),
                Boost(type: .energy, value: 50, position: CGPoint(x: 0.3, y: 0.6))
            ],
            basePoints: 400,
            description: "Modern office layout",
            optimalPathLength: 4,
            timeLimit: 120,
            ratMoveInterval: 9.0
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
            rats: [
                Rat(id: 1, currentRoom: 8, points: 300, speed: 4.0, color: "gray"),
                Rat(id: 2, currentRoom: 7, points: 250, speed: 3.5, color: "brown"),
                Rat(id: 3, currentRoom: 6, points: 200, speed: 3.0, color: "white"),
                Rat(id: 4, currentRoom: 5, points: 150, speed: 2.5, color: "black"),
                Rat(id: 5, currentRoom: 4, points: 100, speed: 2.0, color: "gold")
            ],
            boosts: [
                Boost(type: .milk, value: 20, position: CGPoint(x: 0.4, y: 0.2)),
                Boost(type: .fish, value: 30, position: CGPoint(x: 0.6, y: 0.4)),
                Boost(type: .cheese, value: 25, position: CGPoint(x: 0.4, y: 0.6)),
                Boost(type: .energy, value: 50, position: CGPoint(x: 0.6, y: 0.8)),
                Boost(type: .energy, value: 75, position: CGPoint(x: 0.5, y: 0.7))
            ],
            basePoints: 500,
            description: "Luxury hotel challenge",
            optimalPathLength: 5,
            timeLimit: 150,
            ratMoveInterval: 7.0
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
            rats: [
                Rat(id: 1, currentRoom: 12, points: 500, speed: 3.0, color: "gold"),
                Rat(id: 2, currentRoom: 11, points: 400, speed: 2.5, color: "black"),
                Rat(id: 3, currentRoom: 10, points: 300, speed: 2.0, color: "white"),
                Rat(id: 4, currentRoom: 9, points: 200, speed: 1.5, color: "brown"),
                Rat(id: 5, currentRoom: 8, points: 150, speed: 1.0, color: "gray"),
                Rat(id: 6, currentRoom: 7, points: 100, speed: 0.5, color: "gray")
            ],
            boosts: [
                Boost(type: .milk, value: 30, position: CGPoint(x: 0.4, y: 0.4)),
                Boost(type: .fish, value: 40, position: CGPoint(x: 0.6, y: 0.4)),
                Boost(type: .cheese, value: 35, position: CGPoint(x: 0.4, y: 0.8)),
                Boost(type: .energy, value: 100, position: CGPoint(x: 0.6, y: 0.8)),
                Boost(type: .energy, value: 150, position: CGPoint(x: 0.5, y: 0.6)),
                Boost(type: .energy, value: 200, position: CGPoint(x: 0.5, y: 0.9))
            ],
            basePoints: 1000,
            description: "Ultimate palace challenge",
            optimalPathLength: 6,
            timeLimit: 180,
            ratMoveInterval: 6.0
        )
    ]
    
    init() {
        loadSavedData()
        setupLevel()
        startRatVisibilityAnimation()
        initializeAchievements()
        loadDailyChallenges()
        loadUserStats()
        checkDailyLogin()
        loadMiniGamesProgress()
    }
    
    private func showRatCaughtToast(color: String, points: Int) {
            toast = ToastModifier.ToastItem(
                message: "🐭 \(color.capitalized) Rat Caught! +\(points) points",
                type: .success,
                duration: 2.0
            )
        }
        
        private func showBoostToast(type: Boost.BoostType, value: Int) {
            toast = ToastModifier.ToastItem(
                message: "\(type.rawValue) Energy +\(value)%",
                type: .info,
                duration: 2.0
            )
        }
        
        private func showSpeedBoostToast() {
            toast = ToastModifier.ToastItem(
                message: "⚡ SPEED BOOST! 2x Speed for 10 seconds!",
                type: .warning,
                duration: 3.0
            )
        }
    

    
    func setupLevel() {
        
        wrongRoomsCount = 0
          let level = levels[currentLevel]
          
          var rooms = level.rooms
          for i in 0..<rooms.count {
              rooms[i].isHighlighted = false
              rooms[i].containsBoost = false
          }
        
        // ✅ Level 1 کے لیے special handling
        if currentLevel == 0 {
            // Level 1 کے لیے boosts کی positions adjust کریں
            let adjustedBoosts = level.boosts
            if adjustedBoosts.count > 0 {

            }
            boosts = adjustedBoosts
        } else {
            boosts = level.boosts
        }
        
        for boost in boosts {
            if let roomIndex = rooms.firstIndex(where: {
                let distance = hypot($0.position.x - boost.position.x,
                                   $0.position.y - boost.position.y)
                return distance < 0.2 // ✅ Distance threshold بڑھا دیں
            }) {
                rooms[roomIndex].containsBoost = true
            }
        }
    
        
        currentRooms = rooms
        rats = level.rats
        activeRats = level.rats
        remainingRats = rats.count
        boosts = level.boosts
        collectedBoosts = 0
        
        catPosition = level.catStartPosition
        catEnergy = 100.0
        catSpeedMultiplier = 1.0
        timeRemaining = level.timeLimit
        showGameOver = false
        showGameComplete = false
        isGamePaused = false
        isGameOver = false
        
        startTimer()
        startRatMovementTimer()
        
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
        
        message = "Find \(remainingRats) rats in the \(level.name)! You have \(timeRemaining) seconds..."
        highlightRoom(at: catPosition)
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.isGamePaused && self.timeRemaining > 0 && self.remainingRats > 0 {
                self.timeRemaining -= 1
                
                if self.timeRemaining == 30 {
                    self.message = "30 seconds remaining! Hurry up!"
                } else if self.timeRemaining == 10 {
                    self.message = "10 seconds left! Catch those rats quickly!"
                } else if self.timeRemaining <= 5 {
                    self.message = "\(self.timeRemaining) seconds left!"
                }
                
                if self.timeRemaining <= 0 && !self.isGameOver {
                    self.gameOver()
                }
            }
        }
    }
    
    private func startRatMovementTimer() {
        ratMoveTimer?.invalidate()
        let level = levels[currentLevel]
        ratMoveInterval = level.ratMoveInterval
        
        ratMoveTimer = Timer.scheduledTimer(withTimeInterval: ratMoveInterval, repeats: true) { [weak self] _ in
            guard let self = self, !self.isGamePaused, !self.isGameOver else { return }
            
            for i in 0..<self.activeRats.count {
                if !self.activeRats[i].isCaught {
                    self.moveRat(&self.activeRats[i])
                }
            }
            
            self.rats = self.activeRats.filter { !$0.isCaught }
            
            if self.rats.isEmpty && self.activeRats.allSatisfy({ $0.isCaught }) {
                self.levelComplete()
            }
        }
    }
    
    private func moveRat(_ rat: inout Rat) {
        guard let currentRoomIndex = currentRooms.firstIndex(where: { $0.id == rat.currentRoom }) else { return }
        
        let currentRoom = currentRooms[currentRoomIndex]
        let connectedRooms = currentRoom.connectedRooms
        
        if let newRoomId = connectedRooms.randomElement(),
           let newRoomIndex = currentRooms.firstIndex(where: { $0.id == newRoomId }) {
            
            rat.currentRoom = newRoomId
            rat.lastMoveTime = Date()
            
            if Int.random(in: 1...3) == 1 {
                let roomName = currentRooms[newRoomIndex].name
                message = "A rat moved to \(roomName)!"
            }
        }
    }
    
    private func gameOver() {
        guard !isGameOver else { return }
        
        isGameOver = true
        timer?.invalidate()
        ratMoveTimer?.invalidate()
        message = "⏰ Time's up! \(remainingRats) rats escaped!"
        showGameOver = true
        
        playSound(named: gameOverSound)
    }

    
    private func levelComplete() {
        timer?.invalidate()
        ratMoveTimer?.invalidate()
        
        let completionTime = levels[currentLevel].timeLimit - timeRemaining
        let wasPerfect = wrongRoomsCount == 0
        
        // ✅ ADD THIS DEBUG LINE
        let actuallyCaughtRats = activeRats.filter { $0.isCaught }.count
        print("DEBUG: Level Complete - \(actuallyCaughtRats) rats caught out of \(activeRats.count)")
        
        calculateFinalScore()
        completeLevel(levelId: currentLevel, completionTime: completionTime, wasPerfect: wasPerfect)
        
        message = "🎉 ALL RATS CAUGHT! You earned \(currentScore) points!"
        showLevelComplete = true
        
        if currentLevel + 1 < levels.count {
            unlockedLevels = max(unlockedLevels, currentLevel + 2)
            saveProgress()
        }
        
        saveProgress()
    }
    
    

    
    func completeLevel(levelId: Int, completionTime: Int, wasPerfect: Bool) {
        userStats.totalGamesPlayed += 1
        
        // ✅ Correct rat count
        let ratsCaughtInLevel = activeRats.filter { $0.isCaught }.count
        userStats.totalRatsCaught += ratsCaughtInLevel
        
        print("Level \(levelId): \(ratsCaughtInLevel) rats caught")
        
        if let currentFastest = userStats.fastestLevelCompletion[levelId] {
            if completionTime < currentFastest {
                userStats.fastestLevelCompletion[levelId] = completionTime
            }
        } else {
            userStats.fastestLevelCompletion[levelId] = completionTime
        }
        
        if wasPerfect {
            userStats.perfectRuns[levelId] = true
        }
        
        saveUserStats()
        checkAchievements()
        updateDailyChallengeProgress()
    }
    

    
    func togglePause() {
        isGamePaused.toggle()
        if isGamePaused {
            timer?.invalidate()
            ratMoveTimer?.invalidate()
            message = "Game Paused"
        } else {
            startTimer()
            startRatMovementTimer()
            message = "Game Resumed"
        }
        
        playSound(named: buttonSound)
    }
    
    func playSound(named soundName: String) {
        if let path = Bundle.main.path(forResource: soundName, ofType: "mp3") {
            let url = URL(fileURLWithPath: path)
            
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error)")
            }
        } else {
            let systemSound: SystemSoundID
            switch soundName {
            case "rat_caught":
                systemSound = 1001
            case "game_over":
                systemSound = 1002
            case "boost_collected":
                systemSound = 1003
            case "energy_collected":
                systemSound = 1004
            default:
                systemSound = 1104
            }
            AudioServicesPlaySystemSound(systemSound)
        }
    }
    
    enum Direction {
        case up, down, left, right
    }
    
    func moveCat(direction: Direction) {
        if remainingRats == 0 || isGamePaused || catEnergy <= 0 {
            if catEnergy <= 0 {
                message = "No energy! Find boosts to restore energy!"
            }
            return
        }
        
        let moveDistance = catSpeed * catSpeedMultiplier
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
            catEnergy = max(0, catEnergy - catEnergyDrainRate)
            
            catPosition = newPosition
            
            if let room = getRoomAtPosition(newPosition) {
                highlightRoom(at: newPosition)
                checkRoomForRats(room)
                checkRoomForBoosts(room)
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
    

    func checkRoomForRats(_ room: Room) {
        let ratsInRoom = rats.filter { $0.currentRoom == room.id && !$0.isCaught }
        
        if !ratsInRoom.isEmpty {
            for i in 0..<activeRats.count {
                if activeRats[i].currentRoom == room.id && !activeRats[i].isCaught {
                    activeRats[i].isCaught = true
                    let ratPoints = activeRats[i].points
                    currentScore += ratPoints
                    
                    userStats.totalRatsByColor[activeRats[i].color, default: 0] += 1
                    userStats.totalRatsCaught += 1 // ✅ یہ لائن پہلے سے موجود ہے
                    
                    playSound(named: ratCaughtSound)
                    
                    // ✅ Show rat caught animation
                    ratCaughtAnimationColor = activeRats[i].color
                    ratCaughtAnimationPoints = ratPoints
                    showRatCaughtAnimation = true
                    
                    // ✅ Auto hide animation after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showRatCaughtAnimation = false
                    }
                    
                    // ✅ Toast message
                    showRatCaughtToast(color: activeRats[i].color, points: ratPoints)
                    
                    remainingRats = max(0, remainingRats - 1)
                    
                    updateDailyChallengeForRatsCaught()
                    
                    // ✅ Rats array update
                    rats = activeRats.filter { !$0.isCaught }
                    
                    // ✅ Force UI update
                    objectWillChange.send()
                    
                    if remainingRats == 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.levelComplete()
                        }
                    }
                    
                    break
                }
            }
        } else {
            wrongRoomsCount += 1
            message = "No rats in \(room.name). Keep searching!"
        }
    }
    

    func checkRoomForBoosts(_ room: Room) {
      
        for i in 0..<boosts.count {
            let boost = boosts[i]
            

            let distance = hypot(
                boost.position.x - room.position.x,
                boost.position.y - room.position.y
            )
            
           
            if distance < 0.2 && !boost.isCollected {
                boosts[i].isCollected = true
                collectedBoosts += 1
                
                let boost = boosts[i]
                let boostValue = boost.value
                
                switch boost.type {
                case .milk, .fish, .cheese:
                    catEnergy = min(100, catEnergy + boostValue)
                    message = "\(boost.type.rawValue) Energy restored! +\(Int(boostValue))"
                    playSound(named: energySound)
                    
                    showBoostToast(type: boost.type, value: Int(boostValue))
                    
                case .energy:
                    catSpeedMultiplier = 2.0
                    message = "⚡ Speed boost activated! 2x speed for 10 seconds!"
                    playSound(named: boostSound)
                    
                    showSpeedBoostToast()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        if self.catSpeedMultiplier == 2.0 {
                            self.catSpeedMultiplier = 1.0
                            self.message = "Speed boost ended."
                        }
                    }
                }
                
                currentScore += Int(boostValue)
                
                userStats.totalEnergyCollected += Int(boostValue)
                userStats.totalBoostsCollected += 1
                
                updateDailyChallengeForEnergyCollected(amount: Int(boostValue))
                
               
                if let roomIndex = currentRooms.firstIndex(where: { $0.id == room.id }) {
                    currentRooms[roomIndex].containsBoost = false
                }
                
                break
            }
        }
    }
    

    private func calculateFinalScore() {
        let level = levels[currentLevel]
        
        let timeBonus = timeRemaining * 10
        let energyBonus = Int(catEnergy) * 2
        let boostBonus = collectedBoosts * 50
        let ratBonus = rats.reduce(0) { $0 + ($1.isCaught ? $1.points : 0) }
        
        currentScore = level.basePoints + timeBonus + energyBonus + boostBonus + ratBonus
        totalScore += currentScore
        
        updateScoreForDailyChallenge(points: currentScore)
        
        saveProgress()
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
            showGameComplete = true
        }
    }
    
    func resetGame() {
        timer?.invalidate()
        ratMoveTimer?.invalidate()
        setupLevel()
    }
    
    func exitToMenu() {
        timer?.invalidate()
        ratMoveTimer?.invalidate()
        isGamePaused = false
    }
    
    // MARK: - Save/Load Progress
    private func loadSavedData() {
        if let savedScore = UserDefaults.standard.object(forKey: "totalScore") as? Int {
            totalScore = savedScore
        }
        
        if let savedUnlockedLevels = UserDefaults.standard.object(forKey: "unlockedLevels") as? Int {
            unlockedLevels = savedUnlockedLevels
        }
        
        if let savedCurrentLevel = UserDefaults.standard.object(forKey: "currentLevel") as? Int {
            currentLevel = savedCurrentLevel
        }
    }
    
    private func saveProgress() {
        UserDefaults.standard.set(totalScore, forKey: "totalScore")
        UserDefaults.standard.set(unlockedLevels, forKey: "unlockedLevels")
        UserDefaults.standard.set(currentLevel, forKey: "currentLevel")
        
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: "achievements")
        }
        
        if let encoded = try? JSONEncoder().encode(userStats) {
            UserDefaults.standard.set(encoded, forKey: "userStats")
        }
    }
    
    func resetAllProgress() {
        totalScore = 0
        unlockedLevels = 1
        currentLevel = 0
        
        for i in 0..<achievements.count {
            achievements[i].isUnlocked = false
            achievements[i].unlockedDate = nil
        }
        
        userStats = UserStats()
        dailyChallenges = []
        generateDailyChallenges()
        
        saveProgress()
        saveUserStats()
        saveDailyChallenges()
        
        setupLevel()
    }
    
    // MARK: - Achievements and Daily Challenges
    private func initializeAchievements() {
        achievements = [
            Achievement(id: 1, title: "First Hunt", description: "Complete your first level", icon: "trophy.fill", requirement: "Complete Level 1", pointsReward: 50, category: .levelCompletion),
            Achievement(id: 2, title: "Apartment Explorer", description: "Complete the Cozy Apartment", icon: "building.2.fill", requirement: "Complete Level 2", pointsReward: 100, category: .levelCompletion),
            Achievement(id: 3, title: "Family Hunter", description: "Complete the Family House", icon: "house.fill", requirement: "Complete Level 3", pointsReward: 150, category: .levelCompletion),
            Achievement(id: 4, title: "Office Raider", description: "Complete the Office Building", icon: "briefcase.fill", requirement: "Complete Level 4", pointsReward: 200, category: .levelCompletion),
            Achievement(id: 5, title: "Hotel Conqueror", description: "Complete the Grand Hotel", icon: "bed.double.fill", requirement: "Complete Level 5", pointsReward: 250, category: .levelCompletion),
            Achievement(id: 6, title: "Palace Master", description: "Complete the Mystery Palace", icon: "crown.fill", requirement: "Complete Level 6", pointsReward: 500, category: .levelCompletion),
            Achievement(id: 7, title: "Score Starter", description: "Reach 500 total points", icon: "star.fill", requirement: "500 total points", pointsReward: 100, category: .score),
            Achievement(id: 8, title: "Score Hunter", description: "Reach 2000 total points", icon: "star.circle.fill", requirement: "2000 total points", pointsReward: 250, category: .score),
            Achievement(id: 9, title: "Score Master", description: "Reach 5000 total points", icon: "star.square.fill", requirement: "5000 total points", pointsReward: 500, category: .score),
            Achievement(id: 10, title: "Speedy Cat", description: "Complete any level in under 30 seconds", icon: "hare.fill", requirement: "Finish level in < 30s", pointsReward: 150, category: .speed),
            Achievement(id: 11, title: "Lightning Hunter", description: "Complete any level in under 15 seconds", icon: "bolt.fill", requirement: "Finish level in < 15s", pointsReward: 300, category: .speed),
            Achievement(id: 12, title: "Rat Catcher", description: "Catch 10 rats total", icon: "pawprint.fill", requirement: "10 rats caught", pointsReward: 100, category: .ratsCaught),
            Achievement(id: 13, title: "Expert Hunter", description: "Catch 50 rats total", icon: "pawprint.circle.fill", requirement: "50 rats caught", pointsReward: 300, category: .ratsCaught),
            Achievement(id: 14, title: "Master Hunter", description: "Catch 100 rats total", icon: "pawprint.square.fill", requirement: "100 rats caught", pointsReward: 500, category: .ratsCaught),
            Achievement(id: 15, title: "Energy Collector", description: "Collect 500 energy total", icon: "bolt.heart.fill", requirement: "500 energy collected", pointsReward: 150, category: .energyCollected),
            Achievement(id: 16, title: "Power Surge", description: "Collect 1000 energy total", icon: "bolt.horizontal.fill", requirement: "1000 energy collected", pointsReward: 300, category: .energyCollected),
            Achievement(id: 17, title: "Daily Player", description: "Play for 3 consecutive days", icon: "flame.fill", requirement: "3 consecutive days", pointsReward: 100, category: .special),
            Achievement(id: 18, title: "Week Warrior", description: "Play for 7 consecutive days", icon: "calendar", requirement: "7 consecutive days", pointsReward: 500, category: .special),
            Achievement(id: 19, title: "Color Collector", description: "Catch rats of all colors", icon: "paintpalette.fill", requirement: "All rat colors", pointsReward: 1000, category: .special)
        ]
        
        loadAchievements()
    }
    
    private func loadDailyChallenges() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let savedDate = UserDefaults.standard.object(forKey: "dailyChallengesDate") as? Date,
           Calendar.current.isDate(savedDate, inSameDayAs: today),
           let savedData = UserDefaults.standard.data(forKey: "dailyChallenges"),
           let savedChallenges = try? JSONDecoder().decode([DailyChallenge].self, from: savedData) {
            
            dailyChallenges = savedChallenges
            todaysChallenge = dailyChallenges.first
            return
        }
        
        generateDailyChallenges()
    }
    
    private func generateDailyChallenges() {
        let today = Calendar.current.startOfDay(for: Date())
        
        let challengeTypes: [DailyChallenge.ChallengeType] = [
            .completeLevels,
            .scorePoints,
            .catchRats,
            .collectEnergy,
            .quickCompletion
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
            
        case .catchRats:
            let target = Int.random(in: 5...15)
            challenge = DailyChallenge(
                id: 3,
                title: "Rat Hunter",
                description: "Catch \(target) rats today",
                challengeType: .catchRats,
                target: target,
                rewardPoints: target * 20,
                date: today
            )
            
        case .collectEnergy:
            let target = Int.random(in: 100...500)
            challenge = DailyChallenge(
                id: 4,
                title: "Energy Gatherer",
                description: "Collect \(target) energy today",
                challengeType: .collectEnergy,
                target: target,
                rewardPoints: target / 5,
                date: today
            )
            
        case .quickCompletion:
            let target = Int.random(in: 1...2)
            challenge = DailyChallenge(
                id: 5,
                title: "Speed Demon",
                description: "Complete \(target) levels in under 60 seconds",
                challengeType: .quickCompletion,
                target: target,
                rewardPoints: 200,
                date: today
            )
            
        default:
            challenge = DailyChallenge(
                id: 1,
                title: "Level Master",
                description: "Complete 1 level today",
                challengeType: .completeLevels,
                target: 1,
                rewardPoints: 50,
                date: today
            )
        }
        
        dailyChallenges = [challenge]
        todaysChallenge = challenge
        
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
                userStats.consecutiveDaysPlayed += 1
            } else if !Calendar.current.isDate(lastPlayDate, inSameDayAs: today) {
                userStats.consecutiveDaysPlayed = 1
            }
        } else {
            userStats.consecutiveDaysPlayed = 1
        }
        
        userStats.lastPlayDate = today
        saveUserStats()
        
        checkAchievements()
    }
    
    
    func updateDailyChallengeProgress() {
        guard var challenge = todaysChallenge else { return }
        
        switch challenge.challengeType {
        case .completeLevels:
            challenge.progress += 1
        case .scorePoints:
            break
        case .quickCompletion:
            let completionTime = levels[currentLevel].timeLimit - timeRemaining
            if completionTime < 60 {
                challenge.progress += 1
            }
        case .perfectRun:
            if wrongRoomsCount == 0 {
                challenge.progress += 1
            }
        case .catchRats:
            break
        case .collectEnergy:
            break
        }
        
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
    
    func updateDailyChallengeForRatsCaught() {
        guard var challenge = todaysChallenge,
              challenge.challengeType == .catchRats else { return }
        
        challenge.progress += 1
        
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
    
    func updateDailyChallengeForEnergyCollected(amount: Int) {
        guard var challenge = todaysChallenge,
              challenge.challengeType == .collectEnergy else { return }
        
        challenge.progress += amount
        
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
                
                totalScore += updatedAchievement.pointsReward
                
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
        case 1: return userStats.totalRatsCaught >= 1
        case 2: return currentLevel >= 1
        case 3: return currentLevel >= 2
        case 4: return currentLevel >= 3
        case 5: return currentLevel >= 4
        case 6: return currentLevel >= 5
        case 7: return totalScore >= 500
        case 8: return totalScore >= 2000
        case 9: return totalScore >= 5000
        case 10: return userStats.fastestLevelCompletion.values.contains { $0 < 30 }
        case 11: return userStats.fastestLevelCompletion.values.contains { $0 < 15 }
        case 12: return userStats.totalRatsCaught >= 10
        case 13: return userStats.totalRatsCaught >= 50
        case 14: return userStats.totalRatsCaught >= 100
        case 15: return userStats.totalEnergyCollected >= 500
        case 16: return userStats.totalEnergyCollected >= 1000
        case 17: return userStats.consecutiveDaysPlayed >= 3
        case 18: return userStats.consecutiveDaysPlayed >= 7
        case 19:
            let colors = ["gray", "brown", "white", "black", "gold"]
            return colors.allSatisfy { userStats.totalRatsByColor[$0, default: 0] > 0 }
        default: return false
        }
    }
    
    
    // MARK: - Mini Games Functions
    func updateMiniGameScore(points: Int) {
        miniGamesScore += points
        
        if points > memoryMatchHighScore {
            memoryMatchHighScore = points
            saveMiniGamesProgress()
        }
        
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

            ForEach(pawPrints) { paw in
                Image(systemName: "pawprint.fill")
                    .foregroundColor(.white.opacity(0.1))
                    .font(.system(size: 20))
                    .position(x: paw.x, y: paw.y)
                    .scaleEffect(paw.scale)
                    .opacity(paw.opacity)
                    .animation(.easeOut(duration: 1), value: paw.opacity)
            }

            ZStack {
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1
                catPosition = CGPoint(x: UIScreen.main.bounds.width * 0.35, y: UIScreen.main.bounds.height * 0.5)
                ratPosition = CGPoint(x: UIScreen.main.bounds.width * 0.65, y: UIScreen.main.bounds.height * 0.5)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isAnimating = true

                for _ in 0..<20 {
                    pawPrints.append(PawPrint(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                        opacity: 0.3,
                        scale: CGFloat.random(in: 0.5...1.5)
                    ))
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 1)) {
                        for i in pawPrints.indices {
                            pawPrints[i].opacity = 0
                        }
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showTitle = true
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    titleScale = 1.0
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showContentView = true
                }
            }
        }
    }
}


struct GameView: View {
    var body: some View {
        EnhancedGameView()
    }
}

// MARK: - Enhanced Game View
struct EnhancedGameView: View {
    @EnvironmentObject var gameController: GameController
    @Environment(\.dismiss) var dismiss
    @State private var showRatCaughtAnimation = false
    @State private var showGameCompleteCelebration = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var hasShownGameOver = false
    
    var body: some View {
        ZStack {
            backgroundView
            mainGameView
            overlayViews
            zoomControls
            
            // ✅ Middle Toast
            if let toast = gameController.toast {
                VStack {
                    Spacer()
                    
                    ToastView(message: toast.message, type: toast.type)
                        .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .scale))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: gameController.toast)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            gameController.toast = nil
                        }
                    }
                }
            }
            
            // ✅ Rat Caught Animation
            if gameController.showRatCaughtAnimation {
                RatCaughtAnimationView(
                    ratColor: gameController.ratCaughtAnimationColor,
                    points: gameController.ratCaughtAnimationPoints
                )
                .transition(.opacity)
                .zIndex(100)
            }
        
            
        
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: CustomBackButton())
        .onAppear {
            gameController.setupLevel()
            hasShownGameOver = false
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
                hasShownGameOver = false
            }
        }
    }
    
    private var backgroundView: some View {
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
    }
    
    private var mainGameView: some View {
        VStack(spacing: 0) {
            EnhancedGameHeaderView()
                .environmentObject(gameController)
                .padding(.horizontal)
                .padding(.top, 10)
            
            gameBoardView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if !gameController.isGamePaused && gameController.remainingRats > 0 && !gameController.showGameOver {
                FloatingControlsView()
                    .environmentObject(gameController)
                    .padding(.vertical, 20)
            }
            
            if !gameController.message.isEmpty {
                GameMessageView(message: gameController.message)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            }
        }
        .blur(radius: gameController.isGamePaused ? 3 : 0)
    }
    
    private var gameBoardView: some View {
        GeometryReader { geometry in
            let boardWidth = max(geometry.size.width, 1000)
            let boardHeight = max(geometry.size.height, 1000)
            
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                gameBoardContent(boardWidth: boardWidth, boardHeight: boardHeight)
                    .frame(width: boardWidth, height: boardHeight)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(scaleGesture)
                    .simultaneousGesture(dragGesture)
                    .onTapGesture(count: 2) {
                        withAnimation {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }
            }
        }
    }
    
    private func gameBoardContent(boardWidth: CGFloat, boardHeight: CGFloat) -> some View {
        ZStack {
            Color.clear
            
            // Draw corridors
            ForEach(gameController.currentDoors, id: \.self) { door in
                corridorView(door: door, boardWidth: boardWidth, boardHeight: boardHeight)
            }
            
            // Draw rooms
            ForEach(gameController.currentRooms) { room in
                EnhancedRoomView(room: room)
                    .position(
                        x: room.position.x * boardWidth,
                        y: room.position.y * boardHeight
                    )
            }

            
            // Draw boosts with better hit area
                   ForEach(gameController.boosts.filter { !$0.isCollected }) { boost in
                       BoostView(boost: boost)
                           .position(
                               x: boost.position.x * boardWidth,
                               y: boost.position.y * boardHeight
                           )
                           .contentShape(Circle().scale(1.5)) // ✅ Hit area بڑھا دیں
                   }
            
            // Draw cat
            Image("cat")
                .resizable()
                .frame(width: 60, height: 60)
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                .position(
                    x: gameController.catPosition.x * boardWidth,
                    y: gameController.catPosition.y * boardHeight
                )
            
            // Draw active rats
            ForEach(gameController.activeRats.filter { !$0.isCaught }) { rat in
                if let room = gameController.currentRooms.first(where: { $0.id == rat.currentRoom }) {
                    RatView(rat: rat)
                        .position(
                            x: room.position.x * boardWidth,
                            y: room.position.y * boardHeight
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
            
        }
    }
    
    private func corridorView(door: Door, boardWidth: CGFloat, boardHeight: CGFloat) -> some View {
        let fromRoom = gameController.getRoom(by: door.fromRoom)
        let toRoom = gameController.getRoom(by: door.toRoom)
        
        return Path { path in
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
    
    private var scaleGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, 0.5), 3.0)
            }
            .onEnded { _ in
                lastScale = 1.0
            }
    }
    
    private var dragGesture: some Gesture {
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
    }
    
    private var overlayViews: some View {
        Group {
            // Game over overlay
            if gameController.showGameOver && !hasShownGameOver {
                gameOverOverlay
            }
            
            // Pause overlay
            if gameController.isGamePaused {
                PauseMenuView()
                    .environmentObject(gameController)
            }
            
            // Level complete celebration
            if showRatCaughtAnimation {
                levelCompleteOverlay
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
        }
    }
    
    private var gameOverOverlay: some View {
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
    
//    private var levelCompleteOverlay: some View {
//        LevelCompleteCelebration(
//            score: gameController.currentScore,
//            ratsCaught: gameController.rats.filter { $0.isCaught }.count,
//            boostsCollected: gameController.collectedBoosts,
//            onNextLevel: {
//                gameController.nextLevel()
//                showRatCaughtAnimation = false
//            },
//            onMenu: {
//                dismiss()
//            },
//            isLastLevel: gameController.currentLevel == gameController.levels.count - 1
//        )
//        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                if !showRatCaughtAnimation {
//                    showRatCaughtAnimation = false
//                }
//            }
//        }
//    }
    
    private var levelCompleteOverlay: some View {
        LevelCompleteCelebration(
            score: gameController.currentScore,
            ratsCaught: gameController.activeRats.filter { $0.isCaught }.count, // ✅ CORRECT
            boostsCollected: gameController.collectedBoosts,
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
    
    
    private var zoomControls: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 10) {
                    zoomButton(icon: "plus.magnifyingglass") {
                        withAnimation {
                            scale = min(scale + 0.2, 3.0)
                        }
                    }
                    
                    zoomButton(icon: "minus.magnifyingglass") {
                        withAnimation {
                            scale = max(scale - 0.2, 0.5)
                        }
                    }
                    
                    zoomButton(icon: "arrow.up.left.and.arrow.down.right") {
                        withAnimation {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func zoomButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .padding()
                .background(Color.black.opacity(0.7))
                .clipShape(Circle())
        }
    }
}


struct EnhancedGameHeaderView: View {
    @EnvironmentObject var gameController: GameController
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Top row
            HStack {
                // Pause button
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
                
                // Level info - FIXED
                VStack(spacing: 5) {
                    Text(gameController.levels[gameController.currentLevel].name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Level \(gameController.currentLevel + 1)/\(gameController.levels.count)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Energy display
                VStack(spacing: 5) {
                    HStack(spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        Text("\(Int(gameController.catEnergy))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(gameController.catEnergy > 30 ? .white : .red)
                    }
                    
                    Text("Energy")
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
                .onAppear { isAnimating = gameController.catEnergy < 30 }
                .onChange(of: gameController.catEnergy) { oldValue, newValue in
                    isAnimating = newValue < 30
                }
            }
            
            // Second row - Stats
            HStack(spacing: 15) {
                // Score display
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    
                    Text("\(gameController.currentScore)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(10)
                
                // Rats remaining
                HStack(spacing: 5) {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(gameController.remainingRats > 0 ? .orange : .green)
                    
                    Text("\(gameController.remainingRats)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(10)
                
                // Speed multiplier
                if gameController.catSpeedMultiplier > 1.0 {
                    HStack(spacing: 5) {
                        Image(systemName: "hare.fill")
                            .foregroundColor(.green)
                        
                        Text("\(String(format: "%.1f", gameController.catSpeedMultiplier))x")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.3))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            
            // Timer display
            TimerDisplayView(timeRemaining: gameController.timeRemaining,
                           totalTime: gameController.currentLevelTimeLimit)
        }
    }
}

// MARK: - Enhanced Room View
struct EnhancedRoomView: View {
    let room: Room
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
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
            
            VStack(spacing: 5) {
                Text(room.name)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(room.isHighlighted ? .orange : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

// MARK: - Rat View
struct RatView: View {
    let rat: Rat
    @State private var isMoving = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 40, height: 10)
                .offset(y: 20)
            
            Circle()
                .fill(ratColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
            
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .fill(Color.black)
                            .frame(width: 3, height: 3)
                    )
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .fill(Color.black)
                            .frame(width: 3, height: 3)
                    )
            }
            .offset(y: -5)
            
            HStack(spacing: 20) {
                Circle()
                    .fill(ratColor)
                    .frame(width: 12, height: 12)
                    .offset(y: -15)
                
                Circle()
                    .fill(ratColor)
                    .frame(width: 12, height: 12)
                    .offset(y: -15)
            }
            
            RoundedRectangle(cornerRadius: 5)
                .fill(ratColor)
                .frame(width: 20, height: 5)
                .rotationEffect(.degrees(45))
                .offset(x: 15, y: 15)
            
            Text("\(rat.points)")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.red.opacity(0.7))
                .cornerRadius(4)
                .offset(y: 25)
        }
        .scaleEffect(isMoving ? 1.1 : 1.0)
        .animation(
            Animation.easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true),
            value: isMoving
        )
        .onAppear { isMoving = true }
    }
    
    private var ratColor: Color {
        switch rat.color {
        case "gray": return Color.gray
        case "brown": return Color.brown
        case "white": return Color.white
        case "black": return Color.black
        case "gold": return Color.yellow
        default: return Color.gray
        }
    }
}


struct BoostView: View {
    let boost: Boost
    @State private var isPulsing = false
    @State private var isFloating = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(boostColor.opacity(0.3))
                .frame(width: 60, height: 60) // ✅ Size بڑھا دیں
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1)
                        .repeatForever(autoreverses: true),
                    value: isPulsing
                )
            
            Text(boost.type.rawValue)
                .font(.system(size: 35)) // ✅ Font size بڑھا دیں
                .shadow(color: .black, radius: 2)
                .offset(y: isFloating ? -5 : 0)
                .animation(
                    Animation.easeInOut(duration: 1)
                        .repeatForever(autoreverses: true),
                    value: isFloating
                )
            
            Text("+\(Int(boost.value))")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(boostColor.opacity(0.8))
                .cornerRadius(6)
                .offset(y: 30)
            
            // ✅ بڑا hit area
            Circle()
                .fill(Color.clear)
                .frame(width: 80, height: 80)
                .contentShape(Circle())
        }
        .onAppear {
            isPulsing = true
            isFloating = true
        }
    
    }
    
    private var boostColor: Color {
        switch boost.type {
        case .milk: return Color.blue
        case .fish: return Color.green
        case .cheese: return Color.yellow
        case .energy: return Color.orange
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

// MARK: - Timer Display View
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

// MARK: - Floating Controls View
struct FloatingControlsView: View {
    @EnvironmentObject var gameController: GameController
    @State private var offset = CGSize.zero
    @State private var controlsCollapsed = false
    @GestureState private var dragOffset = CGSize.zero

    var body: some View {
        ZStack {
            if controlsCollapsed {
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
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Color.clear.frame(width: 40, height: 40)

                        CompactControlButton(
                            icon: "arrow.up",
                            action: { gameController.moveCat(direction: .up) },
                            color: .blue
                        )

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
                        CompactControlButton(
                            icon: "arrow.left",
                            action: { gameController.moveCat(direction: .left) },
                            color: .blue
                        )

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

                        CompactControlButton(
                            icon: "arrow.right",
                            action: { gameController.moveCat(direction: .right) },
                            color: .blue
                        )
                    }

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

// MARK: - Content View
struct ContentView: View {
    @StateObject private var gameController = GameController()
    @State private var isAnimating = false
    @State private var showResetConfirmation = false

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

                                NavigationLink(destination: EnhancedGameView().environmentObject(gameController)) {
                                    ZStack {
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

                    HStack(spacing: 40) {
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
                        
                        VStack(spacing: 8) {
                            ZStack {
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
                                destination: EnhancedGameView()
                                    .environmentObject(gameController)
                                    .onAppear {
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
                
                Text(level.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isLocked ? .gray : .white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(isLocked ? .gray : .orange)
                    
                    Text("\(level.rats.count) rats")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isLocked ? .gray : .orange)
                }
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(isLocked ? .gray : .blue)
                    
                    Text("\(level.timeLimit / 60):\(String(format: "%02d", level.timeLimit % 60))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isLocked ? .gray : .blue)
                }
                
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

// MARK: - Daily Challenge View
struct DailyChallengeView: View {
    @EnvironmentObject var gameController: GameController
    @Environment(\.dismiss) var dismiss
    @State private var timeRemaining = ""
    @State private var timer: Timer?
    @State private var showResetConfirmation = false
    
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
            
            VStack(spacing: 0) {
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
                            VStack(spacing: 20) {
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
                                            Rectangle()
                                                .fill(Color.white.opacity(0.1))
                                                .frame(height: 12)
                                                .cornerRadius(6)
                                            
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
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("📊 YOUR STATS")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 15) {
                                EnhancedStatCard(
                                    title: "Total Games",
                                    value: "\(gameController.userStats.totalGamesPlayed)",
                                    icon: "gamecontroller.fill",
                                    color: .blue
                                )
                                
                                EnhancedStatCard(
                                    title: "Rats Caught",
                                    value: "\(gameController.userStats.totalRatsCaught)",
                                    icon: "pawprint.fill",
                                    color: .green
                                )
                                
                                EnhancedStatCard(
                                    title: "Energy Collected",
                                    value: "\(gameController.userStats.totalEnergyCollected)",
                                    icon: "bolt.fill",
                                    color: .orange
                                )
                                
                                EnhancedStatCard(
                                    title: "Boosts Collected",
                                    value: "\(gameController.userStats.totalBoostsCollected)",
                                    icon: "star.fill",
                                    color: .yellow
                                )
                                
                                EnhancedStatCard(
                                    title: "Consecutive Days",
                                    value: "\(gameController.userStats.consecutiveDaysPlayed)",
                                    icon: "flame.fill",
                                    color: .red
                                )
                                
                                EnhancedStatCard(
                                    title: "Achievements",
                                    value: "\(gameController.achievements.filter { $0.isUnlocked }.count)",
                                    icon: "trophy.fill",
                                    color: .purple
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
        case .catchRats:
            return "Move quickly between rooms to catch more rats"
        case .collectEnergy:
            return "Collect all boosts in each level for maximum energy"
        default:
            return "Complete daily challenges for bonus rewards!"
        }
    }
}

struct EnhancedStatCard: View {
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
        .special,
        .ratsCaught,
        .energyCollected
    ]
    
    var categoryNames: [Achievement.AchievementCategory: String] = [
        .levelCompletion: "Levels",
        .score: "Score",
        .speed: "Speed",
        .perfection: "Perfection",
        .special: "Special",
        .ratsCaught: "Rats",
        .energyCollected: "Energy"
    ]
    
    var categoryIcons: [Achievement.AchievementCategory: String] = [
        .levelCompletion: "flag.fill",
        .score: "star.fill",
        .speed: "bolt.fill",
        .perfection: "checkmark.circle.fill",
        .special: "sparkles",
        .ratsCaught: "pawprint.fill",
        .energyCollected: "bolt.heart.fill"
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

struct AchievementCard: View {
    let achievement: Achievement
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 15) {
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

// MARK: - Level Complete Celebration
struct LevelCompleteCelebration: View {
    let score: Int
    let ratsCaught: Int
    let boostsCollected: Int
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
            
            VStack(spacing: 20) {
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
                
                Text("LEVEL COMPLETE!")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .yellow, radius: 10)
                
                // Stats display
                VStack(spacing: 15) {
                    StatRowView(icon: "star.fill", label: "SCORE", value: "\(score)")
                    StatRowView(icon: "pawprint.fill", label: "RATS CAUGHT", value: "\(ratsCaught)")
                    StatRowView(icon: "bolt.fill", label: "BOOSTS COLLECTED", value: "\(boostsCollected)")
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                .padding(.horizontal, 30)
                
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
                .padding(.horizontal, 30)
            }
            .padding(.vertical, 40)
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

struct StatRowView: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.yellow)
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
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

// MARK: - Other Views (PauseMenu, GameOver, GameComplete, etc.)
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

struct GameOverView: View {
    let onRestart: () -> Void
    let onMenu: () -> Void
    @State private var hasPlayedSound = false

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

                Image("cat")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                            .offset(y: -30)
                    )

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
            if !hasPlayedSound {
                hasPlayedSound = true
            }
        }
    }
}

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
            .shadow(color: .yellow.opacity(0.5), radius: 50)
            .scaleEffect(scale)

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
                    
                    Text(achievement.description)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
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

// MARK: - Mini Games Views
struct MiniGamesView: View {
    @EnvironmentObject var gameController: GameController
    @Environment(\.dismiss) var dismiss
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
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

// MARK: - How to Play View
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

            VStack(spacing: 0) {
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

                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "GAME OBJECTIVE", color: .orange)

                            BulletPoint(
                                text: "Find and catch all the rats in each level",
                                color: .orange,
                                icon: "magnifyingglass"
                            )

                            BulletPoint(
                                text: "Rats move between rooms - be quick!",
                                color: .orange,
                                icon: "hare.fill"
                            )
                        }
                        .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "ENERGY SYSTEM", color: .blue)

                            BulletPoint(
                                text: "Cat has energy that drains with movement",
                                color: .blue,
                                icon: "bolt.fill"
                            )

                            BulletPoint(
                                text: "Find boosts (🥛🐟🧀⚡) to restore energy",
                                color: .blue,
                                icon: "heart.fill"
                            )

                            BulletPoint(
                                text: "Energy boosts give 2x speed for 10 seconds",
                                color: .blue,
                                icon: "hare.fill"
                            )
                        }
                        .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "SCORING SYSTEM", color: .yellow)

                            BulletPoint(
                                text: "Different colored rats give different points",
                                color: .yellow,
                                icon: "pawprint.fill"
                            )

                            BulletPoint(
                                text: "Gold rats = most points",
                                color: .yellow,
                                icon: "crown.fill"
                            )

                            BulletPoint(
                                text: "Time bonus: Points for remaining time",
                                color: .yellow,
                                icon: "clock.fill"
                            )

                            BulletPoint(
                                text: "Energy bonus: Points for remaining energy",
                                color: .yellow,
                                icon: "bolt.heart.fill"
                            )
                        }
                        .padding(.horizontal, 20)

                        VStack(alignment: .leading, spacing: 15) {
                            SectionHeader(title: "PRO TIPS", color: .purple)

                            BulletPoint(
                                text: "Plan your route to collect boosts efficiently",
                                color: .purple,
                                icon: "lightbulb.fill"
                            )

                            BulletPoint(
                                text: "Watch rat movement patterns",
                                color: .purple,
                                icon: "eye.fill"
                            )

                            BulletPoint(
                                text: "Use speed boosts to catch fast rats",
                                color: .purple,
                                icon: "hare.fill"
                            )

                            BulletPoint(
                                text: "Prioritize high-value rats first",
                                color: .purple,
                                icon: "star.fill"
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

// MARK: - Memory Match Game (simplified version)
struct MemoryMatchGameView: View {
    @EnvironmentObject var gameController: GameController
    @Environment(\.dismiss) var dismiss
    @StateObject private var memoryGame = MemoryMatchGame()
    @State private var showWinScreen = false
    
    var body: some View {
        ZStack {
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
                
                VStack(spacing: 15) {
                    StatRow(icon: "arrow.right.arrow.left", label: "Moves", value: "\(moves)")
                    StatRow(icon: "timer", label: "Time Left", value: "\(time) sec")
                    StatRow(icon: "star.fill", label: "Score", value: "\(score)")
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                
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

