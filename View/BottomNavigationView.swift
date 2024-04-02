import SwiftUI

struct BottomNavigationView: View {
    @EnvironmentObject var pageRouter: PageRouter

    var body: some View {
        HStack {
            Button(action: {
                pageRouter.goToPreviousPage()
            }, label: {
                Image(systemName: "arrow.left")
            })
            Spacer()
            Button(action: {
                pageRouter.goToNextPage()
            }, label: {
                Image(systemName: "arrow.right")
            })
        }
        .fontWeight(.semibold)
        .font(.title)
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
    }
}
