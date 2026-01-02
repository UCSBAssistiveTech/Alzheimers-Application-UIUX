import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: – Main View orchestrating all four tests, with slide screens
// ─────────────────────────────────────────────────────────────────────────────
struct ReactionGameView: View {
    // which slide we’re on (0 = no slide; 1..4 = “Test 1/4”…“Test 4/4”)
    @State private var slidePhase: Int = 0

    // which screen is active
    @State private var showStartScreen           = true
    @State private var showReflexDotGame         = false
    @State private var showOptokineticTest       = false
    @State private var showChromaticPupillometry = false

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
                    Text("Test \(slidePhase)/4")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.black)
                        .onAppear {
                            let current = slidePhase
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                slidePhase = 0
                                switch current {
                                case 1:
                                    // Test 1/4 → Reaction‐Time Game
                                    break
                                case 2:
                                    showReflexDotGame = true
                                case 3:
                                    showOptokineticTest = true
                                case 4:
                                    showChromaticPupillometry = true
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
                            You will get \(maxAttempts) attempts. Then you’ll proceed through 3 more vision tests.
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
                            showReflexDotGame   = false
                            showOptokineticTest = false
                            showChromaticPupillometry = false

                            // show slide 1/4 first
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
                         && !showChromaticPupillometry
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
                                // done with reaction test → show Test 2/4
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
                        // after reflex-dot, show Test 3/4
                        slidePhase = 3
                    }

                // ─── 4) Optokinetic Test ─────────────────────────────────
                } else if showOptokineticTest {
                    OptokineticTestView(isShowing: $showOptokineticTest)
                        .onDisappear {
                            // after optokinetic, show Test 4/4
                            slidePhase = 4
                        }

                // ─── 5) Chromatic Pupillometry Test ──────────────────────
                } else if showChromaticPupillometry {
                    ChromaticPupillometryView(isShowing: $showChromaticPupillometry)

                // ─── 6) Final End Screen ─────────────────────────────────
                } else {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("All Tests Complete!")
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
// MARK: – Subview: Reflex-Dot Game
// ─────────────────────────────────────────────────────────────────────────────
struct ReflexDotGameView: View {
    @Binding var isShowing: Bool
    var hitPercentageHandler: (Double) -> Void

    private let totalCircles = 5
    private let maxCycles     = 3
    private let speedUpFactor : Double = 0.95

    @State private var currentDelay    = 1.0
    @State private var highlightedIndex = 0
    @State private var forward         = true
    @State private var hitCount        = 0
    @State private var missCount       = 0
    @State private var cycleCount      = 0
    @State private var isRunning       = true

    var body: some View {
        VStack(spacing: 30) {
            Text("Tap the red circle!")
                .font(.title)
                .foregroundColor(.white)

            Text("Hit Rate: \(hitPercentage, specifier: "%.0f")%")
                .font(.headline)
                .foregroundColor(.yellow)

            HStack(spacing: 30) {
                ForEach(0..<totalCircles, id: \.self) { i in
                    Circle()
                        .fill(i == highlightedIndex ? .red : .gray)
                        .frame(width: 100, height: 100)
                        .scaleEffect(i == highlightedIndex ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 0.2), value: highlightedIndex)
                        .onTapGesture {
                            if i == highlightedIndex { hitCount += 1 }
                            else                    { missCount += 1 }
                        }
                }
            }

            if !isRunning {
                Button("Finish") {
                    hitPercentageHandler(hitPercentage)
                    isShowing = false
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear(perform: startHighlighting)
    }

    private var hitPercentage: Double {
        let total = hitCount + missCount
        return total > 0 ? (Double(hitCount) / Double(total) * 100) : 0
    }

    private func startHighlighting() {
        guard isRunning else { return }
        Timer.scheduledTimer(withTimeInterval: currentDelay, repeats: false) { _ in
            if forward {
                highlightedIndex += 1
                if highlightedIndex == totalCircles - 1 {
                    forward = false
                    cycleCount += 1
                }
            } else {
                highlightedIndex -= 1
                if highlightedIndex == 0 {
                    forward = true
                    cycleCount += 1
                }
            }

            if cycleCount >= maxCycles {
                isRunning = false
            } else {
                currentDelay *= speedUpFactor
                startHighlighting()
            }
        }
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
// MARK: – Subview: Chromatic Pupillometry Test (Test 4)
// ─────────────────────────────────────────────────────────────────────────────
struct ChromaticPupillometryView: View {
    @Binding var isShowing: Bool
    
    // Test States
    @State private var isInstructionPhase = true
    @State private var isDarkAdaptationPhase = false
    @State private var isTestingPhase = false
    @State private var backgroundColor = Color.black
    
    // Data tracking
    @State private var currentRound = 1
    // DEMO CHANGE: Set total rounds to 1
    private let totalRounds = 1
    
    // Text feedback
    @State private var statusText = ""
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            if isInstructionPhase {
                VStack(spacing: 30) {
                    Text("Chromatic Pupillometry")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Label("WARNING: Flashing Lights", systemImage: "exclamationmark.triangle.fill")
                            .font(.title3)
                            .foregroundColor(.yellow)
                        
                        Text("This test involves flashing blue lights. \nPlease confirm you have been pre-screened for Epilepsy.")
                            .font(.body)
                            .foregroundColor(.white)
                        
                        Text("Procedure:")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("1. Dark adaptation (10 seconds)\n2. You will see brief flashes of blue light.\n3. Keep your eyes open and focus on the screen.")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    
                    Button("Start Test") {
                        startDarkAdaptation()
                    }
                    .font(.title2)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .frame(maxWidth: 600)
                
            } else if isDarkAdaptationPhase {
                // Just the black background (no text as requested)
            }
            // During testing phase, screen is mostly black or blue, no text needed per PDF
        }
    }
    
    private func startDarkAdaptation() {
        isInstructionPhase = false
        isDarkAdaptationPhase = true
        backgroundColor = .black
        
        // 10 seconds dark adaptation as requested (demo mode)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            isDarkAdaptationPhase = false
            isTestingPhase = true
            startTestingRounds()
        }
    }
    
    private func startTestingRounds() {
        guard isTestingPhase else { return }
        runRound(roundIndex: 1)
    }
    
    // Recursive function to handle the rounds
    private func runRound(roundIndex: Int) {
        if roundIndex > totalRounds {
            // Test Complete
            isShowing = false
            return
        }
        
        currentRound = roundIndex
        
        // Sequence for one round:
        // Flash 1 (1s) -> Intermission (3s) -> Flash 2 (1s) -> Intermission (3s) -> Flash 3 (1s) -> Intermission (3s)
        
        runFlashSequence(count: 1) {
            // Round complete, start next round
            runRound(roundIndex: roundIndex + 1)
        }
    }
    
    // Recursive function to handle the 3 flashes per round
    private func runFlashSequence(count: Int, completion: @escaping () -> Void) {
        if count > 3 {
            completion()
            return
        }
        
        // 1. Flash Blue Light (approx 460-485 nm)
        // Using standard Blue which is approx 470nm in RGB color space
        withAnimation(.linear(duration: 0.1)) {
            backgroundColor = Color.blue
        }
        
        // Flash duration: 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 2. Intermission (Black Screen)
            withAnimation(.linear(duration: 0.1)) {
                backgroundColor = Color.black
            }
            
            // Intermission duration: 3 seconds (DEMO MODE)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                // Next flash in the sequence
                runFlashSequence(count: count + 1, completion: completion)
            }
        }
    }
}


// ─────────────────────────────────────────────────────────────────────────────
// MARK: – Preview
// ─────────────────────────────────────────────────────────────────────────────
struct ReactionGameView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionGameView()
            .previewDevice("Apple Vision Pro")
    }
}
