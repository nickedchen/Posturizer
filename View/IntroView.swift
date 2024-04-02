import SwiftUI

struct IntroView: View {
    @EnvironmentObject var pageRouter: PageRouter
    @State private var bounce = 0
    @State private var displayedText = ""
    @State private var showText = false
    @State private var showButton = false
    @State private var wordIndex = 0
    @State private var timer: Timer?
    @State private var isButtonPressed = false
    @State private var arrowScaleX: CGFloat = 1.0
    
    private let label = "# Swift Student Challenge 24'"
    private let secondaryLabel = "Rotate Device to Landscape Mode to Start"
    private let fullText = "Posturizer is an app designed to help you in maintaining a proper head posture in a playful way."
    
    private var words: [String] {
        fullText.components(separatedBy: " ")
    }
   
    var body: some View {
        SplitContainerView(leftSideContent: {
            leftSideContent
        }, rightSideContent: {
            rightSideContent
        })
        .onAppear {
            triggerTextAnimation()
        }
    }
    
    private var leftSideContent: some View {
        VStack {
            HStack {
                Text(label)
                Spacer()
                Image(systemName: "arrow.up.right")
            }
            .fontWeight(.medium)
            
            .frame(maxWidth: .infinity, alignment: .top)
            .foregroundColor(.black)
            Spacer()
            Image(systemName: "person.fill.and.arrow.left.and.arrow.right")
                .font(.system(size: 300))
                .fontWeight(.semibold)
                .symbolEffect(.bounce, value: bounce)
                .onAppear { bounce += 1 }
                .onTapGesture { bounce += 1 }
            Spacer()
            HStack {
                Text(secondaryLabel)
                Spacer()
            }
            .fontWeight(.medium)
            .frame(maxWidth: .infinity, alignment: .top)
            .foregroundColor(.black)
        }
        .padding(40)
        .font(.title3)
        .foregroundColor(.black)
        .background(Color.accentColor)
    }
    
    private var rightSideContent: some View {
        VStack(alignment: .leading, spacing: 40) {
            if showText {
                Text(displayedText)
                    .tracking(-0.2)
            }
            Spacer()
            Button(action: {
                withAnimation(.interpolatingSpring) {
                    pageRouter.currentView = .benefitsView
                }
            }, label: {
                HStack {
                    Text("Get Started")
                    Spacer()
                    Image(systemName: "arrow.right")
                        .scaleEffect(x: arrowScaleX, y: 1.0, anchor: .center)
                }
                .tracking(-0.2)
            })
            .controlSize(.large)
            .opacity(showButton ? 1 : 0)
            .scaleEffect(isButtonPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isButtonPressed)
            .foregroundStyle(Color.primary)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                withAnimation {
                    isButtonPressed = pressing
                }
            }, perform: {})
       
            .opacity(showButton ? 1 : 0)
        }
        
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(40)
    }
    
    private func triggerTextAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
                if wordIndex < words.count {
                    displayedText += (wordIndex > 0 ? " " : "") + words[wordIndex]
                    wordIndex += 1
                    if !showText {
                        withAnimation(.easeInOut) {
                            showText = true
                        }
                    }
                } else {
                    timer.invalidate()
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showButton = true
                    }
                }
            }
        }
    }
}
