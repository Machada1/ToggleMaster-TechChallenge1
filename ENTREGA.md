# Entrega — ToggleMaster Tech Challenge Fase 1

## Participantes

- `<NOME COMPLETO 1> — <RM>`
- `<NOME COMPLETO 2> — <RM>`
- `<NOME COMPLETO 3> — <RM>`

## Links

- Vídeo (até 15 minutos): `<LINK_DO_VIDEO>`
- Diagrama draw.io/Mermaid: `<LINK_DO_DIAGRAMA>`
- Repositório e documentação: `<LINK_DO_REPOSITORIO>`
- Infraestrutura como código Terraform: [`terraform/`](./terraform/)

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

1. `<DESCREVA o desafio de rede/SG e como foi resolvido>`
2. `<DESCREVA o desafio de instalação/bootstrap>`
3. `<DESCREVA o desafio de validação/persistência>`

## Estimativa de custos

Cole aqui o print da AWS Pricing Calculator para `us-east-1`:

`<INSIRA O PRINT OU LINK DA ESTIMATIVA>`

Total calculado: `<valor>`.
