class SiglifyBase < Formula
  desc "Siglify dev-laptop baseline (Claude config, hooks, siglify CLI)"
  homepage "https://github.com/siglify/base"
  # Git strategy (not tarball) so `git clone` runs against the private repo,
  # respecting the user's git credential helper (`gh auth setup-git`).
  # GitHub's /archive/refs/tags/*.tar.gz URL cannot be authenticated via
  # HOMEBREW_GITHUB_API_TOKEN — that env var is API-only, not for downloads.
  url "https://github.com/siglify/base.git", tag: "v0.2.1"
  version "0.2.1"
  license "Proprietary"

  depends_on "asakin/tap/dragoman"
  depends_on "jq"

  def install
    # Bake the formula's version into the CLI's default VERSION constant
    # so `siglify version` reports the installed Cellar version (instead
    # of whatever was hardcoded in bin/siglify at tag time).
    inreplace "bin/siglify",
              /VERSION="\$\{SIGLIFY_BASE_VERSION:-[0-9.]+\}"/,
              "VERSION=\"${SIGLIFY_BASE_VERSION:-#{version}}\""
    bin.install "bin/siglify"
    pkgshare.install "share/CLAUDE.md"
    pkgshare.install "share/hooks"
    # Ship all scheduler templates regardless of OS — the install is
    # tiny, and `siglify wire` picks the right one (launchd on macOS,
    # systemd user timer on Linux) at wire-time.
    (etc/"siglify-base").install Dir["etc/*"]
  end

  # NO post_install. macOS sandboxes brew's post_install and blocks writes to
  # ~/, so symlinks into ~/.siglify/, the launchd plist into
  # ~/Library/LaunchAgents/, and the ~/.claude/ wiring all fail with EPERM.
  # All user-space setup is done by `siglify wire` — the user runs it once
  # after install (the caveats below tell them to). It's idempotent and
  # safe to re-run any time, so `brew upgrade` doesn't need to re-trigger it.

  def caveats
    <<~EOS
      siglify-base installed under #{prefix}.

      One more step — run this to set up your laptop:

          siglify wire

      That command (idempotent, re-runnable any time) will:
        • Symlink ~/.siglify/CLAUDE.md and ~/.siglify/hooks/temporal.py
        • Install + activate the daily-upgrade scheduler:
            macOS → launchd agent in ~/Library/LaunchAgents/
            Linux → systemd user timer in ~/.config/systemd/user/
                    (one-time: sudo loginctl enable-linger $USER, so the
                    timer fires when you're logged out)
        • Add the SIGLIFY-MANAGED @-import block to the TOP of ~/.claude/CLAUDE.md
        • Register the temporal hook on UserPromptSubmit in ~/.claude/settings.json
          (and scrub any stale temporal.py hook entries first)

      Then:  siglify status    # confirm everything's wired
      Try:   siglify           # welcome banner

      Personal preferences (Spotify on, custom src_root, watched files):
        Drop a JSON file at ~/.siglify/hooks/temporal.json.
        See `siglify-base` README for the schema.

      Inner-source: PRs welcome at https://github.com/siglify/base
    EOS
  end

  test do
    assert_predicate bin/"siglify", :executable?
    assert_match "siglify-base", shell_output("#{bin}/siglify version")
  end
end
