# Runbook: implantação manual no console AWS

Valores entre `<...>` são preenchidos durante a execução. Use a região **us-east-1** em todos os recursos.

> **Alternativa automatizada:** a pasta [`terraform/`](../terraform/) contém a mesma infraestrutura como código, incluindo VPC, EC2, RDS, SGs, Secrets Manager e user data. Este runbook permanece como o procedimento manual exigido/útil para validação no console.

## 1. Rede

1. Em **VPC > Your VPCs**, crie uma VPC `togglemaster-vpc`, CIDR `10.0.0.0/16`, com DNS hostnames e DNS resolution habilitados.
2. Crie as subnets:
   - `togglemaster-public-a`, `10.0.1.0/24`, AZ `us-east-1a`, com auto-assign public IPv4 habilitado.
   - `togglemaster-private-a`, `10.0.11.0/24`, AZ `us-east-1a`.
   - `togglemaster-private-b`, `10.0.12.0/24`, AZ `us-east-1b`.
3. Crie um Internet Gateway `togglemaster-igw`, anexe-o à VPC e crie a route table pública. Associe-a à subnet pública e adicione `0.0.0.0/0 -> Internet Gateway`. As subnets privadas permanecem com apenas a rota local; não crie NAT Gateway nesta fase.

## 2. Segurança e banco

1. Crie `sg-app` na VPC. Inbound: TCP 80 de `0.0.0.0/0`, TCP 443 de `0.0.0.0/0` e TCP 22 somente de `<MEU_IP>/32`. Não abra 5000.
2. Crie `sg-db` na mesma VPC. Inbound: TCP 5432 com **Source = sg-app** (referência ao security group, não CIDR). Sem acesso público.
3. Em **RDS > Subnet groups**, crie `togglemaster-db-subnet-group` com a VPC e as duas subnets privadas.
4. Em **RDS > Databases**, crie PostgreSQL, template compatível com o laboratório/Free Tier, `db.t4g.micro`, Single-AZ, banco inicial `togglemaster`, usuário `<DB_USER>`, senha forte temporária e armazenamento gp2 de 20 GiB. Desabilite **Public access** e associe `sg-db`. Aguarde o status `Available` e copie o endpoint privado.

## 3. EC2 e instalação

1. Crie um key pair e guarde o `.pem` fora do repositório, com permissão local 400.
2. Lance Amazon Linux 2023 `t3.micro`, na subnet pública, com auto-assign public IP, `sg-app` e o key pair.
3. Conecte por SSH:

   ```bash
   chmod 400 <ARQUIVO>.pem
   ssh -i <ARQUIVO>.pem ec2-user@<IP_PUBLICO>
   ```

4. Na EC2, obtenha o código e execute o bootstrap (o script instala `git`, Python, Nginx e cliente PostgreSQL):

   ```bash
   git clone <URL_DO_REPOSITORIO_GIT>
   cd toggle-master-monolith
   sudo REPO_URL=<URL_DO_REPOSITORIO_GIT> bash deploy/bootstrap-ec2.sh
   ```

5. Edite o arquivo protegido e **não mostre a senha na gravação**:

   ```bash
   sudo vi /etc/togglemaster/app.env
   sudo chmod 600 /etc/togglemaster/app.env
   sudo systemctl restart togglemaster
   ```

O bootstrap aguarda `pg_isready` e executa `FLASK_APP=app.py flask init-db`. Isso reproduz o passo do [`entrypoint.sh`](../entrypoint.sh#L29), que cria a tabela `flags` antes de iniciar o Gunicorn. A própria aplicação lê as quatro variáveis no [`app.py`](../app.py#L9-L12).

## 4. Validação

Na sua máquina:

```bash
curl http://<IP_PUBLICO>/health
curl -X POST http://<IP_PUBLICO>/flags \
  -H 'Content-Type: application/json' \
  -d '{"name":"video-demo","is_enabled":true}'
curl http://<IP_PUBLICO>/flags
curl http://<IP_PUBLICO>/flags/video-demo
curl -X PUT http://<IP_PUBLICO>/flags/video-demo \
  -H 'Content-Type: application/json' \
  -d '{"is_enabled":false}'
curl http://<IP_PUBLICO>/flags/video-demo
```

Na EC2, prove a persistência no RDS. O cliente pede a senha interativamente para evitar deixá-la no histórico:

```bash
psql -h <ENDPOINT_RDS> -U <DB_USER> -d togglemaster -W \
  -c '\dt' \
  -c 'SELECT id, name, is_enabled, created_at FROM flags ORDER BY id;'
```

O RDS não deve ser acessível da sua máquina: teste `nc -vz -w 5 <ENDPOINT_RDS> 5432` ou `psql` a partir do seu computador. O resultado esperado é timeout/recusa, pois o RDS é privado e `sg-db` aceita somente `sg-app`. O teste positivo de PostgreSQL deve ocorrer na EC2.

## 5. Troubleshooting

- **Timeout na 5432:** confira que o RDS está nas duas subnets do DB Subnet Group, que `sg-db` referencia `sg-app`, que a EC2 usa `sg-app` e que o endpoint/usuário/banco no `app.env` estão corretos.
- **502 no Nginx:** execute `sudo systemctl status togglemaster nginx`, `sudo journalctl -u togglemaster -n 100 --no-pager` e `curl http://127.0.0.1:5000/health`. Verifique também `nginx -t`.
- **SSH recusado:** confirme que a regra 22 usa o IP público atual da sua máquina, que a instância está `running`, que o key pair é o correto e que o IP público da EC2 não mudou.

## 6. Teardown para evitar custo residual

1. Remova a EC2 (e o volume EBS associado, se não precisar do snapshot).
2. Remova o RDS e escolha não criar snapshot final quando autorizado pelo trabalho; apague snapshots manuais não necessários.
3. Remova o DB Subnet Group.
4. Remova regras/SGs não usados.
5. Remova associações das route tables e depois as route tables extras.
6. Desanexe e exclua o Internet Gateway.
7. Exclua as subnets e por fim a VPC.
8. Libere IPv4 elástico, se algum tiver sido alocado, e remova o key pair somente se não for reutilizado.

Confirme em **Billing/Cost Explorer** que não restaram recursos na região.
