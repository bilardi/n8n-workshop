# Installazione n8n con Docker

## Indice

1. [Scarica il repository](#prima-di-tutto-scarica-il-repository)
2. [Perché Docker](#metodo-consigliato-docker)
3. [Windows](#installazione-docker-windows)
4. [Linux e macOS](#installazione-docker-linux-e-macos)
5. [Leggere file locali dai workflow](#leggere-file-locali-dai-workflow)
6. [WEBHOOK_URL: uso locale vs server](#webhook_url-uso-locale-vs-server)
7. [N8N_ENCRYPTION_KEY](#n8n_encryption_key-cosa-mettere)
8. [Backup e ripristino](#backup-e-ripristino)
9. [Troubleshoot](#troubleshoot)

---

## Prima di tutto: scarica il repository

Qualunque sistema tu usi (Windows, Linux o macOS), il primo passo è sempre lo stesso:

1. Scarica questo repository come **ZIP** (pulsante "Code → Download ZIP" su GitHub)
2. Estrailo nella cartella che preferisci
3. Tutti i file necessari (`docker-compose.yml`, `.env`, script) si trovano già lì

---

## Metodo consigliato: Docker

**Docker è il modo più semplice e consigliato** per installare n8n, soprattutto se vuoi:
- Usarlo su più computer
- Condividerlo con i colleghi
- Non preoccuparti di installare dipendenze (Node.js, ecc.)
- Aggiornarlo e fare backup facilmente

**Perché Docker è meglio dell'installazione diretta?**
- Funziona allo stesso modo su Windows, Mac e Linux
- Non "inquina" il tuo sistema con pacchetti vari
- Un solo comando per avviare, uno per fermare
- I dati sono al sicuro in un volume separato

---

## Installazione Docker: Windows

### Prerequisiti

Questi tre passi vanno completati **nell'ordine indicato** prima di usare qualsiasi script o comando.

**1. Abilita WSL2**

Apri PowerShell come amministratore (cerca "PowerShell" nel menu Start, clic destro → "Esegui come amministratore") e digita:

```powershell
wsl --install
```

Riavvia il computer quando richiesto. WSL2 è il motore Linux su cui Docker si appoggia su Windows.

**2. Installa Docker Desktop**

Scarica da [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) e installa. Durante l'installazione assicurati che l'opzione **"Use WSL2 instead of Hyper-V"** sia spuntata.

**3. Avvia Docker Desktop**

Apri Docker Desktop dal menu Start e aspetta che l'icona della balena nella barra delle applicazioni diventi **stabile** (smette di animarsi). Solo a quel punto Docker è pronto.

> **Nota:** Docker Desktop include già **Docker Compose**: non serve installare nulla di separato. Funziona su Windows 10/11 Home, Pro e Education.

---

### Opzione A: Script guidato per non programmatori (consigliato)

Se non hai familiarità con la riga di comando, usa lo script PowerShell incluso in questa guida: **`n8n-installer.ps1`**.

**Come usarlo:**
1. Nella cartella estratta, fai **clic destro** sul file `scripts/docker_installer/n8n-installer.ps1`
2. Scegli **"Esegui con PowerShell"**
3. Se appare un avviso di sicurezza, clicca **"Apri"** o **"Sì"**
4. Segui le istruzioni sullo schermo: dovari rispondere solo ad alcune domande semplici

Lo script in automatico:
- Verifica che Docker Desktop sia installato e avviato
- Chiede porta, fuso orario e chiave di cifratura
- Genera una chiave di sicurezza per proteggere le tue credenziali
- Crea il file `.env` con la configurazione
- Avvia n8n e apre il browser

> **Primo avvio:** la prima volta Docker scarica l'immagine di n8n (~500 MB). Può richiedere qualche minuto. I successivi avvii sono istantanei.

---

### Opzione B: Avvio manuale con Docker Compose

1. Apri il file `.env` con il Blocco Note e compila almeno i campi `N8N_ENCRYPTION_KEY` e `TELEGRAM_TOKEN` come suggerito nei commenti del file stesso
2. Apri **PowerShell** nella cartella `scripts/docker_installer` (tasto destro sulla cartella → "Apri in PowerShell") e digita:

```powershell
docker compose up -d
```

Apri il browser su: **http://localhost:5678**

> **Importante:** La chiave in `.env` cifra le tue credenziali salvate in n8n. Annotala in un posto sicuro: se la perdi, dovrai reinserire tutte le credenziali (email, Telegram, ecc.).

> Se modifichi `.env` dopo il primo avvio, riavvia con: `docker compose down && docker compose up -d`

---

## Installazione Docker: Linux e macOS

### Opzione A: Script guidato per non programmatori (consigliato)

Usa lo script bash incluso in questa guida: **`n8n-installer.sh`**.

**Come usarlo:**
```bash
# Dalla cartella estratta
bash scripts/docker_installer/n8n-installer.sh
```

Lo script:
- Rileva automaticamente il sistema operativo (Linux o macOS)
- Se Docker non è presente, mostra i comandi di installazione per la tua distribuzione e guida al download di Docker Desktop
- Rileva il fuso orario del sistema e lo propone come default
- Genera una chiave di sicurezza casuale
- Scrive `.env` e avvia n8n dalla cartella `scripts/docker_installer/`
- Apre il browser alla fine

---

### Opzione B: Avvio manuale con Docker Compose

**Su Linux**, se Docker non è installato, usa il gestore pacchetti della tua distribuzione:

```bash
# Debian/Ubuntu
sudo apt-get install docker.io docker-compose-plugin

# Fedora/RHEL
sudo dnf install docker docker-compose-plugin
```

**Su macOS**, installa Docker Desktop in uno dei due modi:

- Con **Homebrew** (se già installato): `brew install --cask docker-desktop`
- Manualmente: scarica da [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/), scegliendo la versione per **Apple Silicon** (M1/M2/M3) o **Intel**

Dopo l'installazione avvia Docker Desktop dalla cartella Applicazioni e aspetta che l'icona della balena nella barra superiore diventi stabile.

Poi, per entrambi i sistemi:

1. Apri il file `.env` con un editor di testo e compila almeno i campi `N8N_ENCRYPTION_KEY` e `TELEGRAM_TOKEN` come suggerito nei commenti del file stesso
2. Apri il **Terminale** nella cartella `scripts/docker_installer` e digita:

```bash
docker compose up -d
```

> **Come aprire il Terminale nella cartella giusta su macOS:** apri il Finder, vai nella cartella `scripts/docker_installer`, poi trascina la cartella sull'icona del Terminale nel Dock. In alternativa: `tasto destro sulla cartella → Nuova finestra di Terminal nella cartella` (visibile se hai abilitato questa opzione in Preferenze di Sistema → Tastiera → Abbreviazioni da tastiera → Servizi).

Apri il browser su: **http://localhost:5678**

> Se modifichi `.env` dopo il primo avvio, riavvia con: `docker compose down && docker compose up -d`

---

## Leggere file locali dai workflow

Per default n8n gira in un container Docker isolato: non può accedere ai file del tuo computer. Per rendere accessibile una cartella, è sufficiente impostare `WORKSPACE_PATH` nel file `.env`:

```bash
# .env
WORKSPACE_PATH=/home/mario/documenti
```

I file in quella cartella saranno accessibili in n8n al percorso `/home/node/.n8n-files/workspace`. Il `docker-compose.yml` incluso gestisce questo automaticamente.

Se non imposti `WORKSPACE_PATH`, viene montata la sottocartella `./workspace` del repository (inclusa nel progetto come cartella vuota pronta all'uso).

> Se modifichi `.env` dopo il primo avvio, riavvia con: `docker compose down && docker compose up -d`

---

## WEBHOOK_URL: uso locale vs server

In locale n8n usa `http://localhost:5678` come indirizzo per i webhook - funziona per i nodi HTTP Request e i webhook generici, ma **non** per il Telegram Trigger, che richiede un URL HTTPS raggiungibile da internet.

Se installi n8n su un server pubblico con HTTPS (es. dietro un reverse proxy con certificato), aggiungi nel `.env`:

```bash
WEBHOOK_URL=https://n8n.tuodominio.com
```

In locale non serve impostare questa variabile - i workflow della guida Docker usano il polling (Schedule + HTTP Request) proprio perché `localhost` non è raggiungibile da Telegram.

---

## N8N_ENCRYPTION_KEY: cosa mettere

È una password che n8n usa per cifrare le tue credenziali (email, token Telegram, ecc.) nel database. Deve essere una stringa casuale di **almeno 32 caratteri**. Non importa il contenuto preciso: l'importante è che sia lunga, casuale e che tu la conservi.

**Come generarla:**

```bash
# Linux / macOS
openssl rand -hex 32
```

```powershell
# Windows PowerShell
-join ((1..32) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
```

Entrambi i comandi producono una stringa esadecimale di 64 caratteri, adatta come chiave.

Gli script `n8n-installer.ps1` e `n8n-installer.sh` la generano automaticamente. Se configuri il `.env` a mano, sostituisci il valore placeholder con una stringa generata come sopra.

---

## Backup e ripristino

n8n salva workflow, credenziali e impostazioni nel volume Docker `n8n_data`, separato dai file del progetto. I tuoi script e `.env` sono già nella cartella del repository, basta copiarli. Il volume invece va esportato esplicitamente.

### Backup

```bash
# Esporta il volume n8n_data in un archivio compresso
docker run --rm -v n8n_data:/data -v "$(pwd)":/backup alpine \
  tar czf /backup/n8n_backup.tar.gz -C /data .
```

Il file `n8n_backup.tar.gz` viene creato nella cartella corrente. Conservalo insieme al `.env` (contiene la chiave di cifratura, senza la quale le credenziali salvate non sono recuperabili).

### Ripristino

```bash
# Ricrea il volume dal backup (sovrascrive i dati esistenti)
docker run --rm -v n8n_data:/data -v "$(pwd)":/backup alpine \
  sh -c "cd /data && tar xzf /backup/n8n_backup.tar.gz"
```

Dopo il ripristino riavvia n8n: `docker compose up -d`

> **Nota:** Il backup include solo i dati di n8n (workflow, credenziali, impostazioni). I file nelle cartelle `downloads/`, `workspace/` e `scripts/` vivono già fuori dal volume: fai un backup separato se servono.

> **Su Windows** sostituisci `"$(pwd)"` con `${PWD}` in PowerShell, oppure usa il percorso completo della cartella (es. `C:\Users\Mario\backup`).

---

## Troubleshoot

Script interattivo per diagnosticare e risolvere i problemi più comuni dell'installazione Docker di n8n.

### Quando usarlo

- Vuoi verificare che Python sia disponibile nel container (necessario per i Workflow 5 e 6)
- Vuoi eseguire `process.py` o `monitor.py` in primo piano per vedere eventuali errori
- Vuoi controllare i log del container n8n

### Requisiti

- Docker Desktop in esecuzione
- Il container n8n avviato con `docker compose up -d`

### Uso

**Linux / macOS:**

```bash
./troubleshoot.sh
```

**Windows (PowerShell):**

```powershell
.\troubleshoot.ps1
```

Lo script rileva automaticamente il container n8n dal `docker-compose.yml`.

### Menu

| Opzione | Comando | A cosa serve |
|---------|---------|--------------|
| 1 | `python3 --version` | Verifica che Python sia installato nel container (Dockerfile custom) |
| 2 | `process.py` | Esegue la scansione in primo piano - utile per vedere errori di permessi o path |
| 3 | `monitor.py` | Mostra lo stato della scansione in formato JSON |
| 4 | `monitor.py --format md` | Mostra lo stato della scansione in formato Markdown (come lo vedrebbe Telegram) |
| 5 | `logs` | Mostra le ultime 50 righe di log del container n8n |
| 6 | `shell` | Apre una shell interattiva dentro il container |

### Flusso tipico di troubleshooting

1. **Opzione 1** - se fallisce, il Dockerfile custom non è stato applicato: ricostruire con `docker compose up -d --build`
2. **Opzione 2** - esegue `process.py` in primo piano: gli errori appaiono direttamente nel terminale (es. `PermissionError`, `FileNotFoundError`)
3. **Opzione 4** - verifica che `monitor.py` produca il messaggio Markdown atteso
4. **Opzione 5** - controlla i log se n8n non si avvia o si comporta in modo anomalo

### Problemi comuni

| Problema | Causa | Soluzione |
|----------|-------|-----------|
| `python3: not found` | Immagine n8n standard senza Python | Usare il Dockerfile custom e ricostruire con `--build` |
| `PermissionError` su `pid.txt` o `processed.csv` | Script cercava di scrivere nel volume scripts (read-only) | Gli script ora scrivono in `/tmp/workflow5/` (già corretto) |
| `Folder not found` | `WORKSPACE_PATH` non impostato o path errato | Controllare `.env` e riavviare il container |
