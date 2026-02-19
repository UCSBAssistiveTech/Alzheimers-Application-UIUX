import SwiftUI

// MARK: – Main View orchestrating the Biomarker Suite
struct ReactionGameView: View {
    @State private var activeTest: TestType = .start
    @State private var finalResults: [String: String] = [:]

    enum TestType {
        case start
        case instrProsaccade, prosaccade
        case instrAntisaccade, antisaccade
        case instrGapEffect, gapEffect
        case instrNovelty, noveltyFixation
        case results
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                switch activeTest {
                case .start:
                    StartScreen(onStart: { activeTest = .instrProsaccade })

                // --- 1) PROSACCADE SEQUENCE ---
                case .instrProsaccade:
                    InstructionView(
                        title: "Prosaccade Test",
                        instructions: "A central, white fixation point will be present. Direct your gaze quickly and accurately to the red target as soon as it appears. Hold your gaze on the target until it disappears, then revert back to the white fixation point. Keep your head positioned still.",
                        buttonText: "Begin Prosaccade",
                        onContinue: { activeTest = .prosaccade }
                    )
                case .prosaccade:
                    ProsaccadeTestView(geo: geo) { res in
                        finalResults["Prosaccade"] = res
                        activeTest = .instrAntisaccade
                    }

                // --- 2) ANTISACCADE SEQUENCE ---
                case .instrAntisaccade:
                    InstructionView(
                        title: "Antisaccade Test",
                        instructions: "Look at the central dot; as soon as a new dot appears look in the opposite direction, to here, as fast as you can. You will probably sometimes make mistakes, and this is perfectly normal.",
                        buttonText: "Begin Antisaccade",
                        onContinue: { activeTest = .antisaccade }
                    )
                case .antisaccade:
                    AntisaccadeTestView(geo: geo) { res in
                        finalResults["Antisaccade"] = res
                        activeTest = .instrGapEffect
                    }

                // --- 3) GAP EFFECT SEQUENCE ---
                case .instrGapEffect:
                    InstructionView(
                        title: "Gap Effect Test",
                        instructions: "During this test, try to quickly shift your gaze between objects on the screen to the best of your ability. A fixation cross will appear, then disappear for a brief gap before the cyan target appears.",
                        buttonText: "Begin Gap Test",
                        onContinue: { activeTest = .gapEffect }
                    )
                case .gapEffect:
                    GapEffectTestView(geo: geo) { res in
                        finalResults["GapEffect"] = res
                        activeTest = .instrNovelty
                    }

                // --- 4) NOVELTY FIXATION SEQUENCE ---
                case .instrNovelty:
                    InstructionView(
                        title: "Novelty Fixation",
                        instructions: "Various visual stimuli will be presented. Please react naturally to what you see. You should focus your attention on the novel images—those you have not seen before in the sequence.",
                        buttonText: "Begin Novelty Test",
                        onContinue: { activeTest = .noveltyFixation }
                    )
                case .noveltyFixation:
                    NoveltyFixationView(geo: geo) { res in
                        finalResults["Novelty"] = res
                        activeTest = .results
                    }

                case .results:
                    ResultsView(results: finalResults) {
                        activeTest = .start
                    }
                }
            }
        }
    }
}

// MARK: – Reusable Instruction Component
struct InstructionView: View {
    let title: String
    let instructions: String
    let buttonText: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Text(title).font(.system(size: 48, weight: .bold)).foregroundColor(.white)
            ScrollView {
                Text(instructions).font(.title3).lineSpacing(8).foregroundColor(.white).multilineTextAlignment(.center).padding()
            }.frame(maxHeight: 400)
            Button(action: onContinue) {
                Text(buttonText).font(.title2).bold().padding().frame(width: 300).background(Color.blue).foregroundColor(.white).cornerRadius(15)
            }
        }.padding(40).background(Color.white.opacity(0.05)).cornerRadius(20).padding()
    }
}

// MARK: – 1) Prosaccade Test (5 Targets)
struct ProsaccadeTestView: View {
    let geo: GeometryProxy
    var onComplete: (String) -> Void
    @State private var attempt = 0
    @State private var targetPos = CGPoint.zero
    @State private var showTarget = false
    private let totalTargets = 5
    
    var body: some View {
        ZStack {
            Circle().fill(.white).frame(width: 20, height: 20).position(x: geo.size.width/2, y: geo.size.height/2)
            if showTarget { Circle().fill(.red).frame(width: 20, height: 20).position(targetPos) }
            Text("Target \(attempt)/\(totalTargets)").foregroundColor(.gray).position(x: geo.size.width/2, y: 100)
        }.onAppear { runSequence() }
    }
    
    func runSequence() {
        guard attempt < totalTargets else { onComplete("Complete"); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            targetPos = randomSaccadePosition(in: geo.size)
            showTarget = true
            attempt += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showTarget = false
                runSequence()
            }
        }
    }
}

// MARK: – 2) Antisaccade Test (5 Trials)
struct AntisaccadeTestView: View {
    let geo: GeometryProxy
    var onComplete: (String) -> Void
    @State private var attempt = 0
    @State private var showFixation = true
    @State private var showTarget = false
    @State private var targetPos = CGPoint.zero
    private let totalTrials = 5

    var body: some View {
        ZStack {
            if showFixation { Image(systemName: "plus").foregroundColor(.white).font(.title).position(x: geo.size.width/2, y: geo.size.height/2) }
            if showTarget { Circle().fill(.cyan).frame(width: 30, height: 30).position(targetPos) }
            Text("Trial \(attempt)/\(totalTrials)").foregroundColor(.gray).position(x: geo.size.width/2, y: 100)
        }.onAppear { runSequence() }
    }
    
    func runSequence() {
        guard attempt < totalTrials else { onComplete("Complete"); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showFixation = false
            targetPos = randomSaccadePosition(in: geo.size)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                showTarget = true
                attempt += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showTarget = false
                    showFixation = true
                    runSequence()
                }
            }
        }
    }
}

// MARK: – 3) Gap Effect Test (Cyan on Gray scale) [cite: 257, 264-270]
struct GapEffectTestView: View {
    let geo: GeometryProxy
    var onComplete: (String) -> Void
    
    @State private var attempt = 0
    @State private var showFixation = false
    @State private var showTarget = false
    @State private var targetPos = CGPoint.zero
    
    private let totalTrials = 5
    private let gapDuration = 0.3 // 300ms gap [cite: 265]
    private let fixationDuration = 1.0 // 1000ms fixation [cite: 264]

    var body: some View {
        ZStack {
            Color(white: 0.85).ignoresSafeArea() // Light Gray background [cite: 266]

            if showFixation {
                Image(systemName: "plus").font(.system(size: 40, weight: .light)).foregroundColor(.black)
                    .position(x: geo.size.width/2, y: geo.size.height/2) // Central fixation cross [cite: 236]
            }
            
            if showTarget {
                Circle().fill(Color(red: 0, green: 0.8, blue: 0.8)).frame(width: 30, height: 30)
                    .position(targetPos) // Cyan target [cite: 266]
            }
            
            Text("Trial \(attempt)/\(totalTrials)").foregroundColor(.black.opacity(0.6)).position(x: geo.size.width/2, y: 100)
        }
        .onAppear { runSequence() }
    }
    
    private func runSequence() {
        guard attempt < totalTrials else { onComplete("Complete"); return }
        showFixation = true
        showTarget = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + fixationDuration) {
            showFixation = false
            // Radial distance = 1/4 of (width + height)/2
            let radialDistance = (geo.size.width + geo.size.height) / 8
            targetPos = calculateRadialPosition(distance: radialDistance, center: CGPoint(x: geo.size.width/2, y: geo.size.height/2))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + gapDuration) {
                showTarget = true
                attempt += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { runSequence() }
            }
        }
    }
    
    private func calculateRadialPosition(distance: CGFloat, center: CGPoint) -> CGPoint {
        let angle = CGFloat.random(in: 0...(2 * .pi))
        return CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance)
    }
}

// MARK: – 4) Novelty Fixation Test (Start -> 1-back -> 2-back) [cite: 358-375]
struct NoveltyFixationView: View {
    let geo: GeometryProxy
    var onComplete: (String) -> Void
    @State private var phase: NoveltyPhase = .start
    @State private var isShowingContent = false
    
    enum NoveltyPhase { case start, oneBack, twoBack }
    
    private var dynamicSquareSize: CGFloat {
        let minDim = min(geo.size.width, geo.size.height)
        return (minDim * 0.7) / 2 - 20
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(phaseTitle).font(.largeTitle).foregroundColor(.white).opacity(isShowingContent ? 1 : 0)
            if isShowingContent {
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        ImagePlaceholder(label: topLeftLabel, size: dynamicSquareSize)
                        ImagePlaceholder(label: topRightLabel, size: dynamicSquareSize)
                    }
                    HStack(spacing: 20) {
                        ImagePlaceholder(label: bottomLeftLabel, size: dynamicSquareSize)
                        ImagePlaceholder(label: bottomRightLabel, size: dynamicSquareSize)
                    }
                }
            } else {
                Color.gray.opacity(0.3).frame(width: dynamicSquareSize * 2 + 20, height: dynamicSquareSize * 2 + 20).cornerRadius(15)
            }
        }.onAppear { runFullSequence() }
    }
    
    private func runFullSequence() {
        displaySlide(for: .start) { displaySlide(for: .oneBack) { displaySlide(for: .twoBack) { onComplete("Measured") } } }
    }
    
    private func displaySlide(for newPhase: NoveltyPhase, completion: @escaping () -> Void) {
        isShowingContent = false
        phase = newPhase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 1s grey screen [cite: 379]
            isShowingContent = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.5) { completion() } // 10.5s duration [cite: 379]
        }
    }

    private var phaseTitle: String {
        switch phase { case .start: return "Start"; case .oneBack: return "1-back"; case .twoBack: return "2-back" }
    }
    private var topLeftLabel: String {
        switch phase { case .start: return "1"; case .oneBack: return "1"; case .twoBack: return "N" }
    }
    private var topRightLabel: String {
        switch phase { case .start: return "2"; case .oneBack: return "2"; case .twoBack: return "N" }
    }
    private var bottomLeftLabel: String {
        switch phase { case .start: return "3"; case .oneBack: return "N"; case .twoBack: return "3" }
    }
    private var bottomRightLabel: String {
        switch phase { case .start: return "4"; case .oneBack: return "N"; case .twoBack: return "4" }
    }
}

struct ImagePlaceholder: View {
    let label: String
    let size: CGFloat
    var body: some View {
        RoundedRectangle(cornerRadius: 10).fill(label == "N" ? Color.blue.opacity(0.8) : Color.white.opacity(0.9))
            .frame(width: size, height: size).overlay(Text(label).font(.system(size: size * 0.2, weight: .bold)).foregroundColor(label == "N" ? .white : .black))
    }
}

// MARK: – Helper Utilities
func randomSaccadePosition(in size: CGSize) -> CGPoint {
    let side = Bool.random() ? -1.0 : 1.0
    return CGPoint(x: size.width/2 + (side * CGFloat.random(in: 250...450)), y: size.height/2 + CGFloat.random(in: -50...50))
}

struct StartScreen: View {
    var onStart: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Text("Biomarker Research Suite").font(.largeTitle).foregroundColor(.white)
            Button("Start Test") { onStart() }.padding().background(Color.blue).foregroundColor(.white).cornerRadius(10)
        }
    }
}

struct ResultsView: View {
    let results: [String: String]
    var onRestart: () -> Void
    var body: some View {
        VStack(spacing: 15) {
            Text("Assessment Complete").font(.title).foregroundColor(.green)
            ForEach(results.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in Text("\(key): \(value)").foregroundColor(.white) }
            Button("Restart") { onRestart() }.padding().background(Color.gray).cornerRadius(8).padding(.top)
        }
    }
}

// MARK: – Preview for Apple Vision Pro
struct ReactionGameView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionGameView()
            .previewDevice("Apple Vision Pro")
    }
}
