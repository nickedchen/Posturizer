import SwiftUI

struct InstructionView: View {
    let instructions = [
        "In the next exercise, you move your head in different directions to dodge any obstacles that will be coming towards you.",
        "Take off any over-ear headphones, caps and make sure your hair is not covering your face :)",
        "Make sure to sit upright in a well lit room, look ahead, and try not to push the head too hard.",
        "Have fun!"
    ]
    
    @EnvironmentObject var pageRouter: PageRouter
    @State private var currentInstruction = ""
    @State private var instructionIndex = 0
    @State private var showButton = false
    
    var body: some View {
        VStack {
            Spacer()
            Text(currentInstruction)
                .font(.title)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .padding()
                .transition(.opacity)
                .onAppear {
                    displayNextInstruction()
                }
            
            if showButton {
                Button("Let's Start") {
                    let gameViewController = GameViewController()
                    gameViewController.pageRouter = self.pageRouter
                    pageRouter.goToNextPage()
                }
                .font(.title2)
                .padding()
                .buttonBorderShape(.capsule)
                .buttonStyle(.bordered)
                .foregroundColor(Color.primary)
                .scaleEffect(showButton ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 1), value: showButton)
            }
            
            Spacer()
        }
    }
    
    func displayNextInstruction() {
        guard instructionIndex < instructions.count else {
            withAnimation {
                showButton = true
            }
            return
        }
            
        let instruction = instructions[instructionIndex]
        var tempDisplay = ""
            
        for (index, character) in instruction.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                tempDisplay.append(character)
                currentInstruction = tempDisplay
            }
        }
            
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(instruction.count) * 0.05 + 2.0) {
            if instructionIndex < instructions.count - 1 {
                instructionIndex += 1
                currentInstruction = ""
                displayNextInstruction()
            } else {
                instructionIndex += 1
                withAnimation(.easeInOut(duration: 0.5)) {
                    showButton = true
                }
            }
        }
    }
}

struct InstructionView_Previews: PreviewProvider {
    static var previews: some View {
        InstructionView()
    }
}
