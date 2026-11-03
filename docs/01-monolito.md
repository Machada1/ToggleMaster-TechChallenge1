# ToggleMaster como monolito

## Classificação

O ToggleMaster é um monolito porque a API HTTP, as regras de validação e o acesso ao banco são executados no mesmo processo Python e entregues como um único artefato. Em [`app.py`](../app.py), a aplicação Flask é criada na linha 7; as rotas CRUD ficam no mesmo módulo (linhas 49–140), e a conexão PostgreSQL é aberta diretamente pela função `get_db_connection` (linhas 14–21). As funções das rotas também executam SQL diretamente, por exemplo o `INSERT` nas linhas 62–66 e o `UPDATE` nas linhas 123–131.

O modelo de dados é um banco PostgreSQL único. A tabela `flags` é criada pelo comando `init-db` em [`app.py`](../app.py#L23), e o [`entrypoint.sh`](../entrypoint.sh#L29) executa esse comando antes de iniciar o Gunicorn. O [`Dockerfile`](../Dockerfile) empacota a aplicação em uma imagem única, enquanto o [`docker-compose.yaml`](../docker-compose.yaml) a executa como um único serviço `app` (com um serviço de banco separado para desenvolvimento).

Assim, a unidade de deploy e de escalabilidade é o conjunto inteiro da aplicação: pode-se aumentar o tamanho da EC2 (escala vertical) ou replicar a aplicação inteira atrás de um balanceador (escala horizontal), mas não escalar API, regras e persistência de forma independente. O banco continua sendo um ponto compartilhado.

## Vantagens para um MVP

- **Baixa complexidade operacional:** um repositório, um processo e uma unidade de deploy reduzem o esforço inicial.
- **Entrega rápida:** Flask, Gunicorn e PostgreSQL já cobrem o CRUD previsto; `requirements.txt` fixa as quatro dependências diretas.
- **Transações simples:** cada operação abre uma conexão, executa seu SQL e fecha a conexão, como ocorre no POST (linhas 62–75).
- **Depuração direta:** logs e erros da API podem ser acompanhados junto ao serviço da aplicação.
- **Custo inicial menor:** uma EC2 pode hospedar a aplicação sem introduzir múltiplos serviços de computação.

## Desvantagens para um MVP

- **Acoplamento:** alteração de uma rota exige publicar o mesmo artefato que contém toda a API.
- **Escala grosseira:** endpoints com cargas diferentes consomem a mesma capacidade do processo e da instância.
- **Falha compartilhada:** problema no processo ou na instância afeta todos os endpoints.
- **Evolução de banco sensível:** a criação de tabela é um passo de inicialização (`flask init-db`), não um sistema de migrações versionadas.
- **Limites de robustez:** não há pool de conexões, autenticação, autorização ou validação de domínio além dos campos básicos visíveis nas rotas.

Esses pontos são observações do código atual, não afirmações de funcionalidades ausentes: o escopo do MVP implementado é o CRUD de flags e o endpoint `/health`.

## Evolução prevista

Nas próximas fases, a API poderia ser separada de um serviço de avaliação/consulta de flags e de um componente de administração. Um serviço de persistência/migrações poderia encapsular o acesso ao PostgreSQL, enquanto um gateway ou balanceador trataria TLS, autenticação e roteamento. A decomposição deve ser guiada por carga, limites de domínio e necessidade de deploy independente; não é necessária para o MVP atual.
