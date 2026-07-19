# n8n - Workflow automation for everyone

Guides, scripts, and configurations to install and use [n8n](https://n8n.io), the open-source workflow automation tool.

Language: [English](#english) | [Italiano](#italiano)

## English

> Routine? Let n8n handle it.
> Workflow automation for everyone.

Start with the [introduction](guides/intro/english.md): what is n8n, key concepts, how to create the Telegram bot and other specifics needed during the workshop.

Then pick your guide:
- **Business:** [shared server](guides/server/english.md) | [email classification](guides/email/english.md)
- **Developers:** [Docker](guides/docker/english.md) | [RSS + Monitor](guides/rss/english.md)

Once you've built your workflows, you can [download and upload them](guides/download/english.md) to another instance.

## Italiano

> La routine? La facciamo fare a n8n.
> Automazione dei flussi di lavoro per tutti.

Parti dall'[introduzione](guides/intro/italiano.md): cos'è n8n, concetti chiave, come creare il bot Telegram e altre specifiche che serviranno durante il workshop.

Poi scegli la tua guida:
- **Business:** [server condiviso](guides/server/italiano.md) | [classificazione email](guides/email/italiano.md)
- **Developers:** [Docker](guides/docker/italiano.md) | [RSS + Monitor](guides/rss/italiano.md)

Una volta creati i tuoi workflow, puoi [scaricarli e caricarli](guides/download/italiano.md) su un'altra istanza.

## Adepts

### Deploy via aws-docker-host

Hosted deploy through the [aws-docker-host](https://github.com/bilardi/aws-docker-host) Terraform repo: an EC2 host behind an ALB with HTTPS (Route 53 + ACM). This is what the [shared server](guides/server/english.md) guide assumes: the Telegram Trigger node only works on a public HTTPS URL, so a local Docker install cannot use it.

The whole `scripts/` tree is copied into the deploy inputs, so the `docker_installer/` compose file, the custom `Dockerfile` (n8n + Python), `.env`, `n8n-task-runners.json`, and the `workflow5/6/7` folders it bind-mounts all ship together.

Run the steps below assuming `aws-docker-host` is a sibling directory (`../aws-docker-host`).

```sh
# 0. deploy-specific values (replace with your own)
export AWS_PROFILE=mine  # AWS profile terraform uses to provision the host
HOST=n8n.workshop.pandle.net  # subdomain + domain_name from terraform.tfvars

# 1. copy the project scripts into aws-docker-host inputs (keeps .env, not .env.sample)
cp -rf scripts/* ../aws-docker-host/inputs/

# 2. set the public URL BEFORE copying, so webhooks (Telegram Trigger)
#    register with the HTTPS host instead of localhost
cd ../aws-docker-host
sed -i "s|^WEBHOOK_URL=.*|WEBHOOK_URL=https://$HOST|" inputs/docker_installer/.env

# 3. prepare the terraform variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Set these values in `terraform/terraform.tfvars` (the compose file is in a subfolder of `inputs/`, and n8n serves its health check on `/healthz`):

```hcl
domain_name      = "workshop.pandle.net"
subdomain        = "n8n"
container_port   = 5678
healthcheck_path = "/healthz"
compose_path     = "docker_installer"
```

```sh
# 4. provision the host
cd terraform
terraform init
terraform apply
terraform output nameservers  # add these as NS records on your DNS provider
terraform output url  # https://n8n.workshop.pandle.net
```

Workarounds:

- **Encryption key**: keep `N8N_ENCRYPTION_KEY` in `.env` stable across redeploys; aws-docker-host restores the `n8n_data` volume from S3, but a changed key makes saved credentials undecryptable
- **Bind-mount paths**: the compose mounts `../../downloads` and `../../workspace` relative to `docker_installer/`; on the host these resolve outside the app dir and Docker creates them empty as root. To mount real content set `DOWNLOADS_PATH` / `WORKSPACE_PATH` to absolute host paths in `.env`
- **502 Bad Gateway** with `sudo docker ps -a` showing no containers means the build or first boot failed: check `sudo cat /var/log/user-data.log` on the host

Operational commands:

```sh
# open a shell on the host via SSM (no SSH)
aws ssm start-session --target "$(cd ../aws-docker-host/terraform && terraform output -raw instance_id)"

# on the host, restart n8n after a config-only change (.env)
cd /opt/app/docker_installer && sudo docker compose up -d --force-recreate n8n

# on the host, follow the logs
cd /opt/app/docker_installer && sudo docker compose logs -f n8n

# tear everything down (backs up volumes to S3 first)
cd ../aws-docker-host && bash scripts/destroy.sh
```

## License

This repo is released under the MIT license. See [LICENSE](LICENSE) for details.
