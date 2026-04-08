# Guida n8n - Server condiviso
## Per i partecipanti al meetup

---

## Come accedere al server

1. Collegati al canale Telegram del meetup
2. Vai al topic **n8n**
3. Trovi lì il link al server che useremo oggi
4. Apri il link nel browser: l'interfaccia n8n è già pronta

---

## Indice

1. [Parte 5: Workflow completo con webhook](#parte-5-workflow-completo-con-webhook)

---

## Bot Telegram per Notifiche

> **Prima di continuare:** completa le [Parti 1-4 dell'introduzione](../intro/italiano.md) (bot Telegram, credenziali, Chat ID, workflow di test). Se stai iniziando da zero, parti da lì.

Per la configurazione delle credenziali e le note di sicurezza, vedi [intro/italiano.md](../intro/italiano.md#configurare-le-credenziali-telegram).

### Parte 5: Workflow completo con webhook

Crea un nuovo workflow. Copia i Nodi B, C e D dal Workflow 1 (selezionali → Ctrl+C → nuovo workflow → Ctrl+V): sono già configurati e verranno riutilizzati nel ramo `/status`.

A differenza della guida Docker che usa il **polling** (Schedule + HTTP Request), qui usiamo il nodo **Telegram Trigger** che riceve i messaggi via **webhook**: Telegram chiama n8n direttamente ad ogni messaggio, senza polling periodico.

> Il Telegram Trigger funziona solo su server raggiungibile pubblicamente via HTTPS. Il server del meetup è già configurato. Non funziona in localhost - per questo la guida Docker usa il polling.

**Struttura del workflow:**

```
[Telegram Trigger]
  ↓
[Switch: smista comandi]
  ├── /status  → [Nodo B] → [Nodo C] → [Nodo D]
  └── fallback → [Nodo 5: IF regex]
                     ├── Sì → [Nodo 6: Telegram]
                     └── No → (nessuna azione)
```

> [Diagramma del workflow](../../mermaid/italiano/workflow2-webhook.mermaid)

#### Nodo 1: Telegram, Trigger, on message

- Resource: **Message**
- Credential: la credenziale creata in Parte 2
- n8n registra il webhook automaticamente con Telegram all'attivazione del workflow: non serve configurare nulla di extra
- Non serve Schedule né HTTP Request né il nodo Code "filtra recenti": il Trigger consegna solo i messaggi nuovi

---

#### Nodo 4: Switch, smista per tipo di comando

- Abilita **Options +** > **Fallback Output** > Extra Output
- Routing Rule 1: `{{ $json.message.text }}` contains `/status`
  - Rename output: status

Rispetto alla guida Docker, **si rimuove la regola "no message"** (`$json.message` not exists): il Telegram Trigger si attiva solo quando arriva un messaggio, e la condizione di nessun messaggio non si verifica mai.

#### Nodi B, C, D (ramo /status)

Copia i Nodi B, C e D dal Workflow 1 (selezionali → Ctrl+C → nuovo workflow → Ctrl+V): sono già configurati nella [Parte 4](../intro/italiano.md#parte-4-workflow-1---conta-i-file-con-trigger-manuale).

Collega l'output `/status` del Nodo 4 al **Nodo B** - il flusso prosegue automaticamente verso Nodo C e Nodo D.

#### Nodo 5 - IF (dopo il Fallback): è un comando?

- Condition: `{{ $json.message.text }}` matches regex `^\/\w+`

#### Nodo 6 - Telegram: comando non riconosciuto
Copia il nodo D e modificalo
- Credential: vedi [Configurare le credenziali Telegram](../intro/italiano.md#configurare-le-credenziali-telegram)
- Operation: Send Message
- Chat ID: `{{ $json.message.chat.id }}` e clicca l'icona a destra del campo e scegli **Expression** (di default è Fixed e il valore viene inviato come testo letterale)
- Text: `Non conosco il comando {{ $json.message.text }}`

#### Chat ID dinamico

In questo workflow viene usato il **Chat ID dinamico** `{{ $json.message.chat.id }}` nei nodi Telegram Send Message (Nodo D e Nodo 6) - con il Telegram Trigger questo campo è sempre disponibile e corretto.

> Nella guida Docker il Chat ID è fisso (trovato in Parte 3) perché con il polling (`getUpdates`) il Chat ID dinamico non funziona in questo percorso → [guida Docker](../docker/italiano.md)
