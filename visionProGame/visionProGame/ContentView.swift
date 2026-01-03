import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// MARK: – Main View orchestrating all FIVE tests, with slide screens
// ─────────────────────────────────────────────────────────────────────────────
struct ReactionGameView: View {
    // which slide we’re on (0 = no slide; 1..5 = “Test 1/5”…“Test 5/5”)
    @State private var slidePhase: Int = 0

    // which screen is active
    @State private var showStartScreen           = true
    @State private var showReflexDotGame         = false
    @State private var showOptokineticTest       = false
    @State private var showChromaticPupillometry = false
    @State private var showWorkingMemoryTest     = false // Test 5
    
    // Explicit state to track when the entire suite is done
    @State private var isGameOver                = false

    // Test 1 (Prosaccade) state
    @State private var targetPosition      = CGPoint.zero
    @State private var showProsaccadeTarget = false
    @State private var attemptCount        = 0
    @State private var finalCode: String = ""
    
    // Config for Test 1
    private let maxProsaccadeDots = 5
    private let prosaccadeDotDuration = 0.8
    private let prosaccadeInterval = 3.0
    private let blueDotSize: CGFloat = 100
    private let redDotSize: CGFloat  = 20

    // Stats
    @State private var finalHitPercentage: Double = 0
    @State private var workingMemoryScore: Int = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ─── SLIDE SCREEN ───────────────────────────────────────
                if slidePhase > 0 {
                    Color.white.ignoresSafeArea()
                    Text("Test \(slidePhase)/5")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.black)
                        .onAppear {
                            let current = slidePhase
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                slidePhase = 0
                                switch current {
                                case 1:
                                    // Start Test 1 Sequence
                                    startProsaccadeSequence(in: geo.size)
                                case 2:
                                    showReflexDotGame = true
                                case 3:
                                    showOptokineticTest = true
                                case 4:
                                    showChromaticPupillometry = true
                                case 5:
                                    showWorkingMemoryTest = true
                                default:
                                    break
                                }
                            }
                        }

                // ─── 1) Start Screen (Instructions) ─────────────────────
                } else if showStartScreen {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("Prosaccade Test")
                            .font(.largeTitle)
                            .foregroundColor(.white)

                        ScrollView {
                            Text("""
                                Please follow the appearing dots as soon as you see them appear to the best of your ability. \
                                A central point in the form of a white circle will be present at the beginning of the trial and will remain throughout the duration of the test. \
                                A red dot will appear at various angles relative to the central point every 3 seconds at random and remain for 800 milliseconds. \
                                Track the dot with your head positioned still as soon as you see it appear, then once the dot disappears, reset your view to the central point until the next point appears.
                                """)
                                .font(.title3)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        .frame(maxHeight: 300)

                        Button("Start Test") {
                            // reset all state
                            attemptCount        = 0
                            showProsaccadeTarget = false
                            showStartScreen     = false
                            showReflexDotGame   = false
                            showOptokineticTest = false
                            showChromaticPupillometry = false
                            showWorkingMemoryTest     = false
                            isGameOver          = false

                            // show slide 1/5 first
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

                // ─── 2) Test 1: Prosaccade ──────────────────────────────
                } else if attemptCount < maxProsaccadeDots
                         && !showReflexDotGame
                         && !showOptokineticTest
                         && !showChromaticPupillometry
                         && !showWorkingMemoryTest
                         && !isGameOver
                {
                    Color.black.ignoresSafeArea()
                    
                    // Central fixation point: White dot
                    Circle()
                        .fill(Color.white)
                        .frame(width: redDotSize, height: redDotSize)
                        .position(x: geo.size.width/2, y: geo.size.height/2)

                    // Peripheral target: Red dot
                    if showProsaccadeTarget {
                        Circle()
                            .fill(Color.red)
                            .frame(width: redDotSize, height: redDotSize)
                            .position(targetPosition)
                    }

                    VStack(spacing: 6) {
                       Text("Target: \(attemptCount)/\(maxProsaccadeDots)")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .position(x: geo.size.width/2, y: 50)

                // ─── 3) Test 2: Reflex‐Dot Game ──────────────────────────
                } else if showReflexDotGame {
                    ReflexDotGameView(
                        isShowing: $showReflexDotGame,
                        hitPercentageHandler: { pct in finalHitPercentage = pct }
                    )
                    .onDisappear {
                        slidePhase = 3
                    }

                // ─── 4) Test 3: Optokinetic Test ─────────────────────────
                } else if showOptokineticTest {
                    OptokineticTestView(isShowing: $showOptokineticTest)
                        .onDisappear {
                            slidePhase = 4
                        }

                // ─── 5) Test 4: Chromatic Pupillometry ───────────────────
                } else if showChromaticPupillometry {
                    ChromaticPupillometryView(
                        isShowing: $showChromaticPupillometry,
                        onComplete: {
                            // Transition to Test 5
                            slidePhase = 5
                        }
                    )

                // ─── 6) Test 5: Working Memory Test ──────────────────────
                } else if showWorkingMemoryTest {
                    WorkingMemoryTestView(
                        isShowing: $showWorkingMemoryTest,
                        onComplete: { score in
                            workingMemoryScore = score
                            isGameOver = true
                        }
                    )
                
                // ─── 7) Final End Screen (Results) ───────────────────────
                } else if isGameOver {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Text("All Tests Complete!")
                            .font(.largeTitle)
                            .foregroundColor(.green)

                        Text("Tests Completed Successfully")
                            .font(.title2)
                            .foregroundColor(.white)

                        Text("Dot Hit Accuracy: \(finalHitPercentage, specifier: "%.0f")%")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Working Memory Score: \(workingMemoryScore)/4")
                            .font(.title2)
                            .foregroundColor(.purple)

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
                            isGameOver = false
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
                    
                } else {
                    // Default Transition State
                    Color.black.ignoresSafeArea()
                }
            }
        }
    }

    // ─── Test 1 Logic ──────────────────────────────────────────────
    
    private func startProsaccadeSequence(in size: CGSize) {
        attemptCount = 0
        scheduleNextProsaccadeStep(in: size, delay: prosaccadeInterval)
    }

    private func scheduleNextProsaccadeStep(in size: CGSize, delay: TimeInterval) {
        guard attemptCount < maxProsaccadeDots else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                slidePhase = 2
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            spawnTarget(in: size)
            showProsaccadeTarget = true
            attemptCount += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + prosaccadeDotDuration) {
                showProsaccadeTarget = false
                scheduleNextProsaccadeStep(in: size, delay: prosaccadeInterval)
            }
        }
    }

    private func spawnTarget(in size: CGSize) {
        let pad: CGFloat = 50
        let center = CGPoint(x: size.width/2, y: size.height/2)
        let minDist = redDotSize * 2

        var x: CGFloat, y: CGFloat
        repeat {
            x = .random(in: pad...(size.width - pad))
            y = .random(in: pad...(size.height - pad))
        } while hypot(x - center.x, y - center.y) < minDist

        targetPosition = CGPoint(x: x, y: y)
    }

    private func generateRandomCode() -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return String((0..<14).map { _ in chars.randomElement()! })
    }
}


// ─────────────────────────────────────────────────────────────────────────────
// MARK: – Subview: Working Memory Test (Test 5)
// ─────────────────────────────────────────────────────────────────────────────
struct WorkingMemoryTestView: View {
    @Binding var isShowing: Bool
    var onComplete: (Int) -> Void
    
    // Config
    private let totalSequences = 4
    private let delayDuration = 1.0 // 1000ms delay between memory and test
    
    // State
    @State private var isInstructionPhase = true
    @State private var currentSequenceIndex = 0
    @State private var score = 0
    
    // Flow control within a sequence
    @State private var showCue = false
    @State private var showMemoryArray = false
    @State private var showTestArray = false
    @State private var cueDirection: CueDirection = .right
    
    // Data
    @State private var memoryDots: [MemoryDot] = []
    @State private var testDots: [MemoryDot] = []
    
    enum CueDirection {
        case left, right
        var symbol: String { self == .left ? "arrow.left" : "arrow.right" }
    }
    
    struct MemoryDot: Identifiable {
        let id = UUID()
        var position: CGPoint
        var color: Color
        var isTarget: Bool = false // True if this is the dot that changed
        var originalColor: Color? = nil
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isInstructionPhase {
                    VStack(spacing: 30) {
                        Text("Working Memory Test")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Put on the headset and wait for an arrow to appear. Pay attention to which side of the screen the arrow is pointing to and determine the dot that changed color on the cued side. There may be no color changes. After each sequence the next sequence will play immediately afterwards.")
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Start Test") {
                            isInstructionPhase = false
                            startSequence(in: geo.size)
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .frame(maxWidth: 600)
                    .position(x: geo.size.width/2, y: geo.size.height/2)
                    
                } else {
                    // Game Loop Views
                    
                    // 1. Cue Arrow
                    if showCue {
                        Image(systemName: cueDirection.symbol)
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .position(x: geo.size.width/2, y: geo.size.height/2)
                    }
                    
                    // 2. Memory Array (Initial presentation)
                    if showMemoryArray {
                        ForEach(memoryDots) { dot in
                            Circle()
                                .fill(dot.color)
                                .frame(width: 50, height: 50)
                                .position(dot.position)
                        }
                        // Fixation cross
                        Image(systemName: "plus")
                            .foregroundColor(.gray)
                            .position(x: geo.size.width/2, y: geo.size.height/2)
                    }
                    
                    // 3. Test Array (Input phase)
                    if showTestArray {
                        ForEach(testDots) { dot in
                            Circle()
                                .fill(dot.color)
                                .frame(width: 50, height: 50)
                                .position(dot.position)
                                .onTapGesture {
                                    handleDotTap(dot, in: geo.size)
                                }
                        }
                        // Fixation cross
                        Image(systemName: "plus")
                            .foregroundColor(.gray)
                            .position(x: geo.size.width/2, y: geo.size.height/2)
                        
                        // "No Change" Button
                        VStack {
                            Spacer()
                            Button("No Change") {
                                handleNoChange(in: geo.size)
                            }
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.bottom, 50)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Logic
    
    private func startSequence(in size: CGSize) {
        // Reset sequence state
        showCue = false
        showMemoryArray = false
        showTestArray = false
        
        // Randomize Cue
        cueDirection = Bool.random() ? .left : .right
        
        // Determine number of dots: 2, 4, 6, 8
        let dotCount = (currentSequenceIndex + 1) * 2
        
        // Generate Dots
        generateDots(count: dotCount, in: size)
        
        // TIMING SEQUENCE
        // 200ms: Arrow Cue appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showCue = true
            
            // 500ms: Dots appear (Cue might disappear or stay - typically cue stays or disappears with array. Let's hide cue when dots appear for cleaner look)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 200+300 = 500ms
                showCue = false
                showMemoryArray = true
                
                // 150ms duration for dots (500 + 150 = 650ms)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showMemoryArray = false
                    
                    // Delay phase (1000ms), then Test Array
                    DispatchQueue.main.asyncAfter(deadline: .now() + delayDuration) {
                        prepareTestArray()
                        showTestArray = true
                    }
                }
            }
        }
    }
    
    private func generateDots(count: Int, in size: CGSize) {
        memoryDots = []
        let halfWidth = size.width / 2
        let safePadding: CGFloat = 60
        
        // Generate half on left, half on right
        let perSide = count / 2
        
        // Helper to generate distinct dots for a region
        func createDots(forRightSide: Bool) -> [MemoryDot] {
            var newDots: [MemoryDot] = []
            let xRange = forRightSide ? (halfWidth + safePadding...size.width - safePadding) : (safePadding...halfWidth - safePadding)
            let yRange = safePadding...size.height - safePadding
            
            for _ in 0..<perSide {
                var pos: CGPoint
                var tries = 0
                // Simple non-overlap logic
                repeat {
                    pos = CGPoint(
                        x: CGFloat.random(in: xRange),
                        y: CGFloat.random(in: yRange)
                    )
                    tries += 1
                } while tries < 50 && newDots.contains(where: { hypot($0.position.x - pos.x, $0.position.y - pos.y) < 60 })
                
                newDots.append(MemoryDot(position: pos, color: randomColor()))
            }
            return newDots
        }
        
        // IMPORTANT: Generate Left Side FIRST, then Right Side.
        // This order allows us to calculate sides by index later without checking screen coordinates.
        memoryDots.append(contentsOf: createDots(forRightSide: false))
        memoryDots.append(contentsOf: createDots(forRightSide: true))
    }
    
    private func prepareTestArray() {
        testDots = memoryDots
        
        // Determine if change happens (50% chance)
        let shouldChange = Bool.random()
        
        if shouldChange {
            // Find dots on the cued side
            // Reliance on generation order: First half is Left, Second half is Right.
            let midIndex = testDots.count / 2
            
            let cuedDotsIndices = testDots.indices.filter { i in
                if cueDirection == .left {
                    return i < midIndex
                } else {
                    return i >= midIndex
                }
            }
            
            if let targetIndex = cuedDotsIndices.randomElement() {
                let oldColor = testDots[targetIndex].color
                var newColor = randomColor()
                while newColor == oldColor { newColor = randomColor() }
                
                testDots[targetIndex].color = newColor
                testDots[targetIndex].originalColor = oldColor
                testDots[targetIndex].isTarget = true
            }
        }
    }
    
    private func handleDotTap(_ dot: MemoryDot, in size: CGSize) {
        // Evaluate
        if dot.isTarget {
            // Correct identification of change
            score += 1
        } else {
            // Incorrect
        }
        advanceSequence(in: size)
    }
    
    private func handleNoChange(in size: CGSize) {
        // Evaluate
        let hasTarget = testDots.contains(where: { $0.isTarget })
        if !hasTarget {
            // Correct (there was no change)
            score += 1
        } else {
            // Incorrect (there was a change but user missed it)
        }
        advanceSequence(in: size)
    }
    
    private func advanceSequence(in size: CGSize) {
        showTestArray = false
        currentSequenceIndex += 1
        
        if currentSequenceIndex < totalSequences {
            // Wait briefly then start next
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startSequence(in: size)
            }
        } else {
            // Done
            onComplete(score)
            isShowing = false
        }
    }
    
    private func randomColor() -> Color {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .cyan, .pink]
        return colors.randomElement()!
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
    // Callback to notify parent that we are done
    var onComplete: () -> Void
    
    @State private var isInstructionPhase = true
    @State private var isDarkAdaptationPhase = false
    @State private var isTestingPhase = false
    @State private var backgroundColor = Color.black
    
    @State private var currentRound = 1
    private let totalRounds = 1
    
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
                // Just the black background
            }
        }
    }
    
    private func startDarkAdaptation() {
        isInstructionPhase = false
        isDarkAdaptationPhase = true
        backgroundColor = .black
        
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
    
    private func runRound(roundIndex: Int) {
        if roundIndex > totalRounds {
            // Test Complete
            onComplete()     // Notify parent we are done
            isShowing = false
            return
        }
        
        currentRound = roundIndex
        
        runFlashSequence(count: 1) {
            runRound(roundIndex: roundIndex + 1)
        }
    }
    
    private func runFlashSequence(count: Int, completion: @escaping () -> Void) {
        if count > 3 {
            completion()
            return
        }
        
        withAnimation(.linear(duration: 0.1)) {
            backgroundColor = Color.blue
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.linear(duration: 0.1)) {
                backgroundColor = Color.black
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
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

