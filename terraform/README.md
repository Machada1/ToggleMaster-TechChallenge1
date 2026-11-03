# Infraestrutura AWS com Terraform

Esta pasta provisiona a arquitetura completa do ToggleMaster:

- VPC `10.0.0.0/16`;
- subnet pública `10.0.1.0/24` em `us-east-1a`;
- subnets privadas `10.0.11.0/24` e `10.0.12.0/24`;
- Internet Gateway e route table pública com `0.0.0.0/0`;
- route tables privadas sem NAT Gateway, apenas a rota local;
- `sg-app` com 80/443 públicos e SSH restrito a `admin_cidr`;
- `sg-db` com 5432 somente a partir do `sg-app`;
- RDS PostgreSQL 15 `db.t3.micro`, Single-AZ, 20 GiB gp3, sem acesso público;
- DB Subnet Group;
- EC2 Amazon Linux 2023 `t3.micro`, EBS gp3 e Elastic IP;
- IAM Instance Profile com somente `secretsmanager:GetSecretValue` no segredo específico;
- Secrets Manager para a senha do RDS;
- user data que instala AWS CLI/jq, recupera o segredo, cria `app.env` e executa [`deploy/bootstrap-ec2.sh`](../deploy/bootstrap-ec2.sh).

## Pré-requisitos

1. Terraform >= 1.5.
2. Credenciais AWS válidas, normalmente as credenciais temporárias da sessão do AWS Academy.
3. Um key pair já criado na região escolhida.
4. Um repositório acessível pela EC2 contendo o projeto e a pasta `deploy`.
5. Permissões da conta para VPC, EC2, RDS, IAM Instance Profile e Secrets Manager. No AWS Academy, a `LabRole` pode restringir IAM/Secrets Manager.

## Uso

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

O arquivo `terraform.tfvars` e o estado local podem conter informações sensíveis. Não os versionar. Depois do `apply`, aguarde a execução do user data e valide:

```bash
curl http://$(terraform output -raw public_ip)/health
ssh -i <KEY>.pem ec2-user@$(terraform output -raw public_ip)
sudo systemctl status togglemaster nginx
sudo journalctl -u togglemaster -n 100 --no-pager
```

O `terraform apply` aguarda o RDS ficar disponível antes de criar a EC2. A inicialização da tabela `flags` ocorre no bootstrap com `flask init-db`, tal como no [`entrypoint.sh`](../entrypoint.sh).

## Destruição

Para o laboratório:

```bash
terraform destroy
```

Com `skip_final_snapshot = true`, a destruição não cria snapshot final. Para um ambiente que precise preservar dados, defina `skip_final_snapshot = false`, desabilite `deletion_protection` somente quando autorizado e informe um identificador de snapshot final conforme a política da equipe.

Não execute Terraform contra recursos criados manualmente com os mesmos nomes: ele tentará criar recursos duplicados. Para assumir recursos existentes, seria necessário importá-los para o state (`terraform import`) e revisar o plano.
