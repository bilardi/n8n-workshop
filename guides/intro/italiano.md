# Guida introduttiva a n8n
## Automazione dei flussi di lavoro per tutti

---

## Indice

1. [Cos'è n8n?](#cosè-n8n)
2. [Concetti chiave con esempi pratici](#concetti-chiave)
3. [Server condiviso vs Cloud: cosa conviene?](#server-vs-cloud)
4. [Bot Telegram per notifiche](#bot-telegram-per-notifiche)
   - Parte 1: Creazione bot con BotFather
   - Parte 2: Configurazione credenziali e sicurezza del token
   - Parte 3: Trovare il Chat ID
   - Parte 4: Workflow 1 - conta i file con trigger manuale
5. [Riepilogo: architettura dei workflow](#riepilogo-architettura-dei-workflow)
6. [Risorse ufficiali](#risorse-ufficiali)

---

## Cos'è n8n?

n8n (pronunciato "n-eight-n" o "nodemation") è uno strumento open-source per **automatizzare compiti ripetitivi** collegando applicazioni e servizi diversi tra loro, senza dover scrivere codice.

Immagina di avere una **segreteria invisibile** che:
- Ogni volta che ricevi una email importante, la sposta nella cartella giusta automaticamente
- Organizza i file scaricati nella cartella giusta senza che tu faccia nulla
- Ti manda un messaggio su Telegram quando qualcosa richiede la tua attenzione

Tutto questo è n8n.

---

## Concetti Chiave

### Come funziona n8n: la metafora della catena di montaggio

Immagina una **catena di montaggio** in una fabbrica:
- Ogni stazione fa un'operazione specifica
- Il prodotto passa da stazione a stazione
- Alla fine esce il prodotto finito

In n8n:
- Ogni **nodo** (stazione) fa un'operazione (leggi email, manda messaggio, scrivi file)
- I **dati** scorrono da un nodo all'altro
- Il risultato finale è l'automazione completata

Questa sequenza di nodi collegati si chiama **workflow** - la parola che troverai ovunque in n8n.

### I componenti principali

#### 1. Trigger (l'interruttore)
È il **punto di partenza** del workflow. Determina *quando* far partire l'automazione.

"Esempio" → nome del nodo n8n:
- "Faccio partire manualmente" → Manual Trigger
- "Ogni mattina alle 9:00" → Schedule Trigger
- "Quando arriva una nuova email" → Email Trigger
- "Quando ricevo un messaggio Telegram" → Telegram Trigger

#### 2. Nodi (le operazioni)
Ogni nodo è un'azione. Esistono centinaia di nodi predefiniti per:
- Gmail, Outlook, Slack, Telegram
- Google Sheets, Excel, Airtable
- Dropbox, Google Drive, OneDrive
- Google Analytics, Salesforce, Power BI
- Asana, Confluence, Jira, Notion, Trello
- E molto altro

#### 3. Connessioni (i fili)
Le frecce che collegano i nodi. I dati fluiscono lungo questi "fili".

---

### Esempio pratico 1: "Avvisami su Telegram quando arriva una email importante"

Scenario: hai un fornitore importante. Vuoi ricevere un messaggio Telegram ogni volta che ti manda una email.

```
[Email Trigger] → [IF: mittente contiene "miofornitore.com"] → [Telegram: invia messaggio]
```

**Come funziona passo per passo:**
1. Il **Email Trigger** rileva i nuovi messaggi
2. Il nodo **IF** verifica se il mittente del nuovo messaggio è il tuo fornitore
3. Se SÌ → il **nodo Telegram** ti manda "Hai una email da Mario Rossi: [oggetto]"
4. Se NO → non succede nulla

---

### Esempio pratico 2: "Salva automaticamente i dati di un foglio Excel su Google Sheets"

Scenario: ogni venerdì vuoi esportare i dati da un foglio condiviso.

```
[Schedule: venerdì alle 17:00] → [Leggi file Excel] → [Scrivi su Google Sheets]
```

**Come funziona passo per passo:**
1. Ogni venerdì alle 17:00 il **Schedule** avvia il workflow automaticamente
2. Il nodo **Leggi file Excel** apre il file e ne estrae i dati riga per riga
3. Il nodo **Scrivi su Google Sheets** aggiorna il foglio con i dati ricevuti

---

### Come creare il tuo primo workflow

1. Apri n8n sul browser
2. Clicca **"Start from scratch"**
3. Clicca il **+** per aggiungere il primo nodo
4. Cerca il tipo di trigger (es. "Manual" per testare a mano)
5. Aggiungi altri nodi cliccando sul **+** a destra di ogni nodo
6. Connetti i nodi trascinando le frecce
7. Clicca **"Execute Workflow"** per testare
8. Clicca **"Save"** e poi attiva il workflow con l'interruttore in alto

Per esempi concreti e configurazioni passo per passo, vedi le sezioni successive a partire da [Bot Telegram](#bot-telegram-per-notifiche).

---

### Codice nei workflow: JavaScript e Python

In n8n puoi aggiungere logica personalizzata tramite il nodo **Code node**. È importante capire cosa puoi usare e perché.

**JavaScript è il linguaggio nativo di n8n.** Il Code node gira direttamente su Node.js - lo stesso motore su cui è costruito n8n - e ha accesso completo a tutte le variabili del workflow (`$input`, `$json`, `$node`, ecc.). Per qualsiasi logica *dentro* un workflow (classificare un'email, costruire un messaggio, decidere dove spostare un file) il Code node in JavaScript è la scelta corretta.

**Python nel Code node - versione nativa.** Dalla versione 1.111.0 (stabile in n8n v2), n8n esegue Python tramite task runner nativi. Le variabili disponibili sono solo `_items` (modalità "Run Once for All Items") e `_item` (modalità "Run Once for Each Item") - le variabili JavaScript (`$input`, `$json` ecc.) non sono disponibili. I campi si accedono con notazione a parentesi: `item["json"]["campo"]`. Su installazione self-hosted puoi importare moduli della standard library e pacchetti di terze parti, se l'immagine `n8nio/runners` li include e li ha in allowlist. Mentre su n8n Cloud non è ancora possibile importare librerie, quindi è consentita solo logica senza importare nemmeno le librerie standard come era permesso nella vecchia modalità Pyodide che ora è legacy.

**Python lo si usa anche come script esterno.** Se hai bisogno di Python con le sue librerie, i suoi file, i suoi strumenti - lo scrivi come script `.py` autonomo sul server e lo chiami dal workflow tramite il nodo **Execute Command**, che esegue il comando come faresti dal terminale. n8n raccoglie l'output (JSON, testo) e lo passa ai nodi successivi. È il caso dello script `smistamento.py` in questa guida.

In sintesi: **JavaScript per la logica dentro n8n, Python nativo per calcoli semplici senza librerie (o con librerie se siamo su self-hosted), Python (esterno) per l'elaborazione specializzata fuori da n8n.**

---

## Server vs Cloud

### Scenario: tutti i colleghi usano n8n

Quando un'intera organizzazione vuole usare n8n, ci sono due strade:

#### Opzione A: Server condiviso (self-hosted)

Un solo server (fisico o virtuale) gira n8n per tutta l'azienda.

**Vantaggi:**
- Costo fisso (server VPS da ~€5-15/mese su Hetzner, OVH, ecc.)
- Dati rimangono **dentro la tua azienda** (importante per GDPR)
- Nessun limite di esecuzioni
- Personalizzazione totale
- I colleghi accedono tutti alla stessa interfaccia

**Svantaggi:**
- Qualcuno deve gestire aggiornamenti e backup
- Se il server va giù, n8n non funziona
- Richiede un minimo di competenza tecnica per la manutenzione

**Costi reali:**
- VPS base (2 CPU, 4GB RAM): ~€6-10/mese → sufficiente per piccoli team
- VPS medio (4 CPU, 8GB RAM): ~€15-25/mese → team di 10-20 persone

#### Opzione B: n8n Cloud

Paghi n8n direttamente per usare il loro servizio gestito.

**Vantaggi:**
- Zero manutenzione
- Aggiornamenti automatici
- Supporto ufficiale

**Svantaggi:**
- Costi variabili in base alle esecuzioni (~$20/mese per workspace, piano Starter con 2.500 esecuzioni)
- I tuoi dati sono su server di terze parti
- Limiti sul numero di workflow eseguiti

**Conclusione per team piccoli/medi:** Un VPS condiviso è quasi sempre la scelta migliore. Costa poco, i dati restano in casa, e un po' di manutenzione mensile è sufficiente.

---

### Gestione utenti e credenziali nel server condiviso

n8n supporta **ruoli e permessi**:
- **Owner**: l'amministratore, vede tutto
- **Admin**: può gestire workflow e utenti
- **Member**: può creare e usare workflow

**Regola d'oro per le credenziali:** Ogni utente o workflow dovrebbe avere le proprie credenziali, non condividerle tutte sotto un unico account. Se una credenziale viene compromessa, il danno è limitato.

### Scegli la tua strada

Ci sono due percorsi: installare n8n in [locale via Docker](../../scripts/docker_installer/italiano.md), oppure accedere a un [server condiviso](../server/italiano.md) già configurato. Entrambi seguono le stesse Parti 1–4 di questa guida - trovi i link alle guide specifiche dopo la Parte 4.

Se vuoi solo provare n8n rapidamente senza Docker, puoi installarlo con **npm** (richiede Node.js 18+):

```bash
npm install n8n -g
n8n start
```

> Per uso continuativo e condiviso, Docker è molto più pratico: vedi la [guida Docker](../../scripts/docker_installer/italiano.md).

---

## Bot Telegram per Notifiche

### Parte 1: Creare il Bot Telegram

1. Apri Telegram e cerca **@BotFather** oppure usa [questo link](https://web.telegram.org/k/#@BotFather)
2. Manda il messaggio `/newbot`
3. Scegli un nome (es. "Il Mio Bot n8n")
4. Scegli un username (deve finire in `bot`, es. `mio_n8n_bot`)
5. BotFather ti darà un **token** del tipo: `123456789:Aa0Bb1Cc2Dd3Ee4Ff5Gg6Hh7Ii8Jj9Kk0Ll`

> **ATTENZIONE:** Questo token è come la password del tuo bot. Chi lo ha può controllare il bot. Non condividerlo mai.

---

### Configurare le credenziali Telegram

**MAI** inserire il token direttamente nel workflow come testo. Le credenziali si configurano dal nodo Telegram o dalla sezione Credentials apposita.

**SE** non avete mai aperto n8n, nella sezione **Overview** troverete **Start from scratch**.

1. Apri il browser su n8n (in locale: `http://localhost:5678`, oppure il link del server condiviso)
2. Clicca su **Start from scratch**
3. Clicca sul +
4. Digita "telegram" nella ricerca in alto a destra
5. Scegli il nodo **On message**
6. Nel nodo selezionato, clicca il campo **"Credential to connect with"**
7. Clicca **"Create new credential"**
8. Incolla il token nel campo **"Access Token"**
9. Clicca **Save**

Il token è ora **cifrato** nel database di n8n. Puoi riusare la stessa credenziale in tutti i nodi Telegram del workflow.

Cliccando sulla x in alto a destra, e tornando sull'Overview, ora appare una sezione **Credentials**, dove troverete le credenziali appena salvate.

---

### Sicurezza del bot Telegram: riepilogo

| Cosa fare | Perché |
|-----------|--------|
| Salvare il token in `.env` come `TELEGRAM_TOKEN` | Usabile via `{{ $env.TELEGRAM_TOKEN }}` nel nodo HTTP Request, senza esporlo nel workflow (solo Docker - vedi [guida Docker](../docker/italiano.md)) |
| Salvare il token nelle Credentials di n8n | Il token è cifrato, non visibile nel workflow nei nodi Telegram |
| Non condividere il token via email/chat | Chiunque lo abbia controlla il bot |
| Usare un bot per ambiente (test / produzione) | Se il token di test è compromesso, la produzione è al sicuro |

---

### Parte 3: Trovare il tuo Chat ID

Per mandare messaggi, n8n ha bisogno del tuo **Chat ID** (il tuo identificativo univoco su Telegram).

**Metodo semplice: @userinfobot**

1. Apri Telegram e cerca **@userinfobot** oppure usa [questo link](https://web.telegram.org/k/#@userinfobot)
2. Manda il messaggio `/start`
3. Il bot risponde con il tuo **User ID**: quello è il tuo Chat ID nelle chat private

**Metodo alternativo: API getUpdates**

1. Manda un qualsiasi messaggio al tuo bot
2. Apri nel browser: `https://api.telegram.org/bot<IL_TUO_TOKEN>/getUpdates`
3. Cerca il campo `"id"` dentro `"chat"` - quello è il tuo Chat ID

> **Nota:** getUpdates può restituire un array vuoto se non hai inviato messaggi recenti al bot. In quel caso usa @userinfobot.

---

### Parte 4: Workflow 1 - conta i file con trigger manuale

Prima di costruire il bot completo, prova questo workflow minimale per verificare che tutto funzioni: conta i file `.py` nella cartella degli script e manda il risultato su Telegram.

```
[Nodo A: Manual Trigger]
  ↓
[Nodo B: Read Files from Disk]
  ↓
[Nodo C: Code node: conta i file]
  ↓
[Nodo D: Telegram: invia il risultato]
```

> [Diagramma del workflow](../../mermaid/italiano/workflow1.mermaid)

**Nodo A – Manual Trigger:** nessuna configurazione necessaria.

**Nodo B – Read Files from Disk:**
- File Selector: `/home/node/.n8n-files/scripts/workflow5/*.py`

> Il percorso funziona perché n8n monta la cartella `scripts/` - su Docker tramite i volumi in `docker-compose.yml`, sul server condiviso è già configurato.

**Nodo C – Code, conta i file:**
- Mode: **Run Once for All Items**

Scegli il linguaggio che preferisci
- Javascript:
```javascript
return [{ json: { count: $input.all().length } }];
```
- Python:
```python
return [{"json": {"count": len(_items)}}]
```

**Nodo D – Telegram, Send a text message:**
- Credential: vedi [Configurare le credenziali Telegram](#configurare-le-credenziali-telegram)
- Operation: Send Message
- Chat ID: il tuo Chat ID (trovato nella Parte 3)
- Text: `Trovati {{ $json.count }} file .py`

Clicca **"Execute workflow"** - se arriva il messaggio su Telegram, tutto funziona.

### Prima di continuare: salva e crea un nuovo workflow

1. **Salva** il workflow corrente con il nome **Workflow 1** (o **W1**): clicca sul nome del workflow in alto e rinominalo
2. **Crea un nuovo workflow** vuoto: menu in alto a sinistra → **New workflow**
3. Rinominalo **Workflow 2** (o **W2**)

La Parte 5 costruirà il Workflow 2 da zero. I Nodi B, C e D del Workflow 1 verranno riutilizzati: copiali (selezionali → Ctrl+C) e incollali (Ctrl+V) nel nuovo workflow.

> **Tip:** ogni volta che ti serve un nodo Telegram "Send a text message" in un nuovo workflow, copia un nodo Telegram già configurato da un workflow esistente e incollalo: credenziale e Chat ID sono già impostati, devi solo cambiare il testo.

---

Ora continua con la **Parte 5** nella tua guida: [guida Docker →](../docker/italiano.md#parte-5-workflow-2-polling-e-comandi) | [guida server →](../server/italiano.md#parte-5-workflow-completo-con-webhook)

---

## Riepilogo: architettura dei workflow

```
n8n self-hosted (Docker)
│
├── Workflow 1: Bot Telegram - Parte 4 (test manuale)
│   └── Nodo A (Manual Trigger) → Nodo B → Nodo C → Nodo D
│
├── Workflow 2: Bot Telegram - Parte 5 (polling completo)
│   ├── Nodo 1 (Schedule) → Nodo 2 (getUpdates) → Nodo 3 (filtra) → Nodo 4 (Switch)
│   ├── ramo /status:    Nodo B → Nodo C → Nodo D
│   └── ramo fallback:   Nodo 5 (IF regex) → Nodo 6 (Telegram)
│
├── Workflow 3: Classificazione Email Gmail
│   └── Gmail Trigger → Text Classifier (AI) → Gmail Add Label
│
├── Workflow 4: Classificazione Email Outlook
│   └── Outlook Trigger → Text Classifier (AI) → Outlook Move Message
│
├── Workflow 5: Avvio Scansione Workspace
│   └── Manual Trigger → Execute Command (nohup process.py &) → Telegram "avviata"
│       process.py gira in autonomia, al termine notifica Telegram direttamente
│
├── Workflow 6: Monitoraggio Scansione (struttura identica al Workflow 2)
│   ├── Nodo 1 (Schedule) → Nodo 2 (getUpdates) → Nodo 3 (filtra) → Nodo 4 (Switch)
│   ├── ramo /status:    Execute Command (monitor.py) → Code (messaggio) → Nodo D
│   └── ramo fallback:   Nodo 5 (IF regex) → Nodo 6 (Telegram)
│
├── Workflow 7: RSS Fetch
│   └── Schedule → RSS Feed Read → Code (filtra) → Write File → Telegram
│
└── Workflow 8: Monitor W7 (struttura identica al Workflow 6)
    ├── ramo /status:    HTTP Request (n8n API) → Read File → Code → Telegram
    └── ramo fallback:   Nodo 5 (IF regex) → Nodo 6 (Telegram)
```

> [Diagramma completo dell'architettura](../../mermaid/italiano/workflow.basic.mermaid)

**Dove trovare i dettagli:**
- Workflow 1–2: [intro](italiano.md#bot-telegram-per-notifiche) (Parti 1–4) + [guida Docker](../docker/italiano.md#parte-5-workflow-completo-con-polling-e-comandi) o [guida server](../server/italiano.md)
- Workflow 3–4: [guida email](../email/italiano.md)
- Workflow 5–6: [guida Docker](../docker/italiano.md#monitoraggio-processi-con-python)
- Workflow 7–8: [guida RSS](../rss/italiano.md)

---

## Risorse ufficiali

- [Documentazione n8n](https://docs.n8n.io/)
- [Installazione Docker](https://docs.n8n.io/hosting/installation/docker/)
- [Nodo Telegram](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.telegram/)
- [Credenziali Telegram](https://docs.n8n.io/integrations/builtin/credentials/telegram/)
- [Code node (Python/JS)](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.code/)
- [Local File Trigger](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.localfiletrigger/)
- [Template workflow email Gmail](https://n8n.io/workflows/2740-basic-automatic-gmail-email-labelling-with-openai-and-gmail-api/)
- [Template workflow email Outlook](https://n8n.io/workflows/8336-automatic-email-categorization-and-organization-with-outlook-and-gpt-4o/)
- [Variabili d'ambiente sicurezza](https://docs.n8n.io/hosting/configuration/environment-variables/security/)
- [Segreti esterni (Vault, AWS Secrets Manager)](https://docs.n8n.io/external-secrets/)
- [Prezzi n8n Cloud](https://n8n.io/pricing/)
- [Self-hosted vs Cloud (confronto)](https://docs.n8n.io/choose-n8n/)
