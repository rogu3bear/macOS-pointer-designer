# Homebrew Cask for Pointer Designer
# Install: brew install --cask pointer-designer
# Or add tap and install:
#   brew tap rogu3bear/pointer-designer
#   brew install --cask pointer-designer

cask "pointer-designer" do
  version "1.0.0"
  sha256 :no_check  # Update with actual SHA256 after release

  url "https://github.com/rogu3bear/macOS-pointer-designer/releases/download/v#{version}/PointerDesigner.dmg"
  name "Pointer Designer"
  desc "System-wide macOS cursor customization with dynamic contrast"
  homepage "https://github.com/rogu3bear/macOS-pointer-designer"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :ventura"

  app "PointerDesigner.app"

  postflight do
    system_command "/usr/bin/open",
                   args: ["-a", "#{appdir}/PointerDesigner.app", "--args", "--install-helper"],
                   sudo: false
  end

  uninstall quit: "com.pointerdesigner.app",
            launchctl: "com.pointerdesigner.helper",
            delete: [
              "/Library/PrivilegedHelperTools/com.pointerdesigner.helper",
              "/Library/LaunchDaemons/com.pointerdesigner.helper.plist",
            ]

  zap trash: [
    "~/Library/Application Support/PointerDesigner",
    "~/Library/Caches/com.pointerdesigner.app",
    "~/Library/Preferences/com.pointerdesigner.app.plist",
  ]
end
