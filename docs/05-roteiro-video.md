# Roteiro do vídeo (até 15 minutos)

| Tempo | Conteúdo e demonstração |
|---|---|
| 00:00–02:00 | Contexto: apresentar o ToggleMaster como API de feature flags. Executar `docker compose up --build`, mostrar `curl http://localhost:5000/health` e criar/listar uma flag. |
| 02:00–04:00 | Explicar o diagrama: VPC `10.0.0.0/16`, subnet pública, EC2, Nginx → Gunicorn e RDS nas duas subnets privadas. Destacar que o RDS é Single-AZ nesta fase. |
| 04:00–07:00 | Tour no console: VPC, subnets e route tables. Mostrar rota pública `0.0.0.0/0 -> IGW` e rotas privadas apenas locais; explicar ausência de NAT Gateway. |
| 07:00–09:00 | Mostrar `sg-app`: 80/443 para Internet e SSH somente do IP `/32`. Mostrar `sg-db`: 5432 com origem `sg-app`, sem CIDR aberto. Mostrar DB Subnet Group e RDS com **Public access: No**. |
| 09:00–11:30 | Na EC2, executar `systemctl status togglemaster nginx`, `journalctl -u togglemaster`. Mostrar apenas `ls -l /etc/togglemaster/app.env` ou `stat` para provar modo 600; não mostrar a senha. |
| 11:30–13:30 | Executar CRUD contra `http://<IP_PUBLICO>`: `GET /health`, POST `/flags`, GET da lista, GET por nome e PUT. Em seguida usar `psql` na EC2 para mostrar a tabela e o registro no RDS. |
| 13:30–14:30 | Relacionar a implantação aos 12 fatores: configuração por ambiente, backing service RDS, logs no journald, processos Gunicorn, port binding e limitações atuais de migrações/paridade. |
| 14:30–15:00 | Encerrar com as decisões: monolito adequado ao MVP, Nginx na frente, SG por referência, duas subnets privadas e ausência de NAT por custo/escopo. Avisar que o ambiente será destruído após a avaliação. |

Antes de gravar, substitua `<IP_PUBLICO>` e use uma flag com nome ainda inexistente. O endpoint `/health` não depende do banco; o CRUD depende da tabela inicializada no RDS.
