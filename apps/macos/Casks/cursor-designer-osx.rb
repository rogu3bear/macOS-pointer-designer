# Homebrew Cask for Cursor Designer
# Install: brew install --cask cursor-designer-osx
# Or add tap and install:
#   brew tap rogu3bear/cursor-designer-osx
#   brew install --cask cursor-designer-osx

cask "cursor-designer-osx" do
  version "1.0.0"
  sha256 :no_check  # Update with actual SHA256 after release

  url "https://github.com/rogu3bear/cursor-designer-osx/releases/download/v#{version}/CursorDesigner.dmg"
  name "Cursor Designer"
  desc "System-wide macOS cursor customization with dynamic contrast"
  homepage "https://github.com/rogu3bear/cursor-designer-osx"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"

  # Prevent dual installs with old cask name
  conflicts_with cask: "pointer-designer"

  app "CursorDesigner.app"

  postflight do
    system_command "/usr/bin/open",
                   args: ["-a", "#{appdir}/CursorDesigner.app", "--args", "--install-helper"],
                   sudo: false
  end

  # Note: Bundle IDs preserved for compatibility
  uninstall quit: "com.pointerdesigner.app",
            launchctl: "com.pointerdesigner.helper",
            delete: [
              "/Library/PrivilegedHelperTools/com.pointerdesigner.helper",
              "/Library/LaunchDaemons/com.pointerdesigner.helper.plist",
            ]

  zap trash: [
    "~/Library/Application Support/CursorDesigner",
    "~/Library/Application Support/PointerDesigner",  # Legacy name
    "~/Library/Caches/com.pointerdesigner.app",
    "~/Library/Preferences/com.pointerdesigner.app.plist",
  ]
end
