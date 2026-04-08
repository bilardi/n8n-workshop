# Guida n8n installato su Docker
## Per chi installa n8n sul proprio computer

---

## Indice

1. [Installazione](#installazione)
2. [Parte 5: Workflow 2 -polling e comandi](#parte-5-workflow-completo-con-polling-e-comandi)
3. [Monitoraggio processi con Python](#monitoraggio-processi-con-python)

---

## Installazione

Per installare n8n con Docker (Windows, Linux, macOS), configurare il `.env`, fare backup e ripristino, vedi la guida completa:

> **[Guida installazione Docker](../../scripts/docker_installer/italiano.md)**

La guida copre anche l'installazione senza Docker via npm.

---

## Bot Telegram per Notifiche

> **Prima di continuare:** completa le [Parti 1–4 dell'introduzione](../intro/italiano.md) (bot Telegram, credenziali, Chat ID, workflow di test). Se stai iniziando da zero, parti da lì.

Per la configurazione delle credenziali e le note di sicurezza, vedi [intro/italiano.md](../intro/italiano.md#configurare-le-credenziali-telegram).

### Parte 5: Workflow 2 - polling e comandi

Crea un nuovo workflow. Copia i Nodi B, C e D dal Workflow 1 (selezionali → Ctrl+C → nuovo workflow → Ctrl+V): sono già configurati e verranno riutilizzati nel ramo `/status`.

Questo workflow gira in background, controlla ogni minuto i messaggi del bot e risponde ai comandi.

**Struttura del workflow:**

```
[Nodo 1: Schedule Trigger]
  ↓
[Nodo 2: HTTP Request]
  ↓
[Nodo 3: Code: filtra recenti]
  ↓
[Nodo 4: Switch]
  ├── /status    → [Nodo B] → [Nodo C] → [Nodo D]
  ├── no message → (nessuna azione)
  └── fallback   → [Nodo 5: IF regex]
                       ├── Sì → [Nodo 6: Telegram]
                       └── No → (nessuna azione)
```

> [Diagramma del workflow](../../mermaid/italiano/workflow2.mermaid) | [Diagramma di sequenza](../../mermaid/italiano/workflow.basic.mermaid)

#### Nodo 1 - Schedule Trigger

- Interval: 1 minuto

#### Nodo 2 - HTTP Request (getUpdates)

- Method: `GET`
- URL: `https://api.telegram.org/bot{{ $env.TELEGRAM_TOKEN }}/getUpdates`

> Il nodo Telegram con "Get Updates" richiederebbe un webhook HTTPS pubblico e non funziona in locale.

> Se `TELEGRAM_TOKEN` non è ancora nel file `.env`, aggiungilo ora e riavvia: `docker compose down && docker compose up -d`

#### Nodo 3 - Code, estrai l'ultimo messaggio recente

- Mode: **Run Once for All Items**

Scegli il linguaggio che preferisci
- Javascript:
```javascript
const results = $input.first().json.result;
if (!results || results.length === 0) return [];

const unMinutoFa = Math.floor(Date.now() / 1000) - 60;
const recenti = results.filter(u =>
  u.message && u.message.date > unMinutoFa
);

if (recenti.length === 0) return [];
return [{ json: recenti[recenti.length - 1] }];
```
- Python:
```python
import time

results = _items[0]["json"]["result"]
if not results:
    return []

un_minuto_fa = int(time.time()) - 60
recenti = [u for u in results if u.get("message") and u["message"]["date"] > un_minuto_fa]

if not recenti:
    return []
return [{"json": recenti[-1]}]
```

#### Nodo 4 - Switch, smista per tipo di comando

- Abilita **Options +** > **Fallback Output** > Extra Output
- Routing Rule 1: `{{ $json.message.text }}` contains `/status`
  - Rename output: status
- Routing Rule 2: `{{ $json.message }}` not exists (messaggi senza testo)
  - Rename output: not exists

#### Nodi B, C, D (ramo /status)

Copia i Nodi B, C e D dal Workflow 1 (selezionali → Ctrl+C → nuovo workflow → Ctrl+V): sono già configurati nella [Parte 4](../intro/italiano.md#parte-4-workflow-1---conta-i-file-con-trigger-manuale).

Collega l'output `/status` del Nodo 4 al **Nodo B** (già configurato in Parte 4), collegato già ai Nodi C e D: stessi nodi fisici, nessuna riconfigurazione necessaria.

#### Nodo 5 - IF (dopo il Fallback): è un comando?

- Condition: `{{ $json.message.text }}` matches regex `^\/\w+`

#### Nodo 6 - Telegram: comando non riconosciuto
Copia il nodo D e modificalo
- Credential: vedi [Configurare le credenziali Telegram](../intro/italiano.md#configurare-le-credenziali-telegram)
- Operation: Send Message
- Chat ID: il tuo Chat ID (trovato nella Parte 3)
- Text: `Non conosco il comando {{ $json.message.text }}`

Nodo D e Nodo 6 usano il Chat ID fisso (trovato nella Parte 3): il Chat ID dinamico da `$json.message.chat.id` non funziona in questi percorsi.

> Con il Telegram Trigger (webhook) il Chat ID dinamico `$json.message.chat.id` funziona correttamente: disponibile nella [guida server](../server/italiano.md)

---

## Monitoraggio Processi con Python

### Il progetto

Creare un sistema che:
1. **Scansiona** la cartella definita in `WORKSPACE_PATH`, un file alla volta
2. **Registra ogni file** in `processed.csv` durante l'esecuzione (con timestamp, cartella e percorso completo)
3. **Permette il monitoraggio** in tempo reale tramite `/status` sul bot Telegram
4. **Dimostra il pattern** processo-in-background + monitoraggio PID, riutilizzabile per qualsiasi elaborazione lunga

Lo script gira in background, scrive il proprio PID in `pid.txt` all'avvio e lo cancella al termine; uno script separato (`workflow6/monitor.py`) aggrega lo stato in qualsiasi momento.

---

### Preparazione: .env

Se usi Docker, apri il file `.env` e imposta il percorso della cartella da monitorare:

```bash
# .env: decommenta e modifica solo questa riga
WORKSPACE_PATH=/home/mario/Documents
```

Se non imposti `WORKSPACE_PATH`, viene montata la sottocartella `./workspace` del repository.

> Se modifichi `.env` dopo il primo avvio, riavvia con: `docker compose down && docker compose up -d`

---

### Script Python: process.py

Riceve `--path` (la cartella da scansionare) e `--interval` (secondi tra un file e l'altro). Al termine chiama `workflow6/monitor.py` internamente per inviare il riepilogo su Telegram.

Per ogni file elaborato appende una riga a `/tmp/workflow5/processed.csv`:

| timestamp | dirname | path |
|-----------|---------|------|
| 2026-03-29T10:00:00 | /workspace/ | /workspace/report.pdf |
| 2026-03-29T10:00:05 | /workspace/ | /workspace/notes.txt |
| 2026-03-29T10:00:10 | /workspace/images/ | /workspace/images/foto.jpg |

#### Logica di scansione

1. **Cartella vuota**, se `WORKSPACE_PATH` non contiene file, scrive una sola riga con `path=.` e `dirname` uguale al percorso base
2. **Cartella con file**, per ogni file (in ordine alfabetico, ricorsivo):
   - Scrive una riga in `processed.csv` con timestamp, `dirname` (cartella relativa del file) e `path` (percorso completo)
   - Aspetta `--interval` secondi prima di passare al file successivo

---

### Script Python: monitor.py

`monitor.py` aggrega lo stato in un unico JSON leggendo tre sorgenti:
- `pid.txt`, per sapere se `process.py` è ancora in esecuzione (letto dalla cartella indicata con `--data`)
- `processed.csv`, conteggio totale e aggregazione per `--column` (default: `dirname`) (letto dalla stessa cartella `--data`)
- conteggio fisico ricorsivo delle sottocartelle (logica interna, auto-scopre tutte le cartelle)

```bash
python3 /home/node/.n8n-files/scripts/workflow6/monitor.py \
  --path /home/node/.n8n-files/workspace \
  --data /tmp/workflow5
```

```json
{
  "running": true,
  "total_files": 42,
  "processed_total": 30,
  "per_folder": {
    "/workspace":        { "processed": 15, "present": 20 },
    "/workspace/images": { "processed": 10, "present": 12 }
  }
}
```

Con `--format md` restituisce il messaggio formattato in Markdown invece del JSON:

```bash
python3 /home/node/.n8n-files/scripts/workflow6/monitor.py \
  --path /home/node/.n8n-files/workspace \
  --data /tmp/workflow5 --format md
```

Per aggregare per `path` invece che per `dirname`:

```bash
python3 /home/node/.n8n-files/scripts/workflow6/monitor.py \
  --path /home/node/.n8n-files/workspace \
  --data /tmp/workflow5 --column path
```

`monitor.py` gira una volta sola e termina: non c'è nessun loop. Il workflow n8n lo chiama ad ogni `/status` ricevuto.

---

### Workflow Monitoraggio Processi

Sono due workflow indipendenti che si basano sugli stessi script.

I workflow usano il nodo **Execute Command** per lanciare script Python nel container. Da n8n 2.0 questo nodo è bloccato di default per motivi di sicurezza. Per riabilitarlo, aggiungi nel `docker-compose.yml`:

```yaml
environment:
  - NODES_EXCLUDE=[]
```

Se preferisci non riabilitare un nodo potenzialmente deprecato, ci sono due alternative:

| Alternativa | Come funziona | Pro | Contro |
|-------------|---------------|-----|--------|
| **Nodo SSH** | Connessione SSH al container o a un host esterno che esegue il comando | Supportato ufficialmente, non a rischio deprecazione | Richiede un server SSH e credenziali da configurare |
| **HTTP Request → webhook esterno** | Lo script Python gira come servizio separato (es. Flask/FastAPI) e n8n lo chiama via HTTP | Disaccoppia n8n dagli script, scalabile | Richiede un servizio aggiuntivo da mantenere |

La guida prosegue con Execute Command. Se usi un'alternativa, sostituisci quel nodo mantenendo lo stesso comando.

#### Workflow 5 – Avvio scansione

Crea un nuovo workflow. Per il nodo Telegram, copia quello già configurato dal Workflow 2 e cambia solo il testo.

```
[Manual Trigger]
  ↓
[Execute Command, avvia process.py in background]
  ↓
[Telegram: Send Message "scansione avviata"]
```

> [Diagramma del workflow](../../mermaid/italiano/workflow5.mermaid) | [Diagramma di sequenza](../../mermaid/italiano/workflow.monitoring.mermaid)

**Execute Command**
```bash
nohup python3 /home/node/.n8n-files/scripts/workflow5/process.py \
  --path /home/node/.n8n-files/workspace --interval 5 > /dev/null 2>&1 &
```

Il nodo Execute Command lancia lo script in background e ritorna **subito**.

**Telegram: Send Text Message "scansione avviata"**
- Credential: la tua credenziale Telegram
- Chat ID: il tuo Chat ID fisso (trovato nella Parte 3)
- Text: `scansione avviata`

Questo nodo conferma immediatamente all'utente che la scansione è partita. Lo script `process.py` continua a girare per conto suo in background, scrive `pid.txt` e aggiorna `processed.csv` in `/tmp/workflow5/` ad ogni file. Quando finisce, chiama `workflow6/monitor.py --format md` internamente e invia lui stesso un secondo messaggio Telegram con il riepilogo finale, senza passare da n8n.

Per ricevere questa notifica finale imposta `TELEGRAM_CHAT_ID` nel file `.env`:
```bash
TELEGRAM_CHAT_ID=123456789   # il tuo Chat ID (trovato nella Parte 3)
```

> Se modifichi `.env` dopo il primo avvio, riavvia con: `docker compose down && docker compose up -d`

#### Workflow 6 – Monitoraggio scansione (struttura identica al Workflow 2)

```
[Nodo 1 – Schedule Trigger]
  ↓
[Nodo 2 – HTTP Request: getUpdates]
  ↓
[Nodo 3 – Code: filtra messaggi recenti]
  ↓
[Nodo 4 – Switch]
  ├── ramo /status → [Execute Command: monitor.py --format md] → [Nodo D – Telegram]
  └── ramo fallback → [Nodo 5 – IF regex] → [Nodo 6 – Telegram]
```

> [Diagramma del workflow](../../mermaid/italiano/workflow6.mermaid)

Crea un nuovo workflow. Il modo più veloce: copia l'intero Workflow 2 (seleziona tutti i nodi → Ctrl+C → nuovo workflow → Ctrl+V), poi modifica solo il ramo `/status`: elimina i Nodi B e C e sostituiscili con un nodo Execute Command collegato direttamente al Nodo D.

**Execute Command (ramo /status):**
```bash
python3 /home/node/.n8n-files/scripts/workflow6/monitor.py \
  --path /home/node/.n8n-files/workspace \
  --data /tmp/workflow5 \
  --format md
```

Il flag `--format md` fa sì che `monitor.py` restituisca direttamente il messaggio formattato in Markdown. Nel **Nodo D** imposta il campo Text a `{{ $json.stdout }}`.

---

### Sicurezza per il workflow file (nota per sviluppatori)

**Attenzione ai path injection:** Nei comandi Execute Command, i nomi dei file provengono dal filesystem. Assicurati di:

1. Non usare `eval` o shell expansion non necessaria
2. Usare percorsi assoluti invece di relativi
3. Limitare la cartella monitorata a una specifica (non `/` o `/home`)
4. Se usi Docker, montare solo la cartella necessaria, non l'intera home

```yaml
# Nel docker-compose.yml: monta SOLO la cartella necessaria
volumes:
  - /home/utente/Documents:/home/node/.n8n-files/workspace:z
  # NON fare:
  # - /home/utente:/home/utente  # troppo permissivo
```
