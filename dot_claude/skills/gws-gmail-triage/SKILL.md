---
name: gws-gmail-triage
description: "Gmail: Show unread inbox summary (sender, subject, date) with clickable links."
metadata:
  version: 0.22.5
  openclaw:
    category: "productivity"
    requires:
      bins:
        - gws
    cliHelp: "gws gmail +triage --help"
---

# gmail +triage

> **PREREQUISITE:** Read `../gws-shared/SKILL.md` for auth, global flags, and security rules. If missing, run `gws generate-skills` to create it.
>
> **NOTE:** This SKILL.md is managed via chezmoi (`dot_claude/skills/gws-gmail-triage/SKILL.md`). The `gws generate-skills` command regenerates the upstream copy at `~/.claude/skills/gws-gmail-triage/SKILL.md` and will overwrite local edits. Re-run `chezmoi apply` after regeneration.

Show unread inbox summary (sender, subject, date) and mark displayed messages as read.

## Usage

```bash
gws gmail +triage
```

## Flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--max` | — | 20 | Maximum messages to show (default: 20) |
| `--query` | — | — | Gmail search query (default: is:unread) |
| `--labels` | — | — | Include label names in output |

## Examples

```bash
gws gmail +triage
gws gmail +triage --max 5 --query 'from:boss'
gws gmail +triage --format json | jq '.[].subject'
gws gmail +triage --labels
```

## Output formatting — ALWAYS include clickable Gmail links

When presenting triage results to the user, **always attach a Gmail URL for each message** so they can jump straight to it. The CLI's table output only shows the message ID, so construct the URL from that ID.

URL template (works for inbox + archived messages):

```
https://mail.google.com/mail/u/0/#all/<message_id>
```

For messages still in inbox, `#inbox/<id>` also works. Default to `#all/<id>` because it works regardless of label.

Example presentation (Markdown):

```markdown
- **転職ドラフト** 5/20開幕 参加確認 — [開く](https://mail.google.com/mail/u/0/#all/19e2ac785f46099f)
- **SBI損保** 自動車保険継続手続き — [開く](https://mail.google.com/mail/u/0/#all/19e2f9948cc36f84)
```

Do **not** dump the raw ID column to the user without also linking it. The link is the deliverable.

## Post-triage: Mark as Read

After displaying the summary, mark all shown messages as read using `batchModify` **only when the query targets unread mail** (the default `is:unread`). For ad-hoc queries like `is:important` or `from:foo`, skip this step — the user likely just wanted a view, not a state change. Ask if unsure.

```bash
gws gmail users messages batchModify \
--params '{"userId":"me"}' \
--json '{"ids":["<id1>","<id2>",...],"removeLabelIds":["UNREAD"]}'
```

The message IDs are available in the `id` column of the triage output.

## Tips

- Defaults to table output format.
- For JSON post-processing, pair `--format json` with `jq` to extract `id` and build URLs in bulk.

## See Also

- [gws-shared](../gws-shared/SKILL.md) — Global flags and auth
- [gws-gmail](../gws-gmail/SKILL.md) — All send, read, and manage email commands
