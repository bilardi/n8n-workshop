# Email Management with n8n

---

## Prerequisites

- **For email classification (Workflow 3 and 4):** you need n8n running and Workflow 1 completed. If you haven't done it yet:
  1. Start from [intro/english.md](../intro/english.md) to create the Telegram bot and complete Workflow 1 (Part 4)
  2. Then follow the [Docker installation guide](../../scripts/docker_installer/english.md), or [server/english.md](../server/english.md) to access the shared server
- **For the `/status` command via bot (last section):** you also need Workflow 2 completed (Part 5 of the [Docker guide](../docker/english.md#part-5-workflow-2-polling-and-commands) or [server guide](../server/english.md)).

---

## Email Management with Tags and Priorities

### The idea

n8n reads incoming emails, analyzes them and automatically assigns **labels/folders** to help you understand what's urgent and what's not.

### Recommended labels

| Label | When to use |
|-----|---------------|
| `serve-risposta` | Emails requiring your reply |
| `da-pagare` | Invoices, payments, financial deadlines |
| `urgente` | Requires action by today |
| `progetto-alpha` | Emails related to project Alpha |
| `progetto-beta` | Emails related to project Beta |
| `newsletter` | Non-urgent communications, to read at leisure |
| `fornitori` | Emails from suppliers |
| `clienti` | Emails from clients |
| `da-archiviare` | Read, handled, go ahead and archive |

---

### Gmail credential configuration (OAuth2)

To connect Gmail to n8n you need to create OAuth2 credentials on Google Cloud Console. The procedure is free.

#### Step 1 - Create a Google Cloud project

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. At the top, click **Select a project** - **New project**
3. Project name: `n8n workshop`
4. Organisation: if you're using a corporate Google account (Workspace), select **No organisation** - this way the project is personal and doesn't require admin permissions
5. Click **Create**
6. Select the project you just created

#### Step 2 - Enable the Gmail API

1. In the left menu (three horizontal lines), go to **APIs & Services** - **Library**
2. Search for **"Gmail API"**
3. Click on **Gmail API** - **Enable**

#### Step 3 - Configure the OAuth consent screen

1. Go to **APIs & Services** - **OAuth consent screen**
2. If "Google Auth Platform" appears as not configured, click **Get started**
3. App name: `n8n workshop`
4. User support email: your email
5. Click **Next**
6. User type: select **External** - the "Internal" option is only for Google Workspace corporate accounts
7. Click **Next**
8. Contact information: your email
9. Click **Next** - accept the terms - **Create**

The app stays in "Testing" mode. Add yourself as a test user:

10. Go to **Audience** - **Test users** - **Add users**
11. Enter your Gmail email and click **Save**

#### Step 4 - Get the OAuth Redirect URL from n8n

1. In n8n, go to **Overview** (home page) - tab **Credentials** - **Create credential**
2. Search for **Gmail OAuth2 API** and select it
3. Copy the **OAuth Redirect URL** that appears at the top (e.g. `http://localhost:5678/rest/oauth2-credential/callback`)

> The localhost URL works: Google accepts it for local development.

#### Step 5 - Create the OAuth credentials

1. Go back to Google Cloud Console - menu (three lines) - **APIs & Services** - **Credentials**
2. Click **+ Create Credentials** - **OAuth client ID**
3. Application type: **Web application**
4. Name: `n8n workshop`
5. Leave "Authorized JavaScript origins" empty
6. In **Authorized redirect URIs**, click **+ Add URI** and paste the URL copied from Step 4
7. Click **Create**
8. Copy the **Client ID** and **Client Secret** that appear in the window

#### Step 6 - Connect n8n to Gmail

1. Go back to n8n on the Gmail OAuth2 API credential screen
2. Paste **Client ID** and **Client Secret**
3. Click **Sign in with Google**
4. Select your Gmail account
5. The warning "This app isn't verified" will appear - click **Advanced** - **Continue**
6. Select only the necessary permissions:
   - **Read, compose and send emails from your Gmail account**
   - **See and edit your email labels**
7. Click **Continue**
8. Save the credentials in n8n

> **Security:** credentials in self-hosted n8n are encrypted in the database. The main risk is someone accessing the server. Protect access with firewall and SSH key-only.

---

### Outlook/Microsoft 365 Credentials

Outlook requires an **Azure App Registration** for OAuth2 credentials. There are three paths:

**Option A - Corporate Microsoft 365 account:** if your company uses Microsoft 365, ask the IT admin to create an App Registration in Azure for n8n, or to give you permissions to do it in the Azure portal ([portal.azure.com](https://portal.azure.com) - Microsoft Entra ID - App registrations).

**Option B - M365 Developer Program** (free, with limitations): sign up at [developer.microsoft.com/en-us/microsoft-365/dev-program](https://developer.microsoft.com/en-us/microsoft-365/dev-program). Includes a sandbox with 25 E5 licenses for 90 days, but Microsoft only grants it to those who demonstrate development activity - it may not be available immediately.

**Option C - Free Azure account:** register at [azure.microsoft.com/free](https://azure.microsoft.com/free). Requires a credit card for identity verification, but charges nothing for the free tier. Gives you an Azure tenant to create App Registration.

> For the workshop, if you don't have a corporate account, option C is the most reliable. If you don't want to use a credit card, use Gmail (section above).

#### Option C - Detailed steps

##### Step 1 - Create a free Azure account

1. Go to [azure.microsoft.com/free](https://azure.microsoft.com/free)
2. Complete the 3 registration steps (requires credit card for verification, no charges)
3. At the end you arrive at [portal.azure.com](https://portal.azure.com)

##### Step 2 - Get the OAuth Redirect URL from n8n

1. In n8n, go to **Overview** - tab **Credentials** - **Create credential**
2. Search for **Microsoft Outlook OAuth2 API** and select it
3. Copy the **OAuth Redirect URL** that appears at the top

##### Step 3 - Create the App Registration

1. In the Azure portal, in the search bar at the top search for **"App registrations"**
2. Click **+ New registration**
3. Fill in:
   - Name: `n8n workshop`
   - Supported account types: **Any Entra ID Tenant + Personal Microsoft accounts**
   - Redirect URI: Platform **Web**, URL: paste the OAuth Redirect URL copied from n8n
4. Click **Register**

##### Step 4 - Copy the Client ID

On the App Registration Overview page, copy the **Application (client) ID**.

##### Step 5 - Create the Client Secret

1. In the left menu, under **Manage**, click **Certificates & secrets**
2. Click **+ New client secret**
3. Description: `n8n`
4. Expires: leave the default (180 days)
5. Click **Add**
6. **Copy the Value immediately** (not the Secret ID) - it's shown only once

##### Step 6 - Add API permissions

1. In the left menu, under **Manage**, click **API permissions**
2. Click **+ Add a permission** - **Microsoft Graph** - **Delegated permissions**
3. Search and select:
   - `Mail.Read`
   - `Mail.ReadWrite`
   - `offline_access`
4. Click **Add permissions**

##### Step 7 - Connect n8n to Outlook

1. Go back to n8n on the Microsoft Outlook OAuth2 API credential
2. Paste **Client ID** (Application client ID from Step 4)
3. Paste **Client Secret** (the Value from Step 5)
4. Leave **Use Shared Mailbox** disabled
5. Click **Connect to Microsoft Outlook**
6. Sign in with your Microsoft account and accept the permissions
7. Save the credential in n8n

---

### Workflow 3 - Gmail, email classification

#### Workflow structure

```
[Gmail Trigger: new unread emails]
  ├── [Basic LLM Chain: classify with AI]
  └── [Gmail: Get Many Labels]
         ↓
[Merge: Append]
  ↓
[Code: find label ID]
  ↓
[Gmail: Add Label]
```

> [Workflow diagram](../../mermaid/english/workflow3.mermaid) | [Sequence diagram](../../mermaid/english/workflow.email.mermaid)

#### Preparation: create the labels in Gmail

Before building the workflow, create the labels in Gmail:
1. Go to **Gmail** - **Settings** (gear icon) - **Labels** - **Create new label**
2. Create the labels you want to use, for example under a parent label `n8n`:
   - `n8n/newsletter`
   - `n8n/urgente`
   - `n8n/serve risposta`
   - `n8n/da pagare`
   - `n8n/da leggere`

> Label names can contain `/` to create sub-labels. Gmail shows them indented in the sidebar.

#### Node 1 - Gmail Trigger

- Credential: your Gmail OAuth2 credentials
- Events: **Message Received**
- Filters:
  - **Read Status**: Unread
  - **Label Names or IDs**: `INBOX`

#### Node 2 - Basic LLM Chain (AI classification)

The AI reads the email subject and preview and chooses the most appropriate category based on the descriptions you provide.

**Basic LLM Chain node configuration:**

- Source for Prompt (User Message): **Define below**
- Prompt (User Message):

```
Classify this email into ONE single category from those listed below. Reply with ONE SINGLE WORD: the category name. Nothing else.

Categories:
- n8n/newsletter: Periodic communications, promotions, non-urgent updates you can unsubscribe from
- n8n/urgente: Requires action by today or tomorrow
- n8n/serve risposta: Emails awaiting a direct reply from me
- n8n/da pagare: Invoices, payment requests, financial deadlines
- n8n/da leggere: Everything else: information, updates, notifications

Email:
{{ $json.Subject }} {{ $json.snippet }}
```

> Adapt the category names to the exact names of your Gmail labels (e.g. `n8n/newsletter`). `$json.Subject` (capital S) contains the subject, `$json.snippet` the body preview.

The output will be `{ "text": "n8n/newsletter" }` - the label name chosen by the AI.

#### Node 3 - AI Model (sub-node of Basic LLM Chain)

At the bottom of the Basic LLM Chain node, click the `+` under **Model** to connect an AI model.

**Option A - Google Gemini** (cloud, free with limits):
1. Go to [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
2. Click **Import projects**, select `n8n workshop`, click **Import**
3. Click **Create API key**, choose the `n8n workshop` project, click **Create key**
4. Copy the API key
5. In n8n: add **Google Gemini Chat Model** - create credential with the API key - model: `gemini-2.0-flash`

**Option B - Ollama** (local, free, unlimited):
1. Install [Ollama](https://ollama.com/download) and download a model (e.g. from terminal `ollama pull qwen2.5`)
2. In n8n: add **Ollama Chat Model** - create credential:
   - Base URL: `http://<DOCKER_BRIDGE_IP>:11434` (on Linux: `ip addr show docker0 | grep inet`, usually `172.17.0.1`)
   - API Key: any value (e.g. `ollama`)
3. Model: type `qwen2.5` in the field with **Expression** mode

> On Linux, if Ollama doesn't respond from the Docker container, make it listen on all interfaces: `OLLAMA_HOST=0.0.0.0 ollama serve`

#### Node 4 - Gmail, Get many labels

This node retrieves the complete list of Gmail labels with their respective IDs. Connect it directly to the **Gmail Trigger** (in parallel with Node 2).

- Credential: your Gmail OAuth2 credentials
- Resource: **Label**
- Operation: **Get Many**
- Return All: **enabled** (or Limit: `200`)

> Gmail Add Label requires the label ID (e.g. `Label_3102307117533849599`), not the name. This node provides the name - ID mapping.

#### Node 5 - Merge

- Mode: **Append**
- Number of Inputs: **2**

Connect the outputs of Node 2 (Basic LLM Chain) and Node 4 (Gmail Get Many Labels) to this node. The Code node will receive: item 0 = category chosen by the AI, item 1+ = the Gmail labels.

#### Node 6 - Code: find label ID

- Mode: **Run Once for All Items**

Choose the language you prefer
- Javascript:
```javascript
const items = $input.all();
const llmItem = items.find(i => i.json.text !== undefined);
const category = (llmItem ? llmItem.json.text : "").trim();
const labels = items.filter(i => i.json.name !== undefined);
const match = labels.find(l => l.json.name === category);
const labelId = match ? match.json.id : "";
const messageId = $('Gmail Trigger').first().json.id;

return [{ json: { labelId, messageId, category } }];
```
- Python:
```python
items = _input.all()
llm_item = next((i for i in items if "text" in i.json), None)
category = (llm_item.json["text"] if llm_item else "").strip()
labels = [i for i in items if "name" in i.json]
match = next((l for l in labels if l.json["name"] == category), None)
label_id = match.json["id"] if match else ""
message_id = _("Gmail Trigger").first().json["id"]

return [{"json": {"labelId": label_id, "messageId": message_id, "category": category}}]
```

> **Note:** the item order in the Merge is not guaranteed. The code looks for the AI item (has the `text` field), the labels (have the `name` field) and the original email (has `threadId`) regardless of position. Make sure that the category names in the prompt match **exactly** the Gmail label names (e.g. `n8n/da leggere` with the space, not `n8n/daleggere`).

> If the AI model returns a name that doesn't match any label, `labelId` will be empty and the Gmail node will throw an error - this is the expected behavior, so you notice that the categories in the prompt need fixing.

#### Node 7 - Gmail: Add Label

- Credential: your Gmail OAuth2 credentials
- Resource: **Message**
- Operation: **Add Label**
- Message ID: `{{ $json.messageId }}`
- Label Names or IDs: `{{ [$json.labelId] }}`

---

### Workflow 4 - Outlook, email classification

Outlook uses **folders** to organize emails instead of labels. The structure is similar to Workflow 3.

#### Workflow structure

```
[Outlook Trigger: new emails]
  ├── [Basic LLM Chain: classify with AI]
  └── [Outlook: Get Many Folders]
         ↓
[Merge: Append]
  ↓
[Code: find folder ID]
  ↓
[Outlook: Move Message]
```

> [Workflow diagram](../../mermaid/english/workflow4.mermaid)

#### Preparation: create the folders in Outlook

Before building the workflow, create the folders in Outlook:
1. Go to **Outlook** (web or desktop) - right-click on **Inbox** - **Create new folder**
2. Create the folders you want to use, for example:
   - `n8n-newsletter`
   - `n8n-urgente`
   - `n8n-serve-risposta`
   - `n8n-da-pagare`
   - `n8n-da-leggere`

#### Troubleshooting Microsoft Outlook nodes

If an Outlook node returns the error **"The DNS server returned an error, perhaps the server is offline"**, the n8n container may have a temporary DNS resolution issue towards `graph.microsoft.com`. Try:

1. **Re-execute the node** - it's often a transient error
2. **Reconnect the credential** - in the Outlook credential, click **Connect to Microsoft Outlook** again
3. **Restart n8n** - Docker: `docker compose down && docker compose up -d`; Server: ask the administrator to restart the n8n service

#### Node 1 - Microsoft Outlook Trigger

- Credential: your Microsoft Outlook OAuth2 credentials
- Events: **Message Received**

#### Node 2 - Basic LLM Chain (AI classification)

Same configuration as Workflow 3. Use the same AI model (Gemini or Ollama).

- Source for Prompt (User Message): **Define below**
- Prompt (User Message):

```
Classify this email into ONE single category from those listed below. Reply with ONE SINGLE WORD: the category name. Nothing else.

Categories:
- n8n-newsletter: Periodic communications, promotions, non-urgent updates you can unsubscribe from
- n8n-urgente: Requires action by today or tomorrow
- n8n-serve-risposta: Emails awaiting a direct reply from me
- n8n-da-pagare: Invoices, payment requests, financial deadlines
- n8n-da-leggere: Everything else: information, updates, notifications

Email:
{{ $json.subject }} {{ $json.bodyPreview }}
```

> Adapt the category names to the exact names of your Outlook folders. `$json.subject` (lowercase s, different from Gmail) contains the subject, `$json.bodyPreview` the body preview.

#### Node 3 - AI Model (sub-node of Basic LLM Chain)

Same configuration as Workflow 3 (Gemini or Ollama). If you've already created the credential, reuse it.

#### Node 4 - Microsoft Outlook, Get many folders

This node retrieves the complete list of Outlook folders with their respective IDs. Connect it directly to the **Outlook Trigger** (in parallel with Node 2).

- Credential: your Microsoft Outlook OAuth2 credentials
- Resource: **Folder**
- Operation: **Get Many**
- Return All: **enabled** (or Limit: `200`)

> Outlook Move Message requires the folder ID (e.g. `AAMkAGI2...`), not the name. This node provides the name - ID mapping.

#### Node 5 - Merge

- Mode: **Append**
- Number of Inputs: **2**

Connect the outputs of Node 2 (Basic LLM Chain) and Node 4 (Outlook Get Many Folders) to this node.

#### Node 6 - Code: find folder ID

- Mode: **Run Once for All Items**

Choose the language you prefer
- Javascript:
```javascript
const items = $input.all();
const llmItem = items.find(i => i.json.text !== undefined);
const category = (llmItem ? llmItem.json.text : "").trim();
const folders = items.filter(i => i.json.displayName !== undefined);
const match = folders.find(f => f.json.displayName === category);
const folderId = match ? match.json.id : "";
const messageId = $('Microsoft Outlook Trigger').first().json.id;

return [{ json: { folderId, messageId, category } }];
```
- Python:
```python
items = _input.all()
llm_item = next((i for i in items if "text" in i.json), None)
category = (llm_item.json["text"] if llm_item else "").strip()
folders = [i for i in items if "displayName" in i.json]
match = next((f for f in folders if f.json["displayName"] == category), None)
folder_id = match.json["id"] if match else ""
message_id = _("Microsoft Outlook Trigger").first().json["id"]

return [{"json": {"folderId": folder_id, "messageId": message_id, "category": category}}]
```

> If the AI model returns a name that doesn't match any folder, `folderId` will be empty and the Outlook node will throw an error.

#### Node 7 - Microsoft Outlook, Move a message

- Credential: your Microsoft Outlook OAuth2 credentials
- Resource: **Message**
- Operation: **Move**
- Message: By ID, `{{ $json.messageId }}`
- Parent Folder: By ID, `{{ $json.folderId }}`

---

### Telegram notification for urgent emails

Add these nodes after Workflow 3 (Gmail) or Workflow 4 (Outlook), after the Add Label / Move Message node. The workflow classifies the email as before, and additionally notifies you on Telegram if it's urgent.

```
... → [Node 7: Add Label / Move Message]
  ↓
[IF: category == "n8n/urgente" or "n8n-urgente"]
  ↓ (true)
[Telegram: Send Message]
```

#### Node 8 - IF

- Condition: `{{ $json.category }}` **equals** `n8n/urgente` (Gmail) or `n8n-urgente` (Outlook)

#### Node 9 - Telegram: Send Message

Copy an already configured Telegram node from a previous workflow. Just change the text:

- Text:

**Gmail:**
```
🚨 Urgent email
From: {{ $('Gmail Trigger').first().json.From }}
Subject: {{ $('Gmail Trigger').first().json.Subject }}
```

**Outlook:**
```
🚨 Urgent email
From: {{ $('Microsoft Outlook Trigger').first().json.from.emailAddress.name }}
Subject: {{ $('Microsoft Outlook Trigger').first().json.subject }}
```

---
