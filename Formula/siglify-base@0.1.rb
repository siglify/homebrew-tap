class SiglifyBaseAT01 < Formula
  desc "Siglify dev-laptop baseline (Claude config, hooks, siglify CLI) — pinned to 0.1.x"
  homepage "https://github.com/siglify/base"
  url "https://github.com/siglify/base/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "85173e41c6d828b41d514a944fddcd5ba8d5dae5d6bd2c9f275db6283a52bb3c"
  version "0.1.0"
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
    mkdir_p "#{home}/.siglify/hooks"
    ln_sf pkgshare/"CLAUDE.md", "#{home}/.siglify/CLAUDE.md"
    ln_sf pkgshare/"hooks/temporal.py", "#{home}/.siglify/hooks/temporal.py"

    plist_template = (etc/"siglify-base/com.siglify.base.update.plist").read
    plist_rendered = plist_template.gsub("__HOME__", home)
    plist_target = "#{home}/Library/LaunchAgents/com.siglify.base.update.plist"
    File.write(plist_target, plist_rendered)

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
