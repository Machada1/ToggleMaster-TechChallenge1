# Avaliação 12-Factor

| Fator | Status | Evidência no código ou repositório | Ajuste necessário para produção |
|---|---|---|---|
| 1. Codebase | Atende | Há um repositório e um código-fonte único; o README orienta `git clone`. | Usar fluxo de branches, revisão e tags/releases. |
| 2. Dependências | Parcial | [`requirements.txt`](../requirements.txt) fixa Flask, Werkzeug, psycopg2-binary e Gunicorn, mas o sistema também depende de `git`, `pg_isready`, Nginx e PostgreSQL client instalados fora do arquivo. | Fixar/gerenciar também a imagem/OS e validar dependências transitivas; considerar lockfile. |
| 3. Configuração | Parcial | [`app.py`](../app.py#L9) lê `DB_HOST`, `DB_NAME`, `DB_USER` e `DB_PASSWORD` do ambiente; o Compose também define `DB_PORT`. | Manter segredos fora do repositório, usar Secrets Manager/IAM e validar variáveis obrigatórias no startup. |
| 4. Backing services | Atende | O PostgreSQL é um serviço externo à aplicação: Compose usa o serviço `db` e o deploy usa RDS. | Tratar RDS como recurso substituível, com backup, monitoramento e migrações versionadas. |
| 5. Build, release, run | Parcial | O [`Dockerfile`](../Dockerfile) faz build e o Compose executa; no EC2 o bootstrap instala dependências e o systemd executa Gunicorn. Não há release imutável nem pipeline. | Produzir artefato versionado, separar build/release/run e registrar a versão implantada. |
| 6. Processos | Atende | Gunicorn é o processo web; o serviço systemd usa workers e não depende da sessão SSH. | Dimensionar workers, timeouts e limites; não armazenar estado em memória. |
| 7. Port binding | Atende | [`Dockerfile`](../Dockerfile#L22) expõe 5000 e o Gunicorn escuta nessa porta; Nginx fará a publicação na 80. | Publicar somente Nginx e manter Gunicorn em loopback; adicionar TLS. |
| 8. Concorrência | Parcial | Gunicorn permite dois workers no unit proposto, mas não há política de escala documentada. | Dimensionar workers por CPU/memória e usar múltiplas instâncias quando necessário. |
| 9. Disposability | Parcial | O `entrypoint.sh` usa `exec` para entregar sinais ao Gunicorn; o systemd reinicia em falha. Não há configuração explícita de graceful timeout/stop. | Definir `TimeoutStopSec`, graceful timeout do Gunicorn e health checks. |
| 10. Dev/prod parity | Parcial | Compose usa PostgreSQL 13, volume e app na porta 5000; produção usa RDS, Nginx, systemd e rede AWS. | Aproximar versões/configuração e automatizar validação em ambiente equivalente. |
| 11. Logs | Parcial | [`app.py`](../app.py#L24) usa `print` na inicialização e a API retorna detalhes de exceção; o systemd encaminha stdout/stderr ao journald. | Estruturar logs em stdout/journald, remover detalhes sensíveis das respostas e centralizar retenção/alertas. |
| 12. Admin processes | Parcial | `flask init-db` cria `flags` com `CREATE TABLE IF NOT EXISTS` em [`app.py`](../app.py#L23-L47), acionado no entrypoint. | Usar migrações versionadas, executadas como job controlado, separado do boot de cada worker. |

## Cinco ajustes prioritários

1. **Segredos:** migrar `DB_PASSWORD` para Secrets Manager (ou mecanismo equivalente) e restringir IAM.
2. **Migrações:** substituir `init-db` por migrações versionadas e observáveis.
3. **HTTPS e exposição:** terminar TLS no Nginx/ALB e publicar apenas 80/443, mantendo 5000 privado.
4. **Observabilidade:** logs estruturados, métricas, alarmes e remoção de detalhes de exceção nas respostas.
5. **Entrega reproduzível:** pipeline com artefato/versionamento, paridade de versões e rollback.
