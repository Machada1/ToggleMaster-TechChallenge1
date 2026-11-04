# Entrega — ToggleMaster Tech Challenge Fase 1

## Participante

- Guilherme Henrique de Lima Machado — RM rm377999

## Links

- Repositório e documentação: [Machada1/ToggleMaster-TechChallenge1](https://github.com/Machada1/ToggleMaster-TechChallenge1)
- Diagrama draw.io: [docs/arquitetura.drawio](./docs/arquitetura.drawio)
- Diagrama Mermaid: [docs/arquitetura.md](./docs/arquitetura.md)
- Infraestrutura como código Terraform: [terraform/](./terraform/)

## Resumo

O ToggleMaster foi implantado como um monolito Flask servido por Gunicorn em uma EC2 na subnet pública, com Nginx como reverse proxy. O PostgreSQL foi externalizado para um RDS em subnets privadas, sem acesso público.

## Decisões arquiteturais

- Manter o monolito no MVP para reduzir complexidade e acelerar a entrega.
- Usar uma VPC `10.0.0.0/16`, com EC2 em `10.0.1.0/24` e RDS em um DB Subnet Group composto por `10.0.11.0/24` e `10.0.12.0/24`.
- Usar Internet Gateway para a subnet pública e não criar NAT Gateway, evitando custo recorrente desnecessário para este escopo.
- Restringir SSH ao IP administrativo `/32`, publicar 80/443 no `sg-app` e permitir 5432 no `sg-db` somente por referência ao `sg-app`.
- Manter o RDS sem acesso público e usar Nginx na frente do Gunicorn, deixando o Gunicorn em `127.0.0.1:5000`.
- Inicializar a tabela `flags` com o comando `flask init-db` depois que o RDS estiver pronto.

## Desafios encontrados

1. A primeira execução do bootstrap encontrou a proteção do Git contra o diretório `/opt/togglemaster` com propriedade diferente da identidade executora. A implantação foi regularizada com a configuração explícita de `safe.directory` e a execução administrativa do `git pull`.
2. O arquivo de ambiente precisou ser corrigido para tratar caracteres especiais da senha do PostgreSQL sem que o shell os interpretasse como comandos. O arquivo final foi protegido com proprietário `root`, grupo `root` e modo `600`.
3. O RDS foi recriado com o DB Subnet Group privado e o Security Group `secg-db`, cuja porta TCP 5432 aceita tráfego somente do `secg-app`. A conectividade foi comprovada pela EC2 com `psql`.
4. A tela do AWS Academy não apresentou todas as opções de conectividade no fluxo de criação do PostgreSQL. A configuração final foi validada por AWS CLI e pelos testes da aplicação.

## Estimativa de custos

Para a arquitetura observada em `us-east-1`, a estimativa mensal de referência é **US$ 26,18**, antes de impostos, créditos e benefícios do Free Tier/AWS Academy. O detalhamento está em [docs/04-estimativa-custos.md](./docs/04-estimativa-custos.md).

Premissas principais:

- EC2 Linux `t3.micro`, 730 horas;
- EBS gp3 de referência com 12 GiB;
- RDS PostgreSQL `db.t4g.micro`, Single-AZ, 20 GiB gp2;
- um IPv4 público;
- 1 GiB/mês de saída;
- ausência de NAT Gateway.
