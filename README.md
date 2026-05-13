# wisdom

Personal wisdom corpus + capture CLI.

This repo is the **single source of truth** for the wisdom snippets:
markdown files with frontmatter under `wisdoms/<YYYY>/<MM>/<ulid>.md`, plus a
shell-first CLI to capture them from any terminal or agent session. The
snippets are rendered as a public page by
[amittiwari.me](https://amittiwari.me/wisdom), which consumes this repo as a
git submodule at build time — there is no longer a standalone Jekyll site
here.

Capture a snippet from any terminal or agent session. The skill categorizes
it into a closed bucket, writes a frontmatter markdown file under `wisdoms/`,
commits, and (optionally) pushes. amittiwari.me picks it up on its next
build.

## Quickstart

```bash
git clone <this-repo> ~/Projects/AmitTiwari/wisdom
cd ~/Projects/AmitTiwari/wisdom
./install.sh
# Follow the printed instructions to add WISDOM_REPO to ~/.zshrc

wisdom "Premature optimization is the root of all evil. — Donald Knuth"
```

## Subcommands

See [`docs/USAGE.md`](./docs/USAGE.md).

## Install

See [`docs/INSTALL.md`](./docs/INSTALL.md).

## Architecture

See [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md).

## License

Dual: MIT for code, CC BY 4.0 for the corpus under `wisdoms/`. See
[`LICENSE`](./LICENSE).
