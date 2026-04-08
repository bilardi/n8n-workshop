# Gestione Email con n8n

---

## Prerequisiti

- **Per la classificazione email (Workflow 3 e 4):** hai bisogno di n8n attivo e del Workflow 1 completato. Se non lo hai ancora:
  1. Parti da [intro/italiano.md](../intro/italiano.md) per creare il bot Telegram e completare il Workflow 1 (Parte 4)
  2. Poi segui la [guida installazione Docker](../../scripts/docker_installer/italiano.md), oppure [server/italiano.md](../server/italiano.md) per accedere al server condiviso
- **Per il comando `/status` via bot (ultima sezione):** hai bisogno anche del Workflow 2 completato (Parte 5 della [guida Docker](../docker/italiano.md#parte-5-workflow-2-polling-e-comandi) o [guida server](../server/italiano.md)).

---

## Gestione Email con Tag e Priorità

### L'idea

n8n legge le email in arrivo, le analizza e assegna automaticamente **etichette/cartelle** per aiutarti a capire cosa è urgente e cosa no.

### Label consigliate

| Label | Quando usarla |
|-----|---------------|
| `serve-risposta` | Email che richiedono una tua risposta |
| `da-pagare` | Fatture, pagamenti, scadenze economiche |
| `urgente` | Richiede azione entro oggi |
| `progetto-alpha` | Email relative al progetto Alpha |
| `progetto-beta` | Email relative al progetto Beta |
| `newsletter` | Comunicazioni non urgenti, da leggere con calma |
| `fornitori` | Email da fornitori |
| `clienti` | Email da clienti |
| `da-archiviare` | Letto, gestito, archivia pure |

---

### Configurazione credenziali Gmail (OAuth2)

Per collegare Gmail a n8n serve creare delle credenziali OAuth2 su Google Cloud Console. La procedura è gratuita.

#### Passo 1 - Crea un progetto Google Cloud

1. Vai su [console.cloud.google.com](https://console.cloud.google.com)
2. In alto, clicca **Select a project** (Seleziona un progetto) → **New project** (Nuovo progetto)
3. Project name (Nome progetto): `n8n workshop`
4. Organisation (Organizzazione): se stai usando un account Google aziendale (Workspace), seleziona **No organisation** - così il progetto è personale e non richiede permessi dall'admin aziendale
5. Clicca **Create** (Crea)
6. Seleziona il progetto appena creato

#### Passo 2 - Abilita la Gmail API

1. Nel menu a sinistra (tre lineette orizzontali), vai su **APIs & Services** (API e servizi) → **Library** (Libreria)
2. Cerca **"Gmail API"**
3. Clicca su **Gmail API** → **Enable** (Abilita)

#### Passo 3 - Configura la OAuth consent screen

1. Vai su **APIs & Services** (API e servizi) → **OAuth consent screen** (Schermata di consenso OAuth)
2. Se appare "Google Auth Platform" non configurata, clicca **Inizia** (Get started)
3. Nome applicazione (App name): `n8n workshop`
4. Email per assistenza utenti (User support email): la tua email
5. Clicca **Avanti** (Next)
6. Pubblico (User type): seleziona **Esterno** (External) - l'opzione "Interno" è solo per account aziendali Google Workspace
7. Clicca **Avanti** (Next)
8. Dati di contatto (Contact information): la tua email
9. Clicca **Avanti** (Next) → accetta i termini → **Crea** (Create)

L'app resta in modalità "Testing". Aggiungi te stesso come utente di test:

10. Vai su **Pubblico** (Audience) → **Utenti di prova** (Test users) → **Add users** (Aggiungi utenti)
11. Inserisci la tua email Gmail e clicca **Salva** (Save)

#### Passo 4 - Prendi l'OAuth Redirect URL da n8n

1. In n8n, vai su **Overview** (pagina iniziale) → tab **Credentials** → **Create credential**
2. Cerca **Gmail OAuth2 API** e selezionala
3. Copia l'**OAuth Redirect URL** che appare in alto (es. `http://localhost:5678/rest/oauth2-credential/callback`)

> L'URL localhost funziona: Google lo accetta per lo sviluppo locale.

#### Passo 5 - Crea le credenziali OAuth

1. Torna su Google Cloud Console → menu (tre lineette) → **APIs & Services** (API e servizi) → **Credentials** (Credenziali)
2. Clicca **+ Create Credentials** (Crea credenziali) → **OAuth client ID** (ID client OAuth)
3. Application type (Tipo di applicazione): **Web application** (Applicazione web)
4. Name (Nome): `n8n workshop`
5. Lascia vuoto "Authorized JavaScript origins" (Origini JS autorizzate)
6. In **Authorized redirect URIs** (URI di reindirizzamento autorizzati), clicca **+ Add URI** (Aggiungi URI) e incolla l'URL copiato dal Passo 4
7. Clicca **Create** (Crea)
8. Copia **Client ID** e **Client Secret** che appaiono nella finestra

#### Passo 6 - Collega n8n a Gmail

1. Torna in n8n sulla schermata della credenziale Gmail OAuth2 API
2. Incolla **Client ID** e **Client Secret**
3. Clicca **Sign in with Google** (Connetti con Google)
4. Seleziona il tuo account Gmail
5. Apparirà l'avviso "Questa app non è verificata" - clicca **Avanzate** (Advanced) → **Continue** (Continua)
6. Seleziona solo i permessi necessari:
   - **Read, compose and send emails from your Gmail account**
   - **See and edit your email labels**
7. Clicca **Continue** (Continua)
8. Salva le credenziali in n8n

> **Sicurezza:** le credenziali in n8n self-hosted sono cifrate nel database. Il rischio principale è che qualcuno acceda al server. Proteggi l'accesso con firewall e SSH solo con chiave.

---

### Credenziali Outlook/Microsoft 365

Outlook richiede una **Azure App Registration** per le credenziali OAuth2. Ci sono tre strade:

**Opzione A - Account aziendale Microsoft 365:** se la tua azienda usa Microsoft 365, chiedi all'admin IT di creare un'App Registration in Azure per n8n, oppure di darti i permessi per farlo nel portale Azure ([portal.azure.com](https://portal.azure.com) → Microsoft Entra ID → App registrations).

**Opzione B - M365 Developer Program** (gratuito, con limitazioni): iscriviti su [developer.microsoft.com/en-us/microsoft-365/dev-program](https://developer.microsoft.com/en-us/microsoft-365/dev-program). Include un sandbox con 25 licenze E5 per 90 giorni, ma Microsoft lo concede solo a chi dimostra attività di sviluppo - potrebbe non essere disponibile subito.

**Opzione C - Account Azure gratuito:** registrati su [azure.microsoft.com/free](https://azure.microsoft.com/free). Richiede una carta di credito per la verifica dell'identità, ma non addebita nulla per il tier gratuito. Ti dà un tenant Azure con cui creare App Registration.

> Per il workshop, se non hai un account aziendale, l'opzione C è la più affidabile. Se non vuoi usare la carta di credito, usa Gmail (sezione sopra).

#### Opzione C - Passaggi dettagliati

##### Passo 1 - Crea un account Azure gratuito

1. Vai su [azure.microsoft.com/free](https://azure.microsoft.com/free)
2. Completa i 3 step di registrazione (richiede carta di credito per verifica, nessun addebito)
3. Al termine arrivi su [portal.azure.com](https://portal.azure.com)

##### Passo 2 - Prendi l'OAuth Redirect URL da n8n

1. In n8n, vai su **Overview** → tab **Credentials** → **Create credential**
2. Cerca **Microsoft Outlook OAuth2 API** e selezionala
3. Copia l'**OAuth Redirect URL** che appare in alto

##### Passo 3 - Crea l'App Registration

1. Nel portale Azure, nella barra di ricerca in alto cerca **"App registrations"**
2. Clicca **+ New registration**
3. Compila:
   - Name: `n8n workshop`
   - Supported account types: **Any Entra ID Tenant + Personal Microsoft accounts**
   - Redirect URI: Platform **Web**, URL: incolla l'OAuth Redirect URL copiato da n8n
4. Clicca **Register**

##### Passo 4 - Copia il Client ID

Nella pagina Overview dell'App Registration, copia l'**Application (client) ID**.

##### Passo 5 - Crea il Client Secret

1. Nel menu a sinistra, sotto **Manage**, clicca **Certificates & secrets**
2. Clicca **+ New client secret**
3. Description: `n8n`
4. Expires: lascia il default (180 days)
5. Clicca **Add**
6. **Copia subito il Value** (non il Secret ID) - viene mostrato solo una volta

##### Passo 6 - Aggiungi i permessi API

1. Nel menu a sinistra, sotto **Manage**, clicca **API permissions**
2. Clicca **+ Add a permission** → **Microsoft Graph** → **Delegated permissions**
3. Cerca e seleziona:
   - `Mail.Read`
   - `Mail.ReadWrite`
   - `offline_access`
4. Clicca **Add permissions**

##### Passo 7 - Collega n8n a Outlook

1. Torna in n8n sulla credenziale Microsoft Outlook OAuth2 API
2. Incolla **Client ID** (Application client ID dal Passo 4)
3. Incolla **Client Secret** (il Value dal Passo 5)
4. Lascia **Use Shared Mailbox** disattivato
5. Clicca **Connect to Microsoft Outlook**
6. Accedi con il tuo account Microsoft e accetta i permessi
7. Salva la credenziale in n8n

---

### Workflow 3 - Gmail, classificazione email

#### Struttura del workflow

```
[Gmail Trigger: nuove email non lette]
  ├── [Basic LLM Chain: classifica con AI]
  └── [Gmail: Get Many Labels]
         ↓
[Merge: Append]
  ↓
[Code: trova label ID]
  ↓
[Gmail: Add Label]
```

> [Diagramma del workflow](../../mermaid/italiano/workflow3.mermaid) | [Diagramma di sequenza](../../mermaid/italiano/workflow.email.mermaid)

#### Preparazione: crea le label in Gmail

Prima di costruire il workflow, crea le label in Gmail:
1. Vai su **Gmail** → **Impostazioni** (ingranaggio) → **Etichette** (Labels) → **Crea nuova etichetta** (Create new label)
2. Crea le label che vuoi usare, ad esempio sotto una label padre `n8n`:
   - `n8n/newsletter`
   - `n8n/urgente`
   - `n8n/serve risposta`
   - `n8n/da pagare`
   - `n8n/da leggere`

> I nomi delle label possono contenere `/` per creare sotto-label. Gmail li mostra indentati nella barra laterale.

#### Nodo 1 - Gmail Trigger

- Credential: le tue credenziali Gmail OAuth2
- Events: **Message Received**
- Filters:
  - **Read Status**: Unread
  - **Label Names or IDs**: `INBOX`

#### Nodo 2 - Basic LLM Chain (classificazione AI)

L'AI legge oggetto e anteprima dell'email e sceglie la categoria più appropriata in base alle descrizioni che fornisci.

**Configurazione del nodo Basic LLM Chain:**

- Source for Prompt (User Message): **Define below**
- Prompt (User Message):

```
Classifica questa email in UNA sola categoria tra quelle elencate sotto. Rispondi con UNA SOLA PAROLA: il nome della categoria. Nient'altro.

Categorie:
- n8n/newsletter: Comunicazioni periodiche, promozioni, aggiornamenti non urgenti da cui ci si può disiscrivere
- n8n/urgente: Richiede azione entro oggi o domani
- n8n/serve risposta: Email che attendono una risposta diretta da parte mia
- n8n/da pagare: Fatture, richieste di pagamento, scadenze economiche
- n8n/da leggere: Tutto il resto: informazioni, aggiornamenti, notifiche

Email:
{{ $json.Subject }} {{ $json.snippet }}
```

> Adatta i nomi delle categorie ai nomi esatti delle tue label Gmail (es. `n8n/newsletter`). `$json.Subject` (S maiuscola) contiene l'oggetto, `$json.snippet` l'anteprima del corpo.

L'output sarà `{ "text": "n8n/newsletter" }` - il nome della label scelto dall'AI.

#### Nodo 3 - Model AI (sotto-nodo del Basic LLM Chain)

In basso nel nodo Basic LLM Chain, clicca sul `+` sotto **Model** per collegare un modello AI.

**Opzione A - Google Gemini** (cloud, gratuito con limiti):
1. Vai su [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
2. Clicca **Import projects**, seleziona `n8n workshop`, clicca **Import**
3. Clicca **Create API key**, scegli il progetto `n8n workshop`, clicca **Create key**
4. Copia la API key
5. In n8n: aggiungi **Google Gemini Chat Model** → crea credenziale con la API key → modello: `gemini-2.0-flash`

**Opzione B - Ollama** (locale, gratuito, senza limiti):
1. Installa [Ollama](https://ollama.com/download) e scarica un modello (es. da terminale `ollama pull qwen2.5`)
2. In n8n: aggiungi **Ollama Chat Model** → crea credenziale:
   - Base URL: `http://<IP_BRIDGE_DOCKER>:11434` (su Linux: `ip addr show docker0 | grep inet`, di solito `172.17.0.1`)
   - API Key: qualsiasi valore (es. `ollama`)
3. Model: scrivi `qwen2.5` nel campo con modalità **Expression**

> Su Linux, se Ollama non risponde dal container Docker, fai ascoltare su tutte le interfacce: `OLLAMA_HOST=0.0.0.0 ollama serve`

#### Nodo 4 - Gmail, Get many labels

Questo nodo recupera la lista completa delle label Gmail con i rispettivi ID. Collegalo direttamente al **Gmail Trigger** (in parallelo al Nodo 2).

- Credential: le tue credenziali Gmail OAuth2
- Resource: **Label**
- Operation: **Get Many**
- Return All: **attivo** (o Limit: `200`)

> Gmail Add Label richiede l'ID della label (es. `Label_3102307117533849599`), non il nome. Questo nodo fornisce la mappa nome → ID.

#### Nodo 5 - Merge

- Mode: **Append**
- Number of Inputs: **2**

Collega le uscite di Nodo 2 (Basic LLM Chain) e Nodo 4 (Gmail Get Many Labels) a questo nodo. Il Code node riceverà: item 0 = categoria scelta dall'AI, item 1+ = le label Gmail.

#### Nodo 6 - Code: trova label ID

- Mode: **Run Once for All Items**

Scegli il linguaggio che preferisci
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

> **Nota:** l'ordine degli item nel Merge non è garantito. Il codice cerca l'item dell'AI (ha il campo `text`), le label (hanno il campo `name`) e l'email originale (ha `threadId`) indipendentemente dalla posizione. Assicurati che i nomi delle categorie nel prompt corrispondano **esattamente** ai nomi delle label Gmail (es. `n8n/da leggere` con lo spazio, non `n8n/daleggere`).

> Se il modello AI restituisce un nome che non corrisponde a nessuna label, `labelId` sarà vuoto e il nodo Gmail darà errore - è il comportamento atteso, così ti accorgi che serve correggere le categorie nel prompt.

#### Nodo 7 - Gmail: Add Label

- Credential: le tue credenziali Gmail OAuth2
- Resource: **Message**
- Operation: **Add Label**
- Message ID: `{{ $json.messageId }}`
- Label Names or IDs: `{{ [$json.labelId] }}`

---

### Workflow 4 - Outlook, classificazione email

Outlook usa le **cartelle** per organizzare le email al posto delle label. La struttura è simile al Workflow 3.

#### Struttura del workflow

```
[Outlook Trigger: nuove email]
  ├── [Basic LLM Chain: classifica con AI]
  └── [Outlook: Get Many Folders]
         ↓
[Merge: Append]
  ↓
[Code: trova folder ID]
  ↓
[Outlook: Move Message]
```

> [Diagramma del workflow](../../mermaid/italiano/workflow4.mermaid)

#### Preparazione: crea le cartelle in Outlook

Prima di costruire il workflow, crea le cartelle in Outlook:
1. Vai su **Outlook** (web o desktop) → clic destro su **Inbox** → **Create new folder** (Crea nuova cartella)
2. Crea le cartelle che vuoi usare, ad esempio:
   - `n8n-newsletter`
   - `n8n-urgente`
   - `n8n-serve-risposta`
   - `n8n-da-pagare`
   - `n8n-da-leggere`

#### Troubleshooting nodi Microsoft Outlook

Se un nodo Outlook restituisce l'errore **"The DNS server returned an error, perhaps the server is offline"**, il container n8n potrebbe avere un problema temporaneo di risoluzione DNS verso `graph.microsoft.com`. Prova a:

1. **Rieseguire il nodo** - spesso è un errore transitorio
2. **Riconnettere la credenziale** - nella credenziale Outlook, clicca di nuovo **Connect to Microsoft Outlook**
3. **Riavviare n8n** - Docker: `docker compose down && docker compose up -d`; Server: chiedere all'amministratore di riavviare il servizio n8n

#### Nodo 1 - Microsoft Outlook Trigger

- Credential: le tue credenziali Microsoft Outlook OAuth2
- Events: **Message Received**

#### Nodo 2 - Basic LLM Chain (classificazione AI)

Stessa configurazione del Workflow 3. Usa lo stesso modello AI (Gemini o Ollama).

- Source for Prompt (User Message): **Define below**
- Prompt (User Message):

```
Classifica questa email in UNA sola categoria tra quelle elencate sotto. Rispondi con UNA SOLA PAROLA: il nome della categoria. Nient'altro.

Categorie:
- n8n-newsletter: Comunicazioni periodiche, promozioni, aggiornamenti non urgenti da cui ci si può disiscrivere
- n8n-urgente: Richiede azione entro oggi o domani
- n8n-serve-risposta: Email che attendono una risposta diretta da parte mia
- n8n-da-pagare: Fatture, richieste di pagamento, scadenze economiche
- n8n-da-leggere: Tutto il resto: informazioni, aggiornamenti, notifiche

Email:
{{ $json.subject }} {{ $json.bodyPreview }}
```

> Adatta i nomi delle categorie ai nomi esatti delle tue cartelle Outlook. `$json.subject` (s minuscola, diverso da Gmail) contiene l'oggetto, `$json.bodyPreview` l'anteprima del corpo.

#### Nodo 3 - Model AI (sotto-nodo del Basic LLM Chain)

Stessa configurazione del Workflow 3 (Gemini o Ollama). Se hai già creato la credenziale, riutilizzala.

#### Nodo 4 - Microsoft Outlook, Get many folders

Questo nodo recupera la lista completa delle cartelle Outlook con i rispettivi ID. Collegalo direttamente all'**Outlook Trigger** (in parallelo al Nodo 2).

- Credential: le tue credenziali Microsoft Outlook OAuth2
- Resource: **Folder**
- Operation: **Get Many**
- Return All: **attivo** (o Limit: `200`)

> Outlook Move Message richiede l'ID della cartella (es. `AAMkAGI2...`), non il nome. Questo nodo fornisce la mappa nome → ID.

#### Nodo 5 - Merge

- Mode: **Append**
- Number of Inputs: **2**

Collega le uscite di Nodo 2 (Basic LLM Chain) e Nodo 4 (Outlook Get Many Folders) a questo nodo.

#### Nodo 6 - Code: trova folder ID

- Mode: **Run Once for All Items**

Scegli il linguaggio che preferisci
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

> Se il modello AI restituisce un nome che non corrisponde a nessuna cartella, `folderId` sarà vuoto e il nodo Outlook darà errore.

#### Nodo 7 - Microsoft Outlook, Move a message

- Credential: le tue credenziali Microsoft Outlook OAuth2
- Resource: **Message**
- Operation: **Move**
- Message: By ID, `{{ $json.messageId }}`
- Parent Folder: By ID, `{{ $json.folderId }}`

---

### Notifica Telegram per email urgenti

Aggiungi questi nodi in coda al Workflow 3 (Gmail) o al Workflow 4 (Outlook), dopo il nodo Add Label / Move Message. Il workflow classifica l'email come prima, e in più ti avvisa su Telegram se è urgente.

```
... → [Nodo 7: Add Label / Move Message]
  ↓
[IF: category == "n8n/urgente" o "n8n-urgente"]
  ↓ (true)
[Telegram: Send Message]
```

#### Nodo 8 - IF

- Condition: `{{ $json.category }}` **equals** `n8n/urgente` (Gmail) oppure `n8n-urgente` (Outlook)

#### Nodo 9 - Telegram: Send Message

Copia un nodo Telegram già configurato da un workflow precedente. Cambia solo il testo:

- Text:

**Gmail:**
```
🚨 Email urgente
Da: {{ $('Gmail Trigger').first().json.From }}
Oggetto: {{ $('Gmail Trigger').first().json.Subject }}
```

**Outlook:**
```
🚨 Email urgente
Da: {{ $('Microsoft Outlook Trigger').first().json.from.emailAddress.name }}
Oggetto: {{ $('Microsoft Outlook Trigger').first().json.subject }}
```

---
