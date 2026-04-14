---
name: gws-gmail-triage
description: "Gmail: Show unread inbox summary (sender, subject, date)."
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

## Post-triage: Mark as Read

After displaying the summary, mark all shown messages as read using `batchModify`:

```bash
gws gmail users messages batchModify \
--params '{"userId":"me"}' \
--json '{"ids":["<id1>","<id2>",...],"removeLabelIds":["UNREAD"]}'
```

The message IDs are available in the `id` column of the triage output. Always execute this step after showing the summary.

## Tips

- Defaults to table output format.

## See Also

- [gws-shared](../gws-shared/SKILL.md) — Global flags and auth
- [gws-gmail](../gws-gmail/SKILL.md) — All send, read, and manage email commands
