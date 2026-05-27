class SiglifyBaseAT01 < Formula
  desc "Siglify dev-laptop baseline (Claude config, hooks, siglify CLI) — pinned to 0.1.x"
  homepage "https://github.com/siglify/base"
  # Git strategy — see siglify-base.rb for rationale.
  url "https://github.com/siglify/base.git", tag: "v0.1.5"
  version "0.1.5"
  license "Proprietary"

  # Versioned formula for rollback. The unpinned `siglify-base` always
  # tracks the latest line; this one stays on 0.1.x patches forever.

  keg_only :versioned_formula

  depends_on "asakin/tap/dragoman"
  depends_on "jq"

  def install
    inreplace "bin/siglify",
              /VERSION="\$\{SIGLIFY_BASE_VERSION:-[0-9.]+\}"/,
              "VERSION=\"${SIGLIFY_BASE_VERSION:-#{version}}\""
    bin.install "bin/siglify"
    pkgshare.install "share/CLAUDE.md"
    pkgshare.install "share/hooks"
    (etc/"siglify-base").install "etc/com.siglify.base.update.plist"
  end

  # See siglify-base.rb for why there's no post_install — `siglify wire`
  # handles all user-space setup (idempotent; re-runnable any time).

  def caveats
    <<~EOS
      siglify-base@0.1 (pinned to 0.1.x) installed.

      One more step:  siglify wire

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
