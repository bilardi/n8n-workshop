# Guida n8n - Scaricare e caricare workflow
## Portare i propri workflow da un'istanza all'altra

---

## Indice

1. [Dall'interfaccia n8n](#dallinterfaccia-n8n)
2. [Da Docker CLI](#da-docker-cli)
3. [Da API REST](#da-api-rest)
4. [Cosa viene esportato e cosa no](#cosa-viene-esportato-e-cosa-no)
5. [Risorse ufficiali](#risorse-ufficiali)

---

## Dall'interfaccia n8n

### Esportare un workflow

1. Apri il workflow che vuoi esportare
2. Clicca il menu **⋮** (tre puntini) in alto a destra
3. Seleziona **Download**
4. Il browser scarica un file `.json` con il nome del workflow

Il file contiene la definizione completa: nodi, connessioni, impostazioni e posizione dei nodi nel canvas.

> Dall'interfaccia non è possibile scaricare più workflow in una volta sola: per l'export multiplo vedi [Docker CLI](#da-docker-cli) o [API REST](#da-api-rest).

### Importare da file

1. Apri l'istanza di destinazione nel browser
2. Crea un nuovo workflow: menu in alto a sinistra → **Create workflow**
3. Nel workflow vuoto, clicca il menu **...** (tre puntini) in alto a destra
4. Seleziona **Import from File**
5. Scegli il file `.json` scaricato in precedenza
6. I nodi appaiono nel canvas: controlla che tutto sia collegato correttamente
7. Clicca **Save**

### Importare da URL

Se il file JSON è accessibile via URL (es. un link diretto da un repository o un server):

1. Crea un nuovo workflow
2. Menu **...** → **Import from URL**
3. Incolla l'URL del file `.json`
4. Controlla e salva

---

## Da Docker CLI

Solo self-hosted. I comandi vanno eseguiti sul container n8n già in esecuzione.

> Negli esempi il nome del container è `docker_installer-n8n-1` (default del `docker-compose.yml` di questo progetto). Sostituiscilo con il nome del tuo container; puoi trovarlo con `docker ps`.

### Esportare tutti i workflow

Salva i workflow dentro il container:

```bash
docker exec docker_installer-n8n-1 n8n export:workflow --all \
  --output=/tmp/all-workflows.json
```

Poi copia il file sull'host:

```bash
docker cp docker_installer-n8n-1:/tmp/all-workflows.json ./downloads/
```

Per esportare un file `.json` per ogni workflow:

```bash
docker exec docker_installer-n8n-1 sh -c "mkdir -p /tmp/workflows && n8n export:workflow --all --separate --output=/tmp/workflows/"
docker cp docker_installer-n8n-1:/tmp/workflows/. ./downloads/
```

> `--all` esporta tutti i workflow, compresi quelli archiviati. Per un backup leggibile e già separato per file, usa `--backup` al posto di `--all --separate`:
>
> ```bash
> docker exec docker_installer-n8n-1 sh -c "mkdir -p /tmp/workflows && n8n export:workflow --backup --output=/tmp/workflows/"
> ```

### Importare un workflow

Copia il file dentro il container e importa:

```bash
docker cp ./downloads/workflow.json docker_installer-n8n-1:/tmp/workflow.json
docker exec docker_installer-n8n-1 n8n import:workflow --input=/tmp/workflow.json
```

---

## Da API REST

Per chi vuole automatizzare l'esportazione, n8n espone un'API REST.

### Esportare un workflow

L'ID del workflow si trova nell'URL quando lo apri nell'editor: `http://localhost:5678/workflow/abcdefgABCDEFG`. La parte finale è l'ID.

```bash
cd n8n
export $(grep -v '^#' scripts/docker_installer/.env | xargs)
export WORKFLOW_ID=abcdefgABCDEFG
curl -H "X-N8N-API-KEY: $N8N_API_KEY" \
  http://localhost:5678/api/v1/workflows/$WORKFLOW_ID \
  -o workflow.json
```

### Importare un workflow

```bash
curl -X POST -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflow.json \
  http://localhost:5678/api/v1/workflows
```

> Per abilitare l'API REST su installazione self-hosted, serve `N8N_API_KEY` nel file `.env` e nel blocco `environment:` di `docker-compose.yml`: vedi la [guida Docker](../docker/italiano.md).

---

## Cosa viene esportato e cosa no

| Incluso nel file JSON | Non incluso |
|-----------------------|-------------|
| Nodi e connessioni | Credenziali (token, password, API key) |
| Impostazioni del workflow | Variabili d'ambiente (`$env.*`) |
| Posizione dei nodi nel canvas | Storico delle esecuzioni |
| Nodi sticky (note) | Tag assegnati al workflow |

**Dopo l'import, devi:**
- Ricreare le **credenziali** sull'istanza di destinazione (Telegram, Gmail, Outlook, ecc.) e riassegnarle ai nodi: ogni nodo che usa una credenziale mostrerà un avviso finché non ne selezioni una valida
- Verificare che le **variabili d'ambiente** esistano anche sulla nuova istanza (es. `TELEGRAM_TOKEN`, `N8N_API_KEY` nel file `.env` e in `docker-compose.yml`)
- Controllare i **percorsi dei file**: se il workflow usa nodi Read/Write File o Execute Command con percorsi assoluti (es. `/home/node/.n8n-files/scripts/`), assicurarsi che la struttura delle cartelle sia la stessa

---

## Risorse ufficiali

- [Documentazione n8n: Import/Export](https://docs.n8n.io/workflows/export-import/)
- [API REST n8n](https://docs.n8n.io/api/api-reference/)
