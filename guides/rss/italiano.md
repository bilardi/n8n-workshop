# Guida n8n - RSS Feed e Monitoraggio Workflow
## Per sviluppatori

---

> **Prima di continuare:** completa le [Parti 1–4 dell'introduzione](../intro/italiano.md) (bot Telegram, credenziali, Chat ID, Workflow 1).

---

## Indice

1. [Prerequisiti](#prerequisiti)
2. [Workflow 7: RSS Fetch](#workflow-7--rss-fetch)
3. [Workflow 8: Monitor](#workflow-8--monitor)

---

## Prerequisiti

Questi passi vanno completati prima di costruire i workflow.

- **Per il Workflow 7:** hai bisogno di n8n attivo e del Workflow 1 completato. Se non lo hai ancora:
  1. Parti da [intro/italiano.md](../intro/italiano.md) per creare il bot Telegram e completare il Workflow 1 (Parte 4)
  2. Poi segui la [guida installazione Docker](../../scripts/docker_installer/italiano.md), oppure [server/italiano.md](../server/italiano.md) per accedere al server condiviso
- **Per il Workflow 8:** hai bisogno anche del Workflow 2 completato (Parte 5 della [guida Docker](../docker/italiano.md#parte-5-workflow-2-polling-e-comandi) o [guida server](../server/italiano.md)), perché il W8 riusa la stessa struttura (Schedule + getUpdates + Switch)

### API key di n8n

Il Workflow 8 interroga le API REST di n8n per sapere se il Workflow 7 è in esecuzione. Serve una chiave API.

**Generare la chiave:**
1. In n8n: **Settings → n8n API → Create an API Key**
2. Copiare la chiave generata

**Salvarla nel file `.env`** (nella cartella `scripts/docker_installer/`):
```
N8N_API_KEY=la_chiave_copiata
```

Il `docker-compose.yml` passa già `N8N_API_KEY` al container: non serve modificarlo.

**Riavviare il container:**
```bash
docker compose down && docker compose up -d
```

> Su server condiviso: l'`N8N_API_KEY` è unica per tutta l'istanza n8n. Va generata dall'amministratore (Settings → API) e impostata nelle variabili d'ambiente del server.

---

## Workflow 7 - RSS Fetch

Crea un nuovo workflow. Per il nodo Telegram, copia quello già configurato da un workflow precedente e cambia solo il testo.

Questo workflow legge due feed RSS in parallelo, filtra gli articoli per keyword e salva i risultati. Mostra dei nodi nuovi: **RSS Feed Read**, **Merge**, **Convert to/from File**, e **Write File to Disk**.

### Struttura

```
[Schedule / Manual Trigger]
  ├── [RSS Feed Read: n8n blog]
  ├── [RSS Feed Read: Python blog]
  └── [Execute Command: prepara cartella /tmp/workflow7]
         ↓
[Merge: combina tutti e 3 gli output]
  ↓
[Code: filtra per keyword]
  ↓
[Convert to/from File]
  ↓
[Write File to Disk: last_run.json]
  ↓
[Telegram: riepilogo]
```

> [Diagramma del workflow](../../mermaid/italiano/workflow7.mermaid) | [Diagramma di sequenza](../../mermaid/italiano/workflow.rss.mermaid)

### Nodo 1 – Schedule Trigger

- Interval: **1 hour** (o usa Manual Trigger per testare)

### Nodo 2a – RSS Feed Read (n8n blog)

- URL: `https://blog.n8n.io/rss/`

### Nodo 2b – RSS Feed Read (Python blog)

- URL: `https://blog.python.org/feeds/posts/default?alt=rss`

Collega entrambi i nodi direttamente al Nodo 1: n8n li esegue **in parallelo**. Ogni nodo restituisce un item per ogni articolo con i campi: `title`, `link`, `pubDate`, `content`.

### Nodo 2c – Execute Command: prepara cartella

```bash
mkdir -p /tmp/workflow7 && touch /tmp/workflow7/last_run.json && chmod 777 /tmp/workflow7/last_run.json
```

Collega anche questo nodo direttamente al Nodo 1, in parallelo con i nodi RSS. Crea la cartella e il file con i permessi corretti per il nodo Write File to Disk.

> **Perché in parallelo dal Trigger?** Se l'Execute Command fosse in sequenza dopo il Code, il nodo Convert to/from File erediterebbe i dati binari dell'Execute Command invece del JSON del Code, producendo un file corrotto. Mettendolo in parallelo, i dati binari non interferiscono.

> **Alternativa senza Execute Command:** creare la cartella `/tmp/workflow7` direttamente nel Dockerfile (Docker) o chiedere all'amministratore del server di crearla con i permessi corretti. In questo caso il Nodo 2c non serve.

### Nodo 3 – Merge

- Mode: **Append**
- Number of Inputs: 3

Collega le uscite di Nodo 2a, Nodo 2b e Nodo 2c a questo nodo. Il Merge unisce tutti gli output: gli item RSS dei due feed più l'output dell'Execute Command. Il Code node successivo filtra solo gli item che hanno un campo `title`, ignorando l'output dell'Execute Command.

### Nodo 4 – Code: filtra per keyword

- Mode: **Run Once for All Items**
- **Rinomina il nodo in "Code"** (doppio clic sul titolo del nodo nell'editor): il Nodo 7 (Telegram) lo referenzia come `$node["Code"]`

Questo nodo riceve tutti gli articoli RSS e restituisce un singolo item JSON con i risultati filtrati. Definisci le keyword e il feed in cima al codice.

Scegli il linguaggio che preferisci
- Javascript:
```javascript
const KEYWORDS = ["python", "n8n"];

const found = [];
for (const item of $input.all()) {
  const title = (item.json.title || "").toLowerCase();
  for (const kw of KEYWORDS) {
    if (title.includes(kw.toLowerCase())) {
      found.push({
        title:   item.json.title,
        url:     item.json.link,
        date:    item.json.pubDate,
        keyword: kw,
      });
      break;
    }
  }
}

return [{
  json: {
    timestamp: new Date().toISOString().slice(0, 19),
    keywords: KEYWORDS,
    items_found: found.length,
    items: found,
  }
}];
```
- Python:
```python
from datetime import datetime

KEYWORDS = ["python", "n8n"]

found = []
for item in _items:
    title = (item["json"].get("title") or "").lower()
    for kw in KEYWORDS:
        if kw.lower() in title:
            found.append({
                "title": item["json"].get("title"),
                "url":   item["json"].get("link"),
                "date":  item["json"].get("pubDate"),
                "keyword": kw,
            })
            break

return [{
    "json": {
        "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S"),
        "keywords": KEYWORDS,
        "items_found": len(found),
        "items": found,
    }
}]
```

> **Nota:** L'import di `datetime` richiede il task runner Python nativo (container `n8n-task-runners` con `N8N_RUNNERS_STDLIB_ALLOW=*` nel file `n8n-task-runners.json`). Senza il runner, il Code node Python usa Pyodide che blocca tutti gli import.

> **Tip per testare il W8:** l'esecuzione del W7 è molto rapida - il W8 potrebbe non riuscire a vederla come "running". Per simulare un'esecuzione lunga, aggiungi uno sleep nel Code node prima del `return`:
> - Javascript: `await new Promise(r => setTimeout(r, 30000));`
> - Python: `import time` e `time.sleep(30)`

### Nodo 5 – Convert to/from File

- Operation: **Convert to File**
- Output format: **JSON**
- File name: `last_run.json`
- Mode: All items to One File

Questo nodo converte il JSON prodotto dal Code node in un file binario pronto per essere scritto su disco.

### Nodo 6 – Write File to Disk

- File Path: `/tmp/workflow7/last_run.json`

Sovrascrive il file ad ogni esecuzione: tiene solo l'ultimo risultato.

### Nodo 7 – Telegram, Send a text message

- Credential: la tua credenziale Telegram
- Chat ID: il tuo Chat ID fisso (vedi la Parte 3 dell'introduzione)
- Text:
```
{{ $node["Code"].json.items_found > 0
  ? "📰 " + $node["Code"].json.items_found + " articoli trovati (ultimi 10):\n" +
    $node["Code"].json.items.sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 10).map(i => "• " + i.title + "\n  " + i.url).join("\n")
  : "📭 Nessun articolo trovato per: " + $node["Code"].json.keywords.join(", ") }}
```

> Il template ordina gli articoli per data (più recenti prima) e mostra solo i primi 10. Telegram ha un limite di 4096 caratteri per messaggio: con 56 articoli il messaggio verrebbe troncato.

> **Chat ID fisso:** questo workflow è avviato da uno Schedule, non da un messaggio Telegram, quindi non esiste un mittente da cui estrarre il Chat ID dinamicamente. Usa il Chat ID fisso trovato nella Parte 3.


---

## Workflow 8 - Monitor

Questo workflow è il bot Telegram che risponde al comando `/status` con lo stato del Workflow 7. Il modo più veloce: copia l'intero Workflow 6 (o Workflow 2), poi modifica solo il ramo `/status`.

```
[Telegram Trigger / Schedule+HTTP]
  ↓
[Switch: /status]
    ├── /status ──→ [HTTP Request: n8n API]
    │            └─→ [Read File from Disk] → [Convert to/from File: estrai JSON]
    │                       ↓
    │               [Merge: combina API + file]
    │                       ↓
    │               [Code: formatta messaggio]
    │                       ↓
    │               [Telegram]
    └── fallback → [IF regex] → [Telegram]
```

> [Diagramma del workflow](../../mermaid/italiano/workflow8.mermaid)

> **Perché due rami paralleli + Merge?** Se il Read File from Disk riceve l'input dall'HTTP Request, eredita i suoi dati binari e il Convert estrae quelli invece del contenuto di `last_run.json`. Collegandoli in parallelo dal Switch, ciascun nodo riceve solo i propri dati.

### Nodi 1–4 e Fallback

Configura **Nodo 1 (Schedule), Nodo 2 (HTTP Request getUpdates), Nodo 3 (Code filtra recenti), Nodo 4 (Switch), Nodo 5 (IF regex) e Nodo 6 (Telegram)** esattamente come nel [Workflow 2 - Parte 5](../docker/italiano.md).

> Su server condiviso usa **Telegram Trigger** al posto di Schedule + HTTP, come nel [Workflow 6 - server](../server/italiano.md).

L'unica differenza è nel ramo `/status` del Switch: usa i nodi seguenti.

### Ramo /status - Nodo A: HTTP Request (n8n API)

- **Rinomina il nodo in "HTTP Request"** (doppio clic sul titolo): il Nodo E (Code) lo referenzia come `$node["HTTP Request"]`
- Collega direttamente al ramo `/status` del nodo Switch
- Method: **GET**
- URL: `http://localhost:5678/api/v1/executions`
- Send Query Parameters:
  - `workflowId`: l'ID del Workflow 7 (copialo dall'URL dell'editor dopo aver salvato W7, es. `…/workflow/AbCdEfGh12` → `AbCdEfGh12`)
  - `status`: `running`
- Send Headers:
  - `X-N8N-API-KEY`: `{{ $env.N8N_API_KEY }}`

> Su server condiviso: sostituire `localhost:5678` con il dominio del server.

> **L'ID cambia** se elimini e ricrei il Workflow 7. In quel caso aggiorna il parametro `workflowId` qui.

Restituisce `{ data: [...] }` che sarà un array vuoto se W7 non è in esecuzione.

### Ramo /status - Nodo B: Read File from Disk

- File Path: `/tmp/workflow7/last_run.json`
- Collega direttamente al ramo `/status` del nodo Switch (in parallelo al Nodo A, non in sequenza)
- **Impostare "Continue on Error"**: nella tab **Settings** del nodo, campo **On Error**, seleziona **Continue**. Se il file non esiste ancora (W7 non è mai stato eseguito), il workflow continua invece di bloccarsi.

### Ramo /status - Nodo C: Convert from File

- Operation: **Extract from File**
- Input format: **JSON**
- **Impostare "Continue on Error"**: tab **Settings** > **On Error** > **Continue**. Se il Nodo B ha prodotto un errore (file assente), anche questo nodo continua.

### Ramo /status - Nodo D: Merge

- Mode: **Append**
- Number of Inputs: 2

Collega le uscite di Nodo A (HTTP Request) e Nodo C (Convert) a questo nodo. Il Code riceverà due item: item 0 = dati API, item 1 = dati file.

### Ramo /status - Nodo E: Code, formatta messaggio

- Mode: **Run Once for All Items**

Scegli il linguaggio che preferisci
- Javascript:
```javascript
const items = $input.all();
const apiData = items[0].json.data ?? [];

let last = {};
const fileData = items[1].json.data ?? [];
if (Array.isArray(fileData) && fileData.length > 0) {
  last = fileData[0];
}

let msg;
if (apiData.length > 0) {
  msg = "🔄 Workflow 7 in corso";
} else if (last.timestamp) {
  const kw = (last.keywords || []).join(", ");
  msg = `✅ Workflow 7 fermo\nUltima esecuzione: ${last.timestamp}\nArticoli trovati: ${last.items_found ?? 0} (${kw})`;
} else {
  msg = "⏳ Workflow 7 non ancora eseguito";
}

return [{ json: { messaggio: msg } }];
```
- Python:
```python
api_data = _items[0]["json"].get("data", [])

last = {}
file_data = _items[1]["json"].get("data", [])
if isinstance(file_data, list) and len(file_data) > 0:
    last = file_data[0]

if api_data:
    msg = "🔄 Workflow 7 in corso"
elif last.get("timestamp"):
    ts = last["timestamp"]
    n  = last.get("items_found", 0)
    kw = ", ".join(last.get("keywords", []))
    msg = f"✅ Workflow 7 fermo\nUltima esecuzione: {ts}\nArticoli trovati: {n} ({kw})"
else:
    msg = "⏳ Workflow 7 non ancora eseguito"

return [{"json": {"messaggio": msg}}]
```

### Ramo /status - Nodo F: Telegram, Send a text message

- Credential: la tua credenziale Telegram
- Chat ID:
  - **Docker (Schedule+HTTP):** Chat ID fisso trovato nella Parte 3
  - **Server (Telegram Trigger):** `{{ $('Telegram Trigger').first().json.message.chat.id }}`
- Text: `{{ $json.messaggio }}`

---
