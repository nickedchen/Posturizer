import AVFoundation
import SceneKit
import SwiftUI
import Vision

let tabContent = [
    ["Head Pitch",

     "Try move your head up and down",

     "The pitch of the head refers to the up-and-down rotation relative to the horizontal axis of the body. When the top of the head moves downward, it is pitch forward; when it moves upward, it is pitch backward. This movement is akin to nodding."],
    ["Head Yaw",

     "Try move your head left and right",

     "The yaw of the head indicates the left-to-right rotation along the vertical axis. It represents the turning of the face to the left or to the right, much like looking over one's shoulder."],

    ["Head Roll",

     "Try tilt your head side to side",

     "Roll describes the side-to-side tilting of the head along the axis that runs from the back to the front of the head. It is the motion used when trying to touch the shoulder with the ear, commonly referred to as the head tilt."]
]
let tags = [
    ("arrow.up.forward.circle.fill", [Color.black, Color.yellow], "Head Pitch"),
    ("arrow.down.right.circle.fill", [Color.white, Color.red], "Head Yaw"),
    ("arrow.left.and.right.circle.fill", [Color.white, Color.blue], "Head Roll")
]

struct HeadAngleView: View {
    @EnvironmentObject var pageRouter: PageRouter
    @State private var selectedTabIndex = 0

    var body: some View {
        VStack {
            SplitContainerView(leftSideContent: {
                HeadAngleLeftContent(selectedTabIndex: $selectedTabIndex)
            }, rightSideContent: {
                HeadAngleRightContent(selectedTabIndex: $selectedTabIndex)
            })
            BottomNavigationView()
        }
    }
}

struct HeadAngleLeftContent: View {
    @Binding var selectedTabIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            headingText
            VStack(alignment: .leading, spacing: 20) {
                ForEach(tags.indices, id: \.self) { index in
                    let tag = tags[index]
                    angleTag(index: index, systemImageName: tag.0, foregroundStyleColors: tag.1, text: tag.2)
                }
            }
            .fontWeight(.semibold)
        }
        .frame(alignment: .center)
        .padding()
    }

    private var headingText: some View {
        Group {
            Text("Head Posture")
                +
                Text(" is determined by these egocentric rotation angles describing orientation of the head in degrees (DEG).")
                .foregroundStyle(Color.secondary)
            Text("Turn on camera to visualize the angles in real-time.")

            Text("Tap on each angles to learn more about them.")
                .foregroundStyle(Color.primary)
        }
        .fontWeight(.semibold)
        .font(.title)
    }

    func angleTag(index: Int, systemImageName: String, foregroundStyleColors: [Color], text: String) -> some View {
        HStack {
            Image(systemName: systemImageName)
                .font(.system(size: 40))
                .symbolRenderingMode(.palette)
                .foregroundStyle(foregroundStyleColors[0], foregroundStyleColors[1])
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.selectedTabIndex = index
                }
            }) {
                Text(text)
                    .font(.title)
                    .foregroundStyle(selectedTabIndex == index ? Color.primary : Color.secondary)
            }
        }
    }
}

struct HeadAngleRightContent: View {
    @Binding var selectedTabIndex: Int
    @StateObject var bodyPoseViewModel = BodyPoseViewModel()
    @State private var isCameraReady: Bool = false
    @State private var isAngleView: Bool = false
    @State private var currentAngleDegrees: Double = 0

    var body: some View {
        VStack {
            if isCameraReady {
                CameraAngleView
            } else {
                ProgressView()
                    .frame(minHeight: 200)
                    .padding()
            }
            tabView
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isCameraReady = true
                }
            }
            bodyPoseViewModel.startSession()
        }

        .padding()
    }

    private var CameraAngleView: some View {
        ZStack {
            if isAngleView {
                // Assuming AngleView exists and takes these parameters
                AngleView(angle: angleForSelectedTab(selectedTabIndex: selectedTabIndex), rotate90Degrees: selectedTabIndex != 0)
                    .frame(width: 300, height: 300, alignment: .center)
            } else {
                GeometryReader { geometry in
                    CameraView(viewModel: bodyPoseViewModel) // Assuming CameraView takes a viewModel parameter
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            overlayView(geometry: geometry)
                        )
                }
            }

            VStack {
                Button(action: {
                    isAngleView.toggle()
                }) {
                    Label("Angle View", systemImage: "angle")
                        .font(.headline)
                        .foregroundColor(.black)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                Spacer()
            }
            .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func overlayView(geometry: GeometryProxy) -> some View {
        Group {
            if bodyPoseViewModel.headPitch.degrees == 0 && bodyPoseViewModel.headYaw.degrees == 0 && bodyPoseViewModel.headRoll.degrees == 0 {
                ZStack {
                    Rectangle()
                        .fill(.regularMaterial)
                        .edgesIgnoringSafeArea(.all)
                    Text("Move away from the camera a bit.\nPlace your hand on the keyboard or hold the device straight 👨‍💻")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                }
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }

    private var tabView: some View {
        TabView(selection: $selectedTabIndex) {
            ForEach(0 ..< tabContent.count, id: \.self) { index in
                VStack(spacing: 20) {
                    let angleDegrees = Int(angleForSelectedTab(selectedTabIndex: index).degrees)
                    Text("\(angleDegrees)°")
                        .font(.body)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(angleIsInRange(angleDegrees: angleDegrees) ? .green : .accentColor))
                        .foregroundColor(angleIsInRange(angleDegrees: angleDegrees) ? Color.white : Color.black)
                        .multilineTextAlignment(.center).fontWeight(.semibold)

                    Text(tabContent[index][0])
                        .fontWeight(.semibold)

                    Text(tabContent[index][1])
                        .font(.title3)
                        .fontWeight(.medium)

                    Text(tabContent[index][2])
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .tabViewStyle(PageTabViewStyle())
    }

    private func angleForSelectedTab(selectedTabIndex: Int) -> Angle {
        switch selectedTabIndex {
        case 0: return -bodyPoseViewModel.headPitch
        case 1: return -bodyPoseViewModel.headYaw
        case 2: return bodyPoseViewModel.headRoll
        default: return .degrees(0)
        }
    }

    private func angleIsInRange(angleDegrees: Int) -> Bool {
        return angleDegrees >= -10 && angleDegrees <= 10
    }
}

#Preview {
    HeadAngleView()
        .environmentObject(PageRouter())
}
