# Introductory Guide to n8n
## Workflow Automation for Everyone

---

## Table of Contents

1. [What is n8n?](#what-is-n8n)
2. [Key concepts with practical examples](#key-concepts)
3. [Shared server vs Cloud: what's best?](#server-vs-cloud)
4. [Telegram bot for notifications](#telegram-bot-for-notifications)
   - Part 1: Creating a bot with BotFather
   - Part 2: Configuring credentials and token security
   - Part 3: Finding your Chat ID
   - Part 4: Workflow 1 - count files with manual trigger
5. [Summary: workflow architecture](#summary-workflow-architecture)
6. [Official resources](#official-resources)

---

## What is n8n?

n8n (pronounced "n-eight-n" or "nodemation") is an open-source tool for **automating repetitive tasks** by connecting different applications and services together, without writing code.

Imagine having an **invisible secretary** that:
- Every time you receive an important email, moves it to the right folder automatically
- Organizes downloaded files into the right folder without you doing anything
- Sends you a message on Telegram when something needs your attention

That's n8n.

---

## Key Concepts

### How n8n works: the assembly line metaphor

Imagine an **assembly line** in a factory:
- Each station performs a specific operation
- The product moves from station to station
- At the end, the finished product comes out

In n8n:
- Each **node** (station) performs an operation (read email, send message, write file)
- **Data** flows from one node to the next
- The final result is the completed automation

This sequence of connected nodes is called a **workflow** - the word you'll find everywhere in n8n.

### Main components

#### 1. Trigger (the switch)
It's the **starting point** of the workflow. It determines *when* to start the automation.

"Example" - n8n node name:
- "I start it manually" - Manual Trigger
- "Every morning at 9:00" - Schedule Trigger
- "When a new email arrives" - Email Trigger
- "When I receive a Telegram message" - Telegram Trigger

#### 2. Nodes (the operations)
Each node is an action. There are hundreds of built-in nodes for:
- Gmail, Outlook, Slack, Telegram
- Google Sheets, Excel, Airtable
- Dropbox, Google Drive, OneDrive
- Google Analytics, Salesforce, Power BI
- Asana, Confluence, Jira, Notion, Trello
- And much more

#### 3. Connections (the wires)
The arrows connecting the nodes. Data flows along these "wires".

---

### Practical example 1: "Notify me on Telegram when an important email arrives"

Scenario: you have an important supplier. You want to receive a Telegram message every time they send you an email.

```
[Email Trigger] → [IF: sender contains "mysupplier.com"] → [Telegram: send message]
```

**How it works step by step:**
1. The **Email Trigger** detects new messages
2. The **IF** node checks whether the sender of the new message is your supplier
3. If YES - the **Telegram node** sends you "You have an email from John Smith: [subject]"
4. If NO - nothing happens

---

### Practical example 2: "Automatically save Excel spreadsheet data to Google Sheets"

Scenario: every Friday you want to export data from a shared spreadsheet.

```
[Schedule: Friday at 17:00] → [Read Excel file] → [Write to Google Sheets]
```

**How it works step by step:**
1. Every Friday at 17:00 the **Schedule** starts the workflow automatically
2. The **Read Excel file** node opens the file and extracts data row by row
3. The **Write to Google Sheets** node updates the sheet with the received data

---

### How to create your first workflow

1. Open n8n in your browser
2. Click **"Start from scratch"**
3. Click the **+** to add the first node
4. Search for the trigger type (e.g. "Manual" to test manually)
5. Add more nodes by clicking the **+** to the right of each node
6. Connect nodes by dragging the arrows
7. Click **"Execute Workflow"** to test
8. Click **"Save"** and then activate the workflow with the toggle at the top

For concrete examples and step-by-step configurations, see the following sections starting from [Telegram Bot](#telegram-bot-for-notifications).

---

### Code in workflows: JavaScript and Python

In n8n you can add custom logic through the **Code node**. It's important to understand what you can use and why.

**JavaScript is n8n's native language.** The Code node runs directly on Node.js - the same engine n8n is built on - and has full access to all workflow variables (`$input`, `$json`, `$node`, etc.). For any logic *within* a workflow (classifying an email, building a message, deciding where to move a file) the JavaScript Code node is the right choice.

**Python in the Code node - native version.** Since version 1.111.0 (stable in n8n v2), n8n runs Python through native task runners. The available variables are only `_items` (mode "Run Once for All Items") and `_item` (mode "Run Once for Each Item") - JavaScript variables (`$input`, `$json` etc.) are not available. Fields are accessed with bracket notation: `item["json"]["field"]`. On a self-hosted installation you can import standard library modules and third-party packages, if the `n8nio/runners` image includes them and they are in the allowlist. On n8n Cloud it's not yet possible to import libraries, so only logic without importing even standard libraries is allowed, as was permitted in the old Pyodide mode which is now legacy.

**Python is also used as an external script.** If you need Python with its libraries, its files, its tools - you write it as a standalone `.py` script on the server and call it from the workflow via the **Execute Command** node, which runs the command as you would from the terminal. n8n collects the output (JSON, text) and passes it to the following nodes. This is the case for the `smistamento.py` script in this guide.

In summary: **JavaScript for logic inside n8n, native Python for simple calculations without libraries (or with libraries on self-hosted), Python (external) for specialized processing outside n8n.**

---

## Server vs Cloud

### Scenario: all colleagues use n8n

When an entire organization wants to use n8n, there are two paths:

#### Option A: Shared server (self-hosted)

A single server (physical or virtual) runs n8n for the whole company.

**Advantages:**
- Fixed cost (VPS server from ~EUR 5-15/month on Hetzner, OVH, etc.)
- Data stays **within your company** (important for GDPR)
- No execution limits
- Full customization
- Colleagues all access the same interface

**Disadvantages:**
- Someone must manage updates and backups
- If the server goes down, n8n doesn't work
- Requires a minimum of technical expertise for maintenance

**Real costs:**
- Basic VPS (2 CPU, 4GB RAM): ~EUR 6-10/month - sufficient for small teams
- Medium VPS (4 CPU, 8GB RAM): ~EUR 15-25/month - teams of 10-20 people

#### Option B: n8n Cloud

You pay n8n directly to use their managed service.

**Advantages:**
- Zero maintenance
- Automatic updates
- Official support

**Disadvantages:**
- Variable costs based on executions (~$20/month per workspace, Starter plan with 2,500 executions)
- Your data is on third-party servers
- Limits on the number of workflow executions

**Conclusion for small/medium teams:** A shared VPS is almost always the best choice. It costs little, the data stays in-house, and a bit of monthly maintenance is enough.

---

### User management and credentials on a shared server

n8n supports **roles and permissions**:
- **Owner**: the administrator, sees everything
- **Admin**: can manage workflows and users
- **Member**: can create and use workflows

**Golden rule for credentials:** Each user or workflow should have its own credentials, not share them all under a single account. If a credential is compromised, the damage is limited.

### Choose your path

There are two paths: install n8n [locally via Docker](../../scripts/docker_installer/english.md), or access an already configured [shared server](../server/english.md). Both follow the same Parts 1-4 of this guide - you'll find links to the specific guides after Part 4.

If you just want to try n8n quickly without Docker, you can install it with **npm** (requires Node.js 18+):

```bash
npm install n8n -g
n8n start
```

> For continuous and shared use, Docker is much more practical: see the [Docker guide](../../scripts/docker_installer/english.md).

---

## Telegram Bot for Notifications

### Part 1: Creating the Telegram Bot

1. Open Telegram and search for **@BotFather** or use [this link](https://web.telegram.org/k/#@BotFather)
2. Send the message `/newbot`
3. Choose a name (e.g. "My n8n Bot")
4. Choose a username (must end in `bot`, e.g. `my_n8n_bot`)
5. BotFather will give you a **token** like: `123456789:Aa0Bb1Cc2Dd3Ee4Ff5Gg6Hh7Ii8Jj9Kk0Ll`

> **WARNING:** This token is like your bot's password. Anyone who has it can control the bot. Never share it.

---

### Configuring Telegram Credentials

**NEVER** insert the token directly in the workflow as text. Credentials are configured from the Telegram node or from the dedicated Credentials section.

**IF** you have never opened n8n, in the **Overview** section you will find **Start from scratch**.

1. Open the browser on n8n (locally: `http://localhost:5678`, or the shared server link)
2. Click on **Start from scratch**
3. Click on the +
4. Type "telegram" in the search bar at the top right
5. Choose the **On message** node
6. In the selected node, click the **"Credential to connect with"** field
7. Click **"Create new credential"**
8. Paste the token in the **"Access Token"** field
9. Click **Save**

The token is now **encrypted** in the n8n database. You can reuse the same credential in all Telegram nodes of the workflow.

Clicking the x at the top right and going back to Overview, a **Credentials** section now appears, where you'll find the credentials you just saved.

---

### Telegram bot security: summary

| What to do | Why |
|-----------|--------|
| Save the token in `.env` as `TELEGRAM_TOKEN` | Usable via `{{ $env.TELEGRAM_TOKEN }}` in the HTTP Request node, without exposing it in the workflow (Docker only - see [Docker guide](../docker/english.md)) |
| Save the token in n8n Credentials | The token is encrypted, not visible in the workflow in Telegram nodes |
| Don't share the token via email/chat | Anyone who has it controls the bot |
| Use one bot per environment (test / production) | If the test token is compromised, production is safe |

---

### Part 3: Finding your Chat ID

To send messages, n8n needs your **Chat ID** (your unique identifier on Telegram).

**Simple method: @userinfobot**

1. Open Telegram and search for **@userinfobot** or use [this link](https://web.telegram.org/k/#@userinfobot)
2. Send the message `/start`
3. The bot replies with your **User ID**: that's your Chat ID in private chats

**Alternative method: getUpdates API**

1. Send any message to your bot
2. Open in the browser: `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates`
3. Look for the `"id"` field inside `"chat"` - that's your Chat ID

> **Note:** getUpdates may return an empty array if you haven't sent recent messages to the bot. In that case use @userinfobot.

---

### Part 4: Workflow 1 - count files with manual trigger

Before building the full bot, try this minimal workflow to verify everything works: it counts the `.py` files in the scripts folder and sends the result on Telegram.

```
[Node A: Manual Trigger]
  ↓
[Node B: Read Files from Disk]
  ↓
[Node C: Code node: count files]
  ↓
[Node D: Telegram: send the result]
```

> [Workflow diagram](../../mermaid/english/workflow1.mermaid)

**Node A - Manual Trigger:** no configuration needed.

**Node B - Read Files from Disk:**
- File Selector: `/home/node/.n8n-files/scripts/workflow5/*.py`

> The path works because n8n mounts the `scripts/` folder - on Docker through the volumes in `docker-compose.yml`, on the shared server it's already configured.

**Node C - Code, count files:**
- Mode: **Run Once for All Items**

Choose the language you prefer
- Javascript:
```javascript
return [{ json: { count: $input.all().length } }];
```
- Python:
```python
return [{"json": {"count": len(_items)}}]
```

**Node D - Telegram, Send a text message:**
- Credential: see [Configuring Telegram Credentials](#configuring-telegram-credentials)
- Operation: Send Message
- Chat ID: your Chat ID (found in Part 3)
- Text: `Found {{ $json.count }} .py files`

Click **"Execute workflow"** - if the message arrives on Telegram, everything works.

### Before continuing: save and create a new workflow

1. **Save** the current workflow with the name **Workflow 1** (or **W1**): click the workflow name at the top and rename it
2. **Create a new empty workflow**: top left menu - **New workflow**
3. Rename it **Workflow 2** (or **W2**)

Part 5 will build Workflow 2 from scratch. Nodes B, C and D from Workflow 1 will be reused: copy them (select them - Ctrl+C) and paste them (Ctrl+V) into the new workflow.

> **Tip:** every time you need a "Send a text message" Telegram node in a new workflow, copy an already configured Telegram node from an existing workflow and paste it: credential and Chat ID are already set, you just need to change the text.

---

Now continue with **Part 5** in your guide: [Docker guide ->](../docker/english.md#part-5-workflow-2-polling-and-commands) | [server guide ->](../server/english.md#part-5-full-workflow-with-webhook)

---

## Summary: workflow architecture

```
n8n self-hosted (Docker)
│
├── Workflow 1: Telegram Bot - Part 4 (manual test)
│   └── Node A (Manual Trigger) → Node B → Node C → Node D
│
├── Workflow 2: Telegram Bot - Part 5 (full polling)
│   ├── Node 1 (Schedule) → Node 2 (getUpdates) → Node 3 (filter) → Node 4 (Switch)
│   ├── /status branch:    Node B → Node C → Node D
│   └── fallback branch:   Node 5 (IF regex) → Node 6 (Telegram)
│
├── Workflow 3: Gmail Email Classification
│   └── Gmail Trigger → Text Classifier (AI) → Gmail Add Label
│
├── Workflow 4: Outlook Email Classification
│   └── Outlook Trigger → Text Classifier (AI) → Outlook Move Message
│
├── Workflow 5: Workspace Scan Start
│   └── Manual Trigger → Execute Command (nohup process.py &) → Telegram "started"
│       process.py runs autonomously, at the end notifies Telegram directly
│
├── Workflow 6: Scan Monitoring (same structure as Workflow 2)
│   ├── Node 1 (Schedule) → Node 2 (getUpdates) → Node 3 (filter) → Node 4 (Switch)
│   ├── /status branch:    Execute Command (monitor.py) → Code (message) → Node D
│   └── fallback branch:   Node 5 (IF regex) → Node 6 (Telegram)
│
├── Workflow 7: RSS Fetch
│   └── Schedule → RSS Feed Read → Code (filter) → Write File → Telegram
│
└── Workflow 8: Monitor W7 (same structure as Workflow 6)
    ├── /status branch:    HTTP Request (n8n API) → Read File → Code → Telegram
    └── fallback branch:   Node 5 (IF regex) → Node 6 (Telegram)
```

> [Full architecture diagram](../../mermaid/english/workflow.basic.mermaid)

**Where to find the details:**
- Workflow 1-2: [intro](english.md#telegram-bot-for-notifications) (Parts 1-4) + [Docker guide](../docker/english.md#part-5-full-workflow-with-polling-and-commands) or [server guide](../server/english.md)
- Workflow 3-4: [email guide](../email/english.md)
- Workflow 5-6: [Docker guide](../docker/english.md#process-monitoring-with-python)
- Workflow 7-8: [RSS guide](../rss/english.md)

---

## Official Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Docker Installation](https://docs.n8n.io/hosting/installation/docker/)
- [Telegram Node](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.telegram/)
- [Telegram Credentials](https://docs.n8n.io/integrations/builtin/credentials/telegram/)
- [Code node (Python/JS)](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.code/)
- [Local File Trigger](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.localfiletrigger/)
- [Template workflow email Gmail](https://n8n.io/workflows/2740-basic-automatic-gmail-email-labelling-with-openai-and-gmail-api/)
- [Template workflow email Outlook](https://n8n.io/workflows/8336-automatic-email-categorization-and-organization-with-outlook-and-gpt-4o/)
- [Environment variables security](https://docs.n8n.io/hosting/configuration/environment-variables/security/)
- [External secrets (Vault, AWS Secrets Manager)](https://docs.n8n.io/external-secrets/)
- [n8n Cloud pricing](https://n8n.io/pricing/)
- [Self-hosted vs Cloud (comparison)](https://docs.n8n.io/choose-n8n/)
