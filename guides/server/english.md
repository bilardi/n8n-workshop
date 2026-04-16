# n8n Guide - Shared Server
## For meetup participants

---

## How to access the server

1. Connect to the meetup Telegram channel
2. Go to the **n8n** topic
3. You'll find the link to the server we'll use today
4. Open the link in your browser: the n8n interface is already ready

---

## Table of Contents

1. [Part 5: Full workflow with webhook](#part-5-full-workflow-with-webhook)

---

## Telegram Bot for Notifications

> **Before continuing:** complete [Parts 1-4 of the introduction](../intro/english.md) (Telegram bot, credentials, Chat ID, test workflow). If you're starting from scratch, start there.

For credential configuration and security notes, see [intro/english.md](../intro/english.md#configuring-telegram-credentials).

### Part 5: Full workflow with webhook

Create a new workflow. Copy Nodes B, C and D from Workflow 1 (select them - Ctrl+C - new workflow - Ctrl+V): they're already configured and will be reused in the `/status` branch.

Unlike the Docker guide which uses **polling** (Schedule + HTTP Request), here we use the **Telegram Trigger** node which receives messages via **webhook**: Telegram calls n8n directly on each message, without periodic polling.

> The Telegram Trigger only works on a server reachable publicly via HTTPS. The meetup server is already configured. It doesn't work on localhost - that's why the Docker guide uses polling.

**Workflow structure:**

```
[Telegram Trigger]
  ↓
[Switch: route commands]
  ├── /status  → [Node B] → [Node C] → [Node D]
  └── fallback → [Node 5: IF regex]
                     ├── Yes → [Node 6: Telegram]
                     └── No → (no action)
```

> [Workflow diagram](../../mermaid/english/workflow2-webhook.mermaid)

#### Node 1: Telegram, Trigger, on message

- Resource: **Message**
- Credential: the credential created in Part 2
- n8n registers the webhook automatically with Telegram when the workflow is activated: no extra configuration needed
- No Schedule, HTTP Request or "filter recent" Code node needed: the Trigger delivers only new messages

---

#### Node 4: Switch, route by command type

- Enable **Options +** > **Fallback Output** > Extra Output
- Routing Rule 1: `{{ $json.message.text }}` contains `/status`
  - Rename output: status

Compared to the Docker guide, **the "no message" rule is removed** (`$json.message` not exists): the Telegram Trigger only fires when a message arrives, and the no-message condition never occurs.

#### Nodes B, C, D (/status branch)

Copy Nodes B, C and D from Workflow 1 (select them - Ctrl+C - new workflow - Ctrl+V): they're already configured in [Part 4](../intro/english.md#part-4-workflow-1---count-files-with-manual-trigger).

Connect the `/status` output of Node 4 to **Node B** - the flow continues automatically to Node C and Node D.

#### Node 5 - IF (after the Fallback): is it a command?

- Condition: `{{ $json.message.text }}` matches regex `^\/\w+`

#### Node 6 - Telegram: unknown command
Copy Node D and modify it
- Credential: see [Configuring Telegram Credentials](../intro/english.md#configuring-telegram-credentials)
- Operation: Send Message
- Chat ID: `{{ $json.message.chat.id }}` and click the icon to the right of the field and choose **Expression** (by default it's Fixed and the value is sent as literal text)
- Text: `Unknown command {{ $json.message.text }}`

#### Dynamic Chat ID

In this workflow, the **dynamic Chat ID** `{{ $json.message.chat.id }}` is used in the Telegram Send Message nodes (Node D and Node 6) - with the Telegram Trigger this field is always available and correct.

> In the Docker guide the Chat ID is fixed (found in Part 3) because with polling (`getUpdates`) the dynamic Chat ID doesn't work in this path - [Docker guide](../docker/english.md)
