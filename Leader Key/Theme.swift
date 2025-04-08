import Defaults

enum Theme: String, Defaults.Serializable {
  case mysteryBox
  case mini
  case breadcrumbs
  case forTheHorde

  static var all: [Theme] {
    return [.mysteryBox, .mini, .breadcrumbs, .forTheHorde]
  }

  static func classFor(_ value: Theme) -> MainWindow.Type {
    switch value {
    case .mysteryBox:
      return MysteryBox.Window.self
    case .mini:
      return Mini.Window.self
    case .breadcrumbs:
      return Breadcrumbs.Window.self
    case .forTheHorde:
      return ForTheHorde.Window.self
    }
  }

  static func name(_ value: Theme) -> String {
    switch value {
    case .mysteryBox: return "Mystery Box"
    case .mini: return "Mini"
    case .breadcrumbs: return "Breadcrumbs"
    case .forTheHorde: return "For The Horde"
    }
  }
}
