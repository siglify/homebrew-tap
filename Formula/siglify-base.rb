class SiglifyBase < Formula
  desc "Siglify dev-laptop baseline (Claude config, hooks, siglify CLI)"
  homepage "https://github.com/siglify/base"
  url "https://github.com/siglify/base/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "85173e41c6d828b41d514a944fddcd5ba8d5dae5d6bd2c9f275db6283a52bb3c"
  version "0.1.0"
  license "Proprietary"

  depends_on "asakin/tap/dragoman"
  depends_on "jq"

  option "without-wire", "Skip ~/.claude/ wiring; run `siglify wire` manually when ready"

  def install
    bin.install "bin/siglify"
    pkgshare.install "share/CLAUDE.md"
    pkgshare.install "share/hooks"
    (etc/"siglify-base").install "etc/com.siglify.base.update.plist"
  end

  def post_install
    home = ENV["HOME"]
    mkdir_p "#{home}/.siglify/hooks"
    ln_sf pkgshare/"CLAUDE.md", "#{home}/.siglify/CLAUDE.md"
    ln_sf pkgshare/"hooks/temporal.py", "#{home}/.siglify/hooks/temporal.py"

    # Render the launchd plist template (substitute __HOME__) into LaunchAgents.
    plist_template = (etc/"siglify-base/com.siglify.base.update.plist").read
    plist_rendered = plist_template.gsub("__HOME__", home)
    plist_target = "#{home}/Library/LaunchAgents/com.siglify.base.update.plist"
    File.write(plist_target, plist_rendered)

    # Reload the agent so the new version is picked up.
    system "launchctl", "unload", plist_target
    system "launchctl", "load", plist_target

    if build.with?("wire")
      system bin/"siglify", "wire"
    else
      ohai "Skipped ~/.claude/ wiring (--without-wire). Run `siglify wire` when ready."
    end
  end

  def caveats
    <<~EOS
      siglify-base installed.

        ~/.siglify/CLAUDE.md            → org Claude baseline (imported into ~/.claude/CLAUDE.md)
        ~/.siglify/hooks/temporal.py    → temporal context hook (wired into ~/.claude/settings.json)
        ~/Library/LaunchAgents/com.siglify.base.update.plist  (daily upgrade ~3am)

      Try:  siglify           # welcome banner
      Try:  siglify status    # what's installed + wired

      Inner-source: PRs welcome at https://github.com/siglify/base
    EOS
  end

  test do
    assert_predicate bin/"siglify", :executable?
    assert_match "siglify-base", shell_output("#{bin}/siglify version")
  end
end
