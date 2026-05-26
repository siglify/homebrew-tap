class SiglifyBase < Formula
  desc "Siglify dev-laptop baseline (Claude config, hooks, siglify CLI)"
  homepage "https://github.com/siglify/base"
  # Git strategy (not tarball) so `git clone` runs against the private repo,
  # respecting the user's git credential helper (`gh auth setup-git`).
  # GitHub's /archive/refs/tags/*.tar.gz URL cannot be authenticated via
  # HOMEBREW_GITHUB_API_TOKEN — that env var is API-only, not for downloads.
  url "https://github.com/siglify/base.git", tag: "v0.1.4"
  version "0.1.4"
  license "Proprietary"

  depends_on "asakin/tap/dragoman"
  depends_on "jq"

  def install
    bin.install "bin/siglify"
    pkgshare.install "share/CLAUDE.md"
    pkgshare.install "share/hooks"
    (etc/"siglify-base").install "etc/com.siglify.base.update.plist"
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
        • Install + load the daily-upgrade launchd agent
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
