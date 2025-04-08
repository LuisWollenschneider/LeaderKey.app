import SwiftUI

let generalPadding: CGFloat = 8

struct AddButtons: View {
  let onAddAction: () -> Void
  let onAddGroup: () -> Void

  var body: some View {
    HStack(spacing: generalPadding) {
      Button(action: onAddAction) {
        Image(systemName: "rays")
        Text("Add action")
      }
      Button(action: onAddGroup) {
        Image(systemName: "folder")
        Text("Add group")
      }
      Spacer()
    }
  }
}

struct GroupContentView: View {
  @Binding var group: Group
  @EnvironmentObject var userConfig: UserConfig
  var isRoot: Bool = false
  var parentPath: [Int] = []
  @Binding var expandedGroups: Set<[Int]>

  var body: some View {
    VStack(spacing: generalPadding) {
      ForEach(group.actions.indices, id: \.self) { index in
        let currentPath = parentPath + [index]
        ActionOrGroupRow(
          item: binding(for: index),
          path: currentPath,
          onDelete: { group.actions.remove(at: index) },
          onDuplicate: { group.actions.insert(group.actions[index], at: index) },
          expandedGroups: $expandedGroups
        )
        .id(index)
      }

      AddButtons(
        onAddAction: {
          withAnimation {
            group.actions.append(
              .action(Action(key: "", type: .application, value: "")))
          }
        },
        onAddGroup: {
          withAnimation {
            group.actions.append(.group(Group(key: "", actions: [])))
          }
        }
      )
      .padding(.top, generalPadding * 0.5)
    }
  }

  private func binding(for index: Int) -> Binding<ActionOrGroup> {
    Binding(
      get: { group.actions[index] },
      set: { group.actions[index] = $0 }
    )
  }
}

struct ConfigEditorView: View {
  @Binding var group: Group
  @EnvironmentObject var userConfig: UserConfig
  var isRoot: Bool = true
  @Binding var expandedGroups: Set<[Int]>

  var body: some View {
    ScrollView {
      GroupContentView(
        group: $group, isRoot: isRoot, parentPath: [], expandedGroups: $expandedGroups
      )
      .padding(
        EdgeInsets(
          top: generalPadding, leading: generalPadding,
          bottom: generalPadding, trailing: 0))
    }
  }
}

struct ActionOrGroupRow: View {
  @Binding var item: ActionOrGroup
  var path: [Int]
  let onDelete: () -> Void
  let onDuplicate: () -> Void
  @EnvironmentObject var userConfig: UserConfig
  @Binding var expandedGroups: Set<[Int]>

  var body: some View {
    switch item {
    case .action:
      ActionRow(
        action: Binding(
          get: {
            if case .action(let action) = item { return action }
            fatalError("Unexpected state")
          },
          set: { newAction in
            item = .action(newAction)
          }
        ),
        path: path,
        onDelete: onDelete,
        onDuplicate: onDuplicate
      )
    case .group:
      GroupRow(
        group: Binding(
          get: {
            if case .group(let group) = item { return group }
            fatalError("Unexpected state")
          },
          set: { newGroup in
            item = .group(newGroup)
          }
        ),
        path: path,
        expandedGroups: $expandedGroups,
        onDelete: onDelete,
        onDuplicate: onDuplicate
      )
    }
  }
}

struct ActionRow: View {
  @Binding var action: Action
  var path: [Int]
  let onDelete: () -> Void
  let onDuplicate: () -> Void
  @FocusState private var isKeyFocused: Bool
  @EnvironmentObject var userConfig: UserConfig

  var body: some View {
    HStack(spacing: generalPadding) {
      KeyButton(
        text: Binding(
          get: { action.key ?? "" },
          set: { action.key = $0 }
        ), placeholder: "Key", validationError: validationErrorForKey,
        onKeyChanged: { userConfig.finishEditingKey() }
      )

      Picker("Type", selection: $action.type) {
        Text("Application").tag(Type.application)
        Text("URL").tag(Type.url)
        Text("Command").tag(Type.command)
        Text("Folder").tag(Type.folder)
      }
      .frame(width: 110)
      .labelsHidden()

      switch action.type {
      case .application:
        Button("Choose…") {
          let panel = NSOpenPanel()
          panel.allowedContentTypes = [.applicationBundle, .application]
          panel.canChooseFiles = true
          panel.canChooseDirectories = true
          panel.allowsMultipleSelection = false
          panel.directoryURL = URL(fileURLWithPath: "/Applications")

          if panel.runModal() == .OK {
            action.value = panel.url?.path ?? ""
          }
        }
        Text(action.value).truncationMode(.middle).lineLimit(1)
      case .folder:
        Button("Choose…") {
          let panel = NSOpenPanel()
          panel.allowsMultipleSelection = false
          panel.canChooseDirectories = true
          panel.canChooseFiles = false
          panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser

          if panel.runModal() == .OK {
            action.value = panel.url?.path ?? ""
          }
        }
        Text(action.value).truncationMode(.middle).lineLimit(1)
      default:
        TextField("Value", text: $action.value)
      }

      Spacer()

      TextField(action.bestGuessDisplayName, text: $action.label ?? "").frame(
        width: 120
      )
      .padding(.trailing, generalPadding)

      let iconSize = NSSize(width: 24, height: 24)

      if action.type == .application {
        AppIconImage(appPath: action.value, size: iconSize)
          .padding(.horizontal, 8)
      } else {
        var icon: String {
          switch action.type {
          case .application: return "macwindow"
          case .url: return "link"
          case .command: return "terminal"
          case .folder: return "folder"
          default: return "questionmark"
          }
        }

        Button(
          action: {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.applicationBundle, .application]
            panel.canChooseFiles = true
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.directoryURL = URL(fileURLWithPath: "/Applications")

            if panel.runModal() == .OK {
              action.iconPath = panel.url?.path
            } else {
              action.iconPath = nil
            }
          }) {
            if action.iconPath != nil && !action.iconPath!.isEmpty {
              AppIconImage(appPath: action.iconPath!, size: iconSize)
            } else {
              Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: iconSize.width, height: iconSize.height, alignment: .center)
            }
          }
      }

      Button(role: .none, action: onDuplicate) {
        Image(systemName: "document.on.document")
      }
      .buttonStyle(.plain)

      Button(role: .destructive, action: onDelete) {
        Image(systemName: "trash")
      }
      .buttonStyle(.plain)
      .padding(.trailing, generalPadding)
    }
  }

  private var validationErrorForKey: ValidationErrorType? {
    guard !path.isEmpty else { return nil }

    // Find validation errors for this item
    let errors = userConfig.validationErrors.filter { error in
      error.path == path
    }

    if let error = errors.first {
      return error.type
    }

    return nil
  }
}

struct GroupRow: View {
  @Binding var group: Group
  var path: [Int]
  @Binding var expandedGroups: Set<[Int]>
  @FocusState private var isKeyFocused: Bool
  let onDelete: () -> Void
  let onDuplicate: () -> Void
  @EnvironmentObject var userConfig: UserConfig

  private var isExpanded: Bool {
    expandedGroups.contains(path)
  }

  private func toggleExpanded() {
    if isExpanded {
      expandedGroups.remove(path)
    } else {
      expandedGroups.insert(path)
    }
  }

  var body: some View {
    VStack(spacing: generalPadding) {
      HStack(spacing: generalPadding) {
        KeyButton(
          text: Binding(
            get: { group.key ?? "" },
            set: { group.key = $0 }
          ),
          placeholder: "Group Key",
          validationError: validationErrorForKey,
          onKeyChanged: { userConfig.finishEditingKey() }
        )

        Button(
          role: .none,
          action: {
            withAnimation(.easeOut(duration: 0.1)) {
              toggleExpanded()
            }

          }
        ) {
          Image(systemName: "chevron.right")
            .rotationEffect(.degrees(isExpanded ? 90 : 0))
            .padding(.leading, generalPadding / 3)
        }.buttonStyle(.plain)

        Spacer(minLength: 0)

        TextField("Label", text: $group.label ?? "").frame(width: 120)
          .padding(.trailing, generalPadding)

        Button(role: .none, action: onDuplicate) {
          Image(systemName: "document.on.document")
        }
        .buttonStyle(.plain)

        Button(role: .destructive, action: onDelete) {
          Image(systemName: "trash")
        }
        .buttonStyle(.plain)
        .padding(.trailing, generalPadding)
      }

      if isExpanded {
        HStack(spacing: 0) {
          Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 1)
            .padding(.leading, generalPadding)
            .padding(.trailing, generalPadding / 3)

          GroupContentView(group: $group, parentPath: path, expandedGroups: $expandedGroups)
            .padding(.leading, generalPadding)
        }
      }
    }
    .padding(.horizontal, 0)
  }

  private var validationErrorForKey: ValidationErrorType? {
    guard !path.isEmpty else { return nil }

    // Find validation errors for this item
    let errors = userConfig.validationErrors.filter { error in
      error.path == path
    }

    if let error = errors.first {
      return error.type
    }

    return nil
  }
}

#Preview {
  let group = Group(
    key: "",
    actions: [
      // Level 1 actions
      .action(
        Action(key: "t", type: .application, value: "/Applications/WezTerm.app")
      ),
      .action(
        Action(key: "f", type: .application, value: "/Applications/Firefox.app")
      ),
      .action(
        Action(key: "a", type: .command, value: "ls")
      ),

      // Level 1 group with actions
      .group(
        Group(
          key: "b",
          actions: [
            .action(
              Action(
                key: "c", type: .application,
                value: "/Applications/Google Chrome.app")),
            .action(
              Action(
                key: "s", type: .application, value: "/Applications/Safari.app")
            ),
          ])),

      // Level 1 group with subgroups
      .group(
        Group(
          key: "r",
          actions: [
            .action(
              Action(
                key: "e", type: .url,
                value:
                  "raycast://extensions/raycast/emoji-symbols/search-emoji-symbols"
              )),
            .group(
              Group(
                key: "w",
                actions: [
                  .action(
                    Action(
                      key: "f", type: .url,
                      value: "raycast://window-management/maximize")),
                  .action(
                    Action(
                      key: "h", type: .url,
                      value: "raycast://window-management/left-half")),
                ])),
          ])),
    ])

  let userConfig = UserConfig()

  return ConfigEditorView(group: .constant(group), expandedGroups: .constant(Set<[Int]>()))
    .frame(width: 600, height: 500)
    .environmentObject(userConfig)
}
