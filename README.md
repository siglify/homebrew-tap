# siglify/homebrew-tap

Siglify's public Homebrew tap. Holds formulae for everything we ship —
both internal (org-private) and OSS.

```bash
brew tap siglify/tap
```

## Available formulae

| Formula | Source repo | Visibility | What |
|---|---|---|---|
| [`siglify-base`](Formula/siglify-base.rb) | [siglify/base](https://github.com/siglify/base) | **private** | The company dev-laptop baseline: org Claude config, hooks, the `siglify` CLI. Installed on every Siglify-issued laptop. |
| [`siglify-base@0.1`](Formula/siglify-base@0.1.rb) | [siglify/base](https://github.com/siglify/base) | **private** | Versioned pin of `siglify-base` to the 0.1.x line, for rollback. |

## Internal formulae (private source)

Some formulae (currently: `siglify-base`, `siglify-base@MAJOR.MINOR`)
point at private GitHub repos. Anyone can `brew tap siglify/tap` and
see the formula files — but to actually install, brew needs to download
the source tarball, which requires GitHub auth on the org.

**Set up GitHub auth for brew:**

```bash
# Option A — let `gh` install a credential helper that brew picks up.
gh auth login
gh auth setup-git

# Option B — set HOMEBREW_GITHUB_API_TOKEN explicitly. Generate a token
# with `repo:read` scope on the siglify org; add to your shell rc:
echo 'export HOMEBREW_GITHUB_API_TOKEN="ghp_..."' >> ~/.zshrc
```

Without auth, `brew install siglify/tap/siglify-base` fails with a
404 from GitHub when fetching the tarball.

## OSS formulae (public source)

When Siglify ships OSS, the formula lives here too. Anyone in the
world can `brew tap siglify/tap && brew install <thing>` with no
token at all — public source repos require no auth.

## Adding a formula

Formulae in this tap are auto-bumped by the release workflow in the
**source** repo (e.g. `siglify/base/.github/workflows/release.yml`).
On every `VERSION` bump in the source repo, that workflow:

1. Tags the source repo
2. Computes the tarball sha256
3. Opens a PR here updating the formula
4. Auto-merges on green CI

For brand-new formulae (first ship), add the `Formula/<name>.rb`
manually, then wire up the source repo's release workflow.

## License

The formulae in this repo are MIT. The software they install is
licensed individually — see each formula's `homepage` and the source
repo's `LICENSE` file.
