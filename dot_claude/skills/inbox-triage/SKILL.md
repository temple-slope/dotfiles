---
name: inbox-triage
description: "Gmail: Show only important unread mail (Claude-judged) with clickable links, then mark all fetched unread as read."
metadata:
  version: 0.22.5
  openclaw:
    category: "productivity"
    requires:
      bins:
        - gws
    cliHelp: "gws gmail +triage --help"
---

# inbox-triage

> **PREREQUISITE:** Read `../gws-shared/SKILL.md` for auth, global flags, and security rules. If missing, run `gws generate-skills` to create it.

Fetch unread mail, surface only the ones Claude judges important, and mark **all** fetched unread as read (clear the inbox).

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

## Workflow

1. Fetch unread mail with bodies (use `--format json` so Claude can read content for the importance judgment).
2. Claude reads each message and selects the **important** ones (see "Importance judgment" below).
3. Present only the important ones to the user as clickable Markdown links.
4. Mark **all fetched unread messages** as read — not just the important ones. The point is to clear the inbox.

## Importance judgment

Claude decides importance from message content. Treat these as important by default:

- Direct requests / questions addressed to the user (work, scheduling, decisions)
- Calendar / meeting invites and changes
- Security alerts, account-lockout, 2FA, password-reset, suspicious-login notices
- Payment failures, billing issues, deadline reminders with concrete dates
- Replies in threads the user started or is actively participating in
- Anything from a real person (not noreply / no-reply / donotreply senders)

Treat these as **not** important and skip surfacing them (but still mark as read):

- Marketing, newsletters, product announcements, promotional offers
- Social network notifications (likes, follows, recommendations)
- Receipts and order confirmations with no action required
- Automated digests, status reports, "weekly summary" mail
- Anything in `category:promotions` / `category:social` / `category:updates` / `category:forums` unless it clearly contains an action item

If a message is borderline, prefer surfacing it. Better to over-include than to bury something the user needed to see.

## Output formatting — ALWAYS include clickable Gmail links

When presenting triage results to the user, **always attach a Gmail URL for each important message** so they can jump straight to it. The CLI's table output only shows the message ID, so construct the URL from that ID.

URL template (works for inbox + archived messages):

```
https://mail.google.com/mail/u/0/#all/<message_id>
```

For messages still in inbox, `#inbox/<id>` also works. Default to `#all/<id>` because it works regardless of label.

Example presentation (Markdown):

```markdown
- **Example Sender** Sample subject line about a meeting — [開く](https://mail.google.com/mail/u/0/#all/MESSAGE_ID_1)
- **noreply@example.com** Sample subject line about a receipt — [開く](https://mail.google.com/mail/u/0/#all/MESSAGE_ID_2)
```

Do **not** dump the raw ID column to the user without also linking it. The link is the deliverable.

## Post-triage: Mark as Read

After surfacing the important ones, mark **every fetched unread message** (important and not) as read using `batchModify`. The whole point of this skill is to clear the unread state so the inbox stays empty.

```bash
gws gmail users messages batchModify \
--params '{"userId":"me"}' \
--json '{"ids":["<id1>","<id2>",...],"removeLabelIds":["UNREAD"]}'
```

Pass **all** IDs returned by the initial fetch, not only the ones surfaced to the user. The message IDs are available in the `id` column / field of the triage output.

Skip this step only when the query was explicitly non-default (e.g. `from:foo`, `is:important`) — those are read-only views, not triage runs. Ask if unsure.

## Tips

- Defaults to table output format.
- For JSON post-processing, pair `--format json` with `jq` to extract `id` and build URLs in bulk.

## See Also

- [gws-shared](../gws-shared/SKILL.md) — Global flags and auth
- [gws-gmail](../gws-gmail/SKILL.md) — All send, read, and manage email commands
