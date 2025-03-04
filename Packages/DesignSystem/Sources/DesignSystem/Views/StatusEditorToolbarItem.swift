import SwiftUI
import Env

@MainActor
extension View {
  public func statusEditorToolbarItem(routeurPath: RouterPath) -> some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        routeurPath.presentedSheet = .newStatusEditor
      } label: {
        Image(systemName: "square.and.pencil")
      }
    }
  }
}
