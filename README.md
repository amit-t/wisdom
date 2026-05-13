# wisdom

Personal wisdom corpus + searchable site.

Capture a snippet from any terminal or agent session. The skill categorizes
it into a closed bucket, writes a frontmatter Markdown file under `wisdoms/`,
commits, and (optionally) pushes. The repo deploys as a neo-brutalist GitHub
Pages site with Pagefind search.

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
