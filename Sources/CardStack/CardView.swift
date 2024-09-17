import SwiftUI

struct CardView<Direction, Content: View>: View {
  @Environment(\.cardStackConfiguration) private var configuration: CardStackConfiguration
  @State private var translation: CGSize = .zero

  private let direction: (Double) -> Direction?
  private let isOnTop: Bool
  private let onSwipeEnded: (Direction?) -> Void
  private let onSwipeChanged: (Direction) -> Void
  private let content: (Direction?) -> Content
  @State private var clockwiseRotation: Bool = true

  init(
    direction: @escaping (Double) -> Direction?,
    isOnTop: Bool,
    onSwipeEnded: @escaping (Direction?) -> Void,
    onSwipeChanged: @escaping (Direction) -> Void,
    @ViewBuilder content: @escaping (Direction?) -> Content
  ) {
    self.direction = direction
    self.isOnTop = isOnTop
    self.onSwipeEnded = onSwipeEnded
    self.onSwipeChanged = onSwipeChanged
    self.content = content
  }

  var body: some View {
    GeometryReader { geometry in
      self.content(self.swipeDirection(geometry))
        .offset(self.translation)
        .rotationEffect(self.rotation(geometry))
        .simultaneousGesture(self.isOnTop ? self.dragGesture(geometry) : nil)
    }
    .transition(transition)
  }

  private func dragGesture(_ geometry: GeometryProxy) -> some Gesture {
    DragGesture()
      .onChanged { value in
        if value.location.y < geometry.size.height / 2 {
            clockwiseRotation = false
        }
        self.translation = value.translation
          if let direction = self.swipeDirection(geometry, useThreshold: false) {
            print("TRANSLATION: \(translation)")
            self.onSwipeChanged(direction)
          }
      }
      .onEnded { value in
        self.translation = value.translation
        let direction = self.swipeDirection(geometry)
          
        withAnimation(self.configuration.animation) { self.onSwipeEnded(direction) }
          
        if direction == nil {
          withAnimation { self.translation = .zero }
        }
      }
  }

  private var degree: Double {
    var degree = atan2(translation.width, -translation.height) * 180 / .pi
    if degree < 0 { degree += 360 }
    return Double(degree)
  }

  private func rotation(_ geometry: GeometryProxy) -> Angle {
    if clockwiseRotation {
      return .degrees(Double(translation.width / geometry.size.width) * -10)
    } else {
      return .degrees(Double(translation.width / geometry.size.width) * 10)
    }
  }

  private func swipeDirection(_ geometry: GeometryProxy, useThreshold: Bool = true) -> Direction? {
    guard let direction = direction(degree) else { return nil }
    let threshold = min(geometry.size.width, geometry.size.height) * configuration.swipeThreshold
    let distance = hypot(translation.width, translation.height)
    
    if useThreshold {
      return distance > threshold ? direction : nil
    } else {
      return direction
    }
  }

  private var transition: AnyTransition {
    .asymmetric(
      insertion: .identity,  // No animation needed for insertion
      removal: .offset(x: translation.width * 2, y: translation.height * 2)  // Go out of screen when card removed
    )
  }
}
