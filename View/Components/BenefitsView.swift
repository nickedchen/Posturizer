import SwiftUI

let benefits: [String] = [
    "Reduces Muscle Strain",
    "Maintains Spinal Health",
    "Prevents Neck Pain",
    "Improves Breathing",
    "Enhances Concentration and Mental Performance",
    "Reduces neck and shoulder tension",
    "..."
]

let factors: [String] = [
    "Prolonged Use of Electronic Devices",
    "Poor Ergonomics at Work",
    "Weak Postural Muscles",
    "Lifestyle",
    "Lack of Physical Excersise",
    "..."
]

struct BenefitsView: View {
    @EnvironmentObject var pageRouter: PageRouter
    @State private var currentPageIndex = 0
    @State private var selectedTabIndex = 0

    var body: some View {
        VStack {
            SplitContainerView(leftSideContent: {
                BenefitsLeftContent(selectedTabIndex: $selectedTabIndex)
            }, rightSideContent: {
                BenefitsRightContent(selectedTabIndex: $selectedTabIndex)
            })
            BottomNavigationView()
        }
    }
}

struct BenefitsLeftContent: View {
    @Binding var selectedTabIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer()
            Text("Head Posture")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .tracking(-0.8)
            Spacer()
            VStack(alignment: .leading, spacing: 20) {
                Text("Head posture refers to the position of the head in relation to the spine.")
                Text("Maintaining a proper head posture is essential to prevent neck pain and other complications, especially for desktop users.")
                Text("This involves ensuring the head is positioned over the shoulders, avoiding forward lean or tilt, which can strain muscles and ligaments in the neck and back.")
            }
            .font(.title2)
            .fontWeight(.regular)

            HStack(spacing: 20) {
                ItemTag(systemImageName: "star.circle.fill",
                        foregroundStyleColors: [.white, .blue],
                        text: "Benefits",
                        index: 0,
                        selectedTabIndex: $selectedTabIndex)
                ItemTag(systemImageName: "flag.circle.fill",
                        foregroundStyleColors: [.white, .orange],
                        text: "Factors",
                        index: 1,
                        selectedTabIndex: $selectedTabIndex)
            }
            .fontWeight(.medium)
        }
        .padding(40)
    }
}

struct ItemTag: View {
    var systemImageName: String
    var foregroundStyleColors: [Color]
    var text: String
    var index: Int
    @Binding var selectedTabIndex: Int
    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: {
            withAnimation(.interpolatingSpring(duration: 0.4)) {
                self.selectedTabIndex = index
            }
        }) {
            HStack {
                Image(systemName: systemImageName)
                    .font(.system(size: 32))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(foregroundStyleColors[0], foregroundStyleColors[1])
                Text(text)
                    .font(.title3)
                    .lineLimit(1)
                    .foregroundColor(selectedTabIndex == index ? .primary : .secondary)
            }

            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(foregroundStyleColors[1].quinary.opacity(selectedTabIndex == index ? 1 : 0))
            )
        }
        .scaleEffect(isPressed ? 0.85 : 1.0)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct BenefitsRightContent: View {
    @Binding var selectedTabIndex: Int
    private var maxCount: Int {
        max(benefits.count, factors.count)
    }

    @State private var appear: [Bool]

    init(selectedTabIndex: Binding<Int>) {
        self._selectedTabIndex = selectedTabIndex
        self._appear = State(initialValue: [Bool](repeating: false, count: max(benefits.count, factors.count)))
    }

    var body: some View {
        VStack(spacing: 20) {
            TabView(selection: $selectedTabIndex) {
                buildTabView(benefits)
                    .tag(0)
                buildTabView(factors)
                    .tag(1)
            }
            .onChange(of: selectedTabIndex) { _, _ in
                resetAnimations()
            }
        }
        .padding(40)
    }

    private func buildTabView(_ items: [String]) -> some View {
        VStack(spacing: 20) {
            Spacer()
            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                Text(item)
                    .foregroundColor(.primary)
                    .fontWeight(.regular)
                    .font(.title3)
                    .offset(y: appear[index] ? 0 : 20)
                    .opacity(appear[index] ? 1 : 0)
                    .multilineTextAlignment(.leading)
                    .onAppear {
                        withAnimation(Animation.spring().delay(Double(index) * 0.2)) {
                            appear[index] = true
                        }
                    }
            }
        }
    }

    private func resetAnimations() {
        appear = [Bool](repeating: false, count: maxCount)
        for index in appear.indices {
            withAnimation(.interpolatingSpring.delay(Double(index) * 0.1)) {
                appear[index] = true
            }
        }
    }
}

#Preview {
    BenefitsView()
        .environmentObject(PageRouter())
}
