class SiglifyBase < Formula
  desc "Siglify dev-laptop baseline (Claude config, hooks, siglify CLI)"
  homepage "https://github.com/siglify/base"
  # Git strategy (not tarball) so `git clone` runs against the private repo,
  # respecting the user's git credential helper (`gh auth setup-git`).
  # GitHub's /archive/refs/tags/*.tar.gz URL cannot be authenticated via
  # HOMEBREW_GITHUB_API_TOKEN — that env var is API-only, not for downloads.
  url "https://github.com/siglify/base.git", tag: "v0.1.2"
  version "0.1.2"
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

    ohai "Preparing ~/.siglify/"
    mkdir_p "#{home}/.siglify/hooks"
    ln_sf pkgshare/"CLAUDE.md", "#{home}/.siglify/CLAUDE.md"
    ln_sf pkgshare/"hooks/temporal.py", "#{home}/.siglify/hooks/temporal.py"

    ohai "Installing launchd agent"
    plist_template = (etc/"siglify-base/com.siglify.base.update.plist").read
    plist_rendered = plist_template.gsub("__HOME__", home)
    plist_target = "#{home}/Library/LaunchAgents/com.siglify.base.update.plist"
    mkdir_p "#{home}/Library/LaunchAgents"  # defensive: some fresh macOS installs lack this
    File.write(plist_target, plist_rendered)

    # launchctl: unload first (quiet — fine if not loaded), then load.
    # Load failures are recoverable (user can launchctl load manually),
    # so we opoo and continue rather than raise + abort post_install.
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
        opoo "  Diagnose:      siglify status"
      end
    else
      ohai "Skipped ~/.claude/ wiring (--without-wire). Run `siglify wire` when ready."
    end

    ohai "post_install complete (see `siglify status` for full state)"
  end

  def caveats
    <<~EOS
      siglify-base installed.

        ~/.siglify/CLAUDE.md            → org Claude baseline (imported into ~/.claude/CLAUDE.md)
        ~/.siglify/hooks/temporal.py    → temporal context hook (wired into ~/.claude/settings.json)
        ~/Library/LaunchAgents/com.siglify.base.update.plist  (daily upgrade ~3am)

      Try:  siglify           # welcome banner
      Try:  siglify status    # what's installed + wired

      Personal preferences (Spotify on, custom src_root, watched files):
        Drop a JSON file at ~/.siglify/hooks/temporal.local.json.
        See `siglify-base` README for the schema.

      Inner-source: PRs welcome at https://github.com/siglify/base
    EOS
  end

  test do
    assert_predicate bin/"siglify", :executable?
    assert_match "siglify-base", shell_output("#{bin}/siglify version")
  end
end
