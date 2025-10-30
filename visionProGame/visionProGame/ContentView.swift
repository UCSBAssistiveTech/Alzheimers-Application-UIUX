import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: – Main View orchestrating all three tests, with slide screens
// ─────────────────────────────────────────────────────────────────────────────
struct ReactionGameView: View {
    // which slide we’re on (0 = no slide; 1,2,3 = “Test 1/3”…“Test 3/3”)
    @State private var slidePhase: Int = 0

    // which screen is active
    @State private var showStartScreen     = true
    @State private var showReflexDotGame   = false
    @State private var showOptokineticTest = false

    // reaction‐time game state
    @State private var targetPosition      = CGPoint.zero
    @State private var lastPosition        = CGPoint.zero
    @State private var deltaX: CGFloat     = 0
    @State private var deltaY: CGFloat     = 0
    @State private var totalDeltaX: CGFloat = 0
    @State private var totalDeltaY: CGFloat = 0
    @State private var finalHitPercentage: Double = 0
    @State private var reactionTime: TimeInterval = 0
    @State private var totalReactionTime: TimeInterval = 0
    @State private var targetAppearedTime: Date?
    @State private var attemptCount        = 0
    @State private var finalCode: String = ""
    
    private let maxAttempts = 5
    private let blueDotSize: CGFloat = 100
    private let redDotSize: CGFloat  = 20

    private var averageReactionTime: TimeInterval {
        guard attemptCount > 0 else { return 0 }
        return totalReactionTime / Double(attemptCount)
    }
    private var averageDeltaX: CGFloat {
        guard attemptCount > 0 else { return 0 }
        return totalDeltaX / CGFloat(attemptCount)
    }
    private var averageDeltaY: CGFloat {
        guard attemptCount > 0 else { return 0 }
        return totalDeltaY / CGFloat(attemptCount)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ─── SLIDE SCREEN ───────────────────────────────────────
                if slidePhase > 0 {
                    Color.white.ignoresSafeArea()
                    Text("Test \(slidePhase)/3")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.black)
                        .onAppear {
                            let current = slidePhase
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                slidePhase = 0
                                switch current {
                                case 1:
                                    // Test 1/3 → Reaction‐Time Game
                                    // (no flag needed; will fall through to attemptCount < maxAttempts block)
                                    break
                                case 2:
                                    showReflexDotGame = true
                                case 3:
                                    showOptokineticTest = true
                                default:
                                    break
                                }
                            }
                        }

                // ─── 1) Start Screen ────────────────────────────────────
                } else if showStartScreen {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("Reaction Time Game")
                            .font(.largeTitle)
                            .foregroundColor(.white)

                        Text("""
                            When the blue circle appears, gaze at it and pinch to tap as quickly as you can. \
                            You will get \(maxAttempts) attempts. After that, you’ll be tested on your reflexes.
                            """)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button("Start Game") {
                            // reset all state
                            attemptCount        = 0
                            reactionTime        = 0
                            totalReactionTime   = 0
                            deltaX              = 0
                            deltaY              = 0
                            totalDeltaX         = 0
                            totalDeltaY         = 0
                            finalHitPercentage  = 0
                            lastPosition        = .zero
                            showStartScreen     = false

                            // show slide 1/3 first
                            slidePhase = 1
                        }
                        .font(.title2)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(width: geo.size.width * 0.8)
                    .position(x: geo.size.width/2, y: geo.size.height/2)

                // ─── 2) Reaction‐Time Gameplay ───────────────────────────
                } else if attemptCount < maxAttempts
                         && !showReflexDotGame
                         && !showOptokineticTest
                {
                    Color.black.ignoresSafeArea()
                    // fixed red dot
                    Circle()
                        .fill(Color.red)
                        .frame(width: redDotSize, height: redDotSize)
                        .position(x: geo.size.width/2, y: geo.size.height/2)

                    // moving blue target
                    Circle()
                        .fill(Color.blue)
                        .frame(width: blueDotSize, height: blueDotSize)
                        .position(targetPosition)
                        .onAppear { spawnTarget(in: geo.size) }
                        .focusable(true)
                        .onTapGesture {
                            guard let appear = targetAppearedTime else { return }
                            reactionTime = Date().timeIntervalSince(appear)
                            totalReactionTime += reactionTime
                            attemptCount += 1

                            if attemptCount < maxAttempts {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    reactionTime = 0
                                    spawnTarget(in: geo.size)
                                }
                            } else {
                                // done with reaction test → show Test 2/3
                                slidePhase = 2
                            }
                        }

                    // stats overlay
                    VStack(spacing: 6) {
                        if reactionTime > 0 {
                            Text("Reaction: \(reactionTime, specifier: "%.2f") s")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        Text("Δx: \(deltaX, specifier: "%.0f"), Δy: \(deltaY, specifier: "%.0f")")
                            .font(.body)
                            .foregroundColor(.yellow)
                    }
                    .position(x: geo.size.width/2, y: 50)

                // ─── 3) Reflex‐Dot Game ──────────────────────────────────
                } else if showReflexDotGame {
                    ReflexDotGameView(
                        isShowing: $showReflexDotGame,
                        hitPercentageHandler: { pct in finalHitPercentage = pct }
                    )
                    .onDisappear {
                        // after reflex-dot, show Test 3/3
                        slidePhase = 3
                    }

                // ─── 4) Optokinetic Test ─────────────────────────────────
                } else if showOptokineticTest {
                    OptokineticTestView(isShowing: $showOptokineticTest)

                // ─── 5) Final End Screen ─────────────────────────────────
                } else {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("Game Over!")
                            .font(.largeTitle)
                            .foregroundColor(.green)

                        Text("Your average reaction time:")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("\(averageReactionTime, specifier: "%.2f") s")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)

                        Text("Average Δx: \(averageDeltaX, specifier: "%.0f")")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("Average Δy: \(averageDeltaY, specifier: "%.0f")")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("Dot Hit Accuracy: \(finalHitPercentage, specifier: "%.0f")%")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Final Score: \(finalCode)")
                        .font(.title2)
                        .foregroundColor(.white)
                        .onAppear {
                            if finalCode.isEmpty {
                                finalCode = generateRandomCode()
                            }
                        }

                        Button("Play Again") {
                            showStartScreen = true
                        }
                        .font(.title2)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(width: geo.size.width * 0.8)
                    .position(x: geo.size.width/2, y: geo.size.height/2)
                }
            }
        }
    }

    /// spawn a new blue dot away from center
    private func spawnTarget(in size: CGSize) {
        guard attemptCount < maxAttempts else { return }
        lastPosition = targetPosition
        let pad: CGFloat = 50
        let center = CGPoint(x: size.width/2, y: size.height/2)
        let minDist = (redDotSize + blueDotSize)/2

        var x: CGFloat, y: CGFloat
        repeat {
            x = .random(in: pad...(size.width - pad))
            y = .random(in: pad...(size.height - pad))
        } while hypot(x - center.x, y - center.y) < minDist

        targetPosition       = CGPoint(x: x, y: y)
        deltaX               = x - lastPosition.x
        deltaY               = y - lastPosition.y
        totalDeltaX         += abs(deltaX)
        totalDeltaY         += abs(deltaY)
        targetAppearedTime   = Date()
    }
    private func generateRandomCode() -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return String((0..<14).map { _ in chars.randomElement()! })
    }
}


// ─────────────────────────────────────────────────────────────────────────────
// MARK: – Subview: Reflex-Dot Game (repurposed so the circle moves side-to-side)
// ─────────────────────────────────────────────────────────────────────────────
struct ReflexDotGameView: View {
    @Binding var isShowing: Bool
    var hitPercentageHandler: (Double) -> Void

    // --- Tunables ---
    private let circleSize: CGFloat = 60
    private let duration: TimeInterval = 12        // total run time (s)
    private let omega: Double = 0.8                // angular speed (rad/s)
    private let rampTime: TimeInterval = 0.8       // ease in/out time (s)

    // --- State ---
    @State private var startDate = Date()
    @State private var finished = false

    @State private var hitCount = 0
    @State private var missCount = 0
    
    @State private var currentX: CGFloat = 0
    @State private var currentY: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 8) {
                    Text("Smooth Pursuit")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Track the blue circle with your eyes.")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.headline)
                }
                .position(x: geo.size.width/2, y: 80)

                // Continuous side-to-side motion
                TimelineView(.animation) { timeline in
                    let t = timeline.date.timeIntervalSince(startDate)
                    let progress = clamp01(t / duration)
                    let eased = easeInOut(t: t, total: duration, ramp: rampTime)

                    let centerY = geo.size.height / 2
                    let centerX = geo.size.width / 2
                    let amplitude = geo.size.width * 0.35   // horizontal travel
                    let x = centerX + amplitude * CGFloat(sin(omega * t)) * CGFloat(eased)

                    Circle()
                        .fill(Color.blue)
                        .frame(width: circleSize, height: circleSize)
                        .position(x: x, y: centerY)
                        .shadow(radius: 8)
                        .onChange(of: x) {
                            self.currentX = x
                            self.currentY = centerY
                        }
                        .onChange(of: progress) {
                            if progress >= 1.0 && !finished {
                                finished = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    hitPercentageHandler(hitPercentage)
                                    isShowing = false
                                }
                            }
                        }
                }
                VStack(spacing: 6) {
                    Text("Hits: \(hitCount)").foregroundColor(.green)
                    Text("Misses: \(missCount)").foregroundColor(.red)
                    Text("Accuracy: \(hitPercentage, specifier: "%.0f")%").foregroundColor(.yellow)
                }
                .font(.headline)
                .position(x: geo.size.width/2, y: geo.size.height - 100)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let loc = value.location
                        let dx = loc.x - currentX
                        let dy = loc.y - currentY
                        let r = circleSize / 2
                        if (dx*dx + dy*dy) <= (r*r) {
                            hitCount += 1     // tap inside = hit
                        } else {
                            missCount += 1    // tap outside = miss
                        }
                    }
            )
            .onAppear { startDate = Date() }
        }
    }
    
    private var hitPercentage: Double {
        let total = hitCount + missCount
        return total > 0 ? (Double(hitCount) / Double(total) * 100.0) : 0
    }
    
    // Helpers
    private func clamp01(_ x: Double) -> Double { max(0, min(1, x)) }

    // Smoothstep-style ease in/out with ramp at both ends
    private func easeInOut(t: TimeInterval, total: TimeInterval, ramp: TimeInterval) -> Double {
        if total <= 0 { return 1 }
        if t <= 0 { return 0 }
        if t >= total { return 0 } // fade to stop at the end

        if t < ramp {
            let u = t / ramp
            return u * u * (3 - 2*u) // smooth step
        }
        if t <= total - ramp {
            return 1
        }
        let v = (total - t) / ramp
        return v * v * (3 - 2*v)
    }
}



// ─────────────────────────────────────────────────────────────────────────────
// MARK: – Subview: Optokinetic Test
// ─────────────────────────────────────────────────────────────────────────────
struct OptokineticTestView: View {
    @Binding var isShowing: Bool
    @State private var phase: Int         = 0
    @State private var offset: CGFloat    = 0
    @State private var stripes: [CGFloat] = []

    private let redDotSize: CGFloat = 40

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if phase == 0 {
                VStack(spacing: 16) {
                    Text("Optokinetic")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.black)

                    Text("Look at the red dot in the center")
                        .font(.title2)
                        .foregroundColor(.black)
                }
                .multilineTextAlignment(.center)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        phase = 1
                    }
                }

            } else {
                GeometryReader { geo in
                    ZStack {
                        HStack(spacing: 20) {
                            ForEach(stripes.indices, id: \.self) { i in
                                Rectangle()
                                    .fill(Color(.darkGray))
                                    .frame(width: stripes[i], height: geo.size.height)
                            }
                        }
                        .offset(x: offset)
                        .onAppear {
                            stripes = generateStripes(totalWidth: geo.size.width * 2)
                            offset = 0
                            withAnimation(.linear(duration: 7)) {
                                offset = -2 * geo.size.width
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                                isShowing = false
                            }
                        }

                        Circle()
                            .fill(Color.red)
                            .frame(width: redDotSize, height: redDotSize)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    }
                }
            }
        }
    }

    private func generateStripes(totalWidth: CGFloat) -> [CGFloat] {
        var arr: [CGFloat] = []
        var sum: CGFloat = 0
        while sum < totalWidth {
            let w = CGFloat.random(in: 20...80)
            arr.append(w)
            sum += w + 20
        }
        return arr
    }
}



// ─────────────────────────────────────────────────────────────────────────────
// MARK: – Preview
// ─────────────────────────────────────────────────────────────────────────────
struct ReactionGameView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ReactionGameView()
                .previewDevice("Apple Vision Pro")
                .previewDisplayName("Vision Pro")

            ReactionGameView()
                .previewDevice("iPhone 15 Pro")
                .previewDisplayName("iPhone 15 Pro")
        }
    }
}
