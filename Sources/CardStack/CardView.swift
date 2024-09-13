import SwiftUI

struct CardView<Direction, Content: View>: View {
  @Environment(\.cardStackConfiguration) private var configuration: CardStackConfiguration
  @State private var translation: CGSize = .zero

  private let direction: (Double) -> Direction?
  private let isOnTop: Bool
  private let onSwipeEnded: (Direction) -> Void
  private let onSwipeChanged: (Direction, CGSize) -> Void
  private let content: (Direction?) -> Content

  init(
    direction: @escaping (Double) -> Direction?,
    isOnTop: Bool,
    onSwipeEnded: @escaping (Direction) -> Void,
    onSwipeChanged: @escaping (Direction, CGSize) -> Void,
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
        self.translation = value.translation
          if let direction = self.swipeDirection(geometry, useThreshold: false) {
            self.onSwipeChanged(direction, translation)
          }
      }
      .onEnded { value in
        self.translation = value.translation
        if let direction = self.swipeDirection(geometry) {
          withAnimation(self.configuration.animation) { self.onSwipeEnded(direction) }
        } else {
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
    .degrees(
      Double(translation.width / geometry.size.width) * 25
    )
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
