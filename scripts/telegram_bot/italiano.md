# Telegram Bot Troubleshoot

Script interattivo per diagnosticare e risolvere i problemi più comuni del bot Telegram usato nei workflow n8n.

## Quando usarlo

- `getUpdates` restituisce sempre `result: []` anche dopo aver mandato un messaggio al bot
- Vuoi verificare che il token sia corretto e il bot risponda
- Sospetti che un webhook o un filtro `allowed_updates` stia bloccando i messaggi

## Requisiti

- Il token del bot Telegram (lo trovi nel file `.env` o da BotFather)
- `curl` e `python3` installati (Linux/macOS) oppure PowerShell (Windows)

## Uso

**Linux / macOS:**

```bash
./troubleshoot.sh <TELEGRAM_TOKEN>
```

**Windows (PowerShell):**

```powershell
.\troubleshoot.ps1 -Token <TELEGRAM_TOKEN>
```

Se non passi il token come argomento, lo script lo chiede interattivamente.

## Menu

| Opzione | Comando API | A cosa serve |
|---------|-------------|--------------|
| 1 | `getMe` | Verifica che il token sia valido e mostra il nome del bot |
| 2 | `getWebhookInfo` | Mostra se c'è un webhook attivo e quali `allowed_updates` sono impostati |
| 3 | `deleteWebhook` | Rimuove il webhook ed elimina gli update in coda |
| 4 | `getUpdates` | Recupera gli ultimi messaggi ricevuti dal bot (offset=-1) |
| 5 | fix `allowed_updates` | Resetta il filtro a `["message"]` - risolve il caso in cui il bot riceve solo update di tipo "poll" |

## Flusso tipico di troubleshooting

1. **Opzione 1** - conferma che il token è giusto e che il nome del bot è quello a cui stai scrivendo
2. **Opzione 2** - controlla `allowed_updates`: se contiene solo `["poll"]`, i messaggi vengono scartati
3. **Opzione 5** - resetta il filtro a `["message"]`
4. **Opzione 2** - verifica che `allowed_updates` ora contenga `["message"]`
5. Manda un messaggio al bot su Telegram
6. **Opzione 4** - verifica che il messaggio arrivi in `result`

## Problema più comune

Se hai usato il nodo **Telegram Trigger** di n8n (anche solo una volta in test), questo può impostare `allowed_updates: ["poll"]` sul bot. Da quel momento `getUpdates` restituisce sempre `result: []` per i messaggi normali. L'opzione 5 dello script risolve questo problema.
