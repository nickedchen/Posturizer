import SwiftUI

class PageRouter: ObservableObject {
    @Published var currentView: AppContainerView.CurrentView = .introView

    func goToNextPage() {
        guard let currentIndex = AppContainerView.CurrentView.allCases.firstIndex(of: currentView) else { return }
        let nextIndex = (currentIndex + 1) % AppContainerView.CurrentView.allCases.count
        currentView = AppContainerView.CurrentView.allCases[nextIndex]
    }

    func goToPreviousPage() {
        guard let currentIndex = AppContainerView.CurrentView.allCases.firstIndex(of: currentView) else { return }
        let previousIndex = (currentIndex - 1 + AppContainerView.CurrentView.allCases.count) % AppContainerView.CurrentView.allCases.count
        currentView = AppContainerView.CurrentView.allCases[previousIndex]
    }
}

struct AppContainerView: View {
    enum CurrentView: CaseIterable, Equatable {
        case introView, benefitsView, definitionView, instructionView, gameView, summaryView
    }

    @EnvironmentObject var viewRouter: PageRouter

    var body: some View {
        ZStack(alignment: .center) {
            switch viewRouter.currentView {
            case .introView:
                IntroView()
                    .transition(.move(edge: .leading).combined(with: .opacity))
            case .benefitsView:
                BenefitsView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .definitionView:
                HeadAngleView()
                    .transition(.opacity)
            case .instructionView:
                InstructionView()
                    .transition(.opacity)
            case .gameView:
                GameView()
            case .summaryView:
                SummaryView(score: 0)
            }
        }
        .animation(.easeInOut, value: viewRouter.currentView)
    }
}
