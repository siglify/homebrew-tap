class SiglifyBaseAT01 < Formula
  desc "Siglify dev-laptop baseline (Claude config, hooks, siglify CLI) — pinned to 0.1.x"
  homepage "https://github.com/siglify/base"
  # Git strategy — see siglify-base.rb for rationale.
  url "https://github.com/siglify/base.git", tag: "v0.1.1"
  version "0.1.1"
  license "Proprietary"

  # Versioned formula for rollback. The unpinned `siglify-base` always
  # tracks the latest line; this one stays on 0.1.x patches forever.
  # Usage:
  #   brew uninstall siglify-base                  # remove latest
  #   brew install siglify/tap/siglify-base@0.1    # pin to 0.1.x

  keg_only :versioned_formula

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

    ohai "Preparing ~/.siglify/"
    mkdir_p "#{home}/.siglify/hooks"
    ln_sf pkgshare/"CLAUDE.md", "#{home}/.siglify/CLAUDE.md"
    ln_sf pkgshare/"hooks/temporal.py", "#{home}/.siglify/hooks/temporal.py"

    ohai "Installing launchd agent"
    plist_template = (etc/"siglify-base/com.siglify.base.update.plist").read
    plist_rendered = plist_template.gsub("__HOME__", home)
    plist_target = "#{home}/Library/LaunchAgents/com.siglify.base.update.plist"
    mkdir_p "#{home}/Library/LaunchAgents"
    File.write(plist_target, plist_rendered)

    quiet_system "launchctl", "unload", plist_target
    if quiet_system("launchctl", "load", plist_target)
      ohai "launchd agent loaded (com.siglify.base.update)"
    else
      opoo "launchctl load failed for #{plist_target}"
      opoo "  Try manually: launchctl load #{plist_target}"
    end

    if build.with?("wire")
      ohai "Wiring siglify-base into ~/.claude/ (idempotent)"
      if quiet_system(bin/"siglify", "wire")
        ohai "wire complete"
      else
        opoo "siglify wire failed during post_install"
        opoo "  Run manually:  siglify wire"
      end
    else
      ohai "Skipped ~/.claude/ wiring (--without-wire). Run `siglify wire` when ready."
    end

    ohai "post_install complete (see `siglify status` for full state)"
  end

  def caveats
    <<~EOS
      siglify-base@0.1 (pinned to 0.1.x) installed.

      To return to the rolling latest:
        brew uninstall siglify-base@0.1
        brew install siglify/tap/siglify-base
    EOS
  end

  test do
    assert_predicate bin/"siglify", :executable?
    assert_match "siglify-base", shell_output("#{bin}/siglify version")
  end
end
