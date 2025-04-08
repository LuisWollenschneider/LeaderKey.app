import SwiftUI

func actionIcon(action: Action, iconSize: NSSize) -> some View {
  var icon: String {
    switch action.type {
    case .application: return "macwindow"
    case .url: return "link"
    case .command: return "terminal"
    case .folder: return "folder"
    default: return "questionmark"
    }
  }
  if action.iconPath != nil && !action.iconPath!.isEmpty {
    if action.iconPath!.hasSuffix(".app") {
      return AnyView(AppIconImage(appPath: action.iconPath!, size: iconSize))
    } else {
      return AnyView(
        Image(systemName: action.iconPath!)
          .foregroundStyle(.secondary)
          .frame(width: iconSize.width, height: iconSize.height, alignment: .center)
      )
    }
  } else if action.type == .application {
    return AnyView(AppIconImage(appPath: action.value, size: iconSize))
  }
  return AnyView(
    Image(systemName: icon)
      .foregroundStyle(.secondary)
      .frame(width: iconSize.width, height: iconSize.height, alignment: .center)
  )
}
