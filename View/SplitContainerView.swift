import SwiftUI

struct SplitContainerView<LeftContent: View, RightContent: View>: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    var leftSideContent: () -> LeftContent
    var rightSideContent: () -> RightContent

    init(@ViewBuilder leftSideContent: @escaping () -> LeftContent, @ViewBuilder rightSideContent: @escaping () -> RightContent) {
        self.leftSideContent = leftSideContent
        self.rightSideContent = rightSideContent
    }

    var body: some View {
        Group {
            if sizeClass == .compact {
                VStack(spacing: 0) {
                    leftSideContent()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    rightSideContent()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .font(.largeTitle)
                }
            } else {
                HStack(alignment: .center, spacing: 0) {
                    leftSideContent()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    rightSideContent()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .font(.system(size: 48))
                }
            }
        }
    }
}
