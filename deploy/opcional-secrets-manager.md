# Variação opcional: AWS Secrets Manager

Nesta variação, a senha não fica em `/etc/togglemaster/app.env`. Crie o RDS com senha gerenciada pelo AWS Secrets Manager (ou armazene a senha em um segredo dedicado) e associe à EC2 um instance profile com a permissão mínima abaixo. O exemplo pressupõe um segredo JSON com a chave `password` e que `DB_HOST`, `DB_NAME` e `DB_USER` continuam no `app.env`.

## Policy mínima

Substitua a região, conta e nome pelo ARN real; não use `Resource: "*"`.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:us-east-1:<ACCOUNT_ID>:secret:togglemaster/rds-<SUFIXO>"
    }
  ]
}
```

No AWS Academy, a associação de policy e instance profile depende das permissões fornecidas pela `LabRole`. Se a conta não permitir essa alteração, use a alternativa documentada no bootstrap e proteja o arquivo com `root:root` e modo 600.

## ExecStartPre

Instale AWS CLI e `jq` conforme os pacotes disponíveis na AMI e crie `/usr/local/sbin/togglemaster-secret-env` como `root:root`, modo 700:

```bash
#!/usr/bin/env bash
set -euo pipefail
SECRET_ARN='arn:aws:secretsmanager:us-east-1:<ACCOUNT_ID>:secret:togglemaster/rds-<SUFIXO>'
password="$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ARN" \
  --query SecretString --output text | jq -r '.password')"
test -n "$password" && test "$password" != "null"
install -d -m 755 /run/togglemaster
printf 'DB_PASSWORD=%q\n' "$password" > /run/togglemaster/app.env
chmod 600 /run/togglemaster/app.env
```

Altere a unit para carregar os dois arquivos:

```ini
EnvironmentFile=/etc/togglemaster/app.env
EnvironmentFile=/run/togglemaster/app.env
ExecStartPre=/usr/local/sbin/togglemaster-secret-env
```

O segredo é buscado antes de cada início/reinício. Rotação exige reiniciar o serviço após a rotação (ou implementar um mecanismo de reload); não imprima o conteúdo do segredo no journal.
