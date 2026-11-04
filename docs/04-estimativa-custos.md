# Estimativa de custos

## Cenário observado

Esta é uma **estimativa indicativa**, não uma fatura nem um resultado exportado da AWS Pricing Calculator. Ela usa os recursos observados na implantação em `us-east-1`:

- EC2 Linux `t3.micro`, On-Demand, 730 h/mês;
- volume raiz EBS gp3 de referência de 12 GiB;
- RDS PostgreSQL `db.t4g.micro`, Single-AZ, 730 h/mês;
- RDS com 20 GiB de armazenamento gp2;
- um IPv4 público em uso;
- tráfego de saída estimado em 1 GiB/mês;
- sem NAT Gateway.

Os valores abaixo são uma referência acadêmica para a arquitetura implantada. Preços, impostos, Free Tier e condições do AWS Academy podem alterar o resultado final da cobrança.

## Cálculo mensal de referência

| Item | Premissa | Valor unitário de referência | Cálculo mensal | Estimativa |
|---|---|---:|---:|---:|
| EC2 | Linux `t3.micro`, 730 h | US$ 0,0104/h | 730 × 0,0104 | **US$ 7,59** |
| EBS | gp3, 12 GiB | US$ 0,08/GiB-mês | 12 × 0,08 | **US$ 0,96** |
| RDS | PostgreSQL `db.t4g.micro`, 730 h | US$ 0,016/h | 730 × 0,016 | **US$ 11,68** |
| Armazenamento RDS | gp2, 20 GiB | US$ 0,115/GiB-mês | 20 × 0,115 | **US$ 2,30** |
| Backup RDS | dentro do armazenamento alocado, sem snapshots adicionais | — | premissa | **US$ 0,00** |
| IPv4 público | 1 endereço em uso, 730 h | US$ 0,005/h | 730 × 0,005 | **US$ 3,65** |
| Data transfer out | 1 GiB/mês | dentro da franquia agregada de 100 GiB, se elegível | 1 × 0 | **US$ 0,00** |
| **Total de referência** | antes de impostos e créditos | — | soma dos itens | **US$ 26,18/mês** |

O volume EBS deve ser ajustado se a saída da CLI ou o console mostrar outra capacidade. O RDS observado nas telas usa `db.t4g.micro` e gp2; não substitua por `db.t3.micro`/gp3 no relatório final se esses não forem os recursos efetivamente criados.

O Free Tier pode reduzir ou zerar parte do consumo elegível, dependendo da idade da conta, região, tipo de recurso e limites vigentes. Confirme a elegibilidade na conta AWS Academy/Free Tier antes de concluir. Não use o Free Tier como garantia de custo zero. O valor calculado acima é bruto e não desconta créditos.

Não há NAT Gateway nesta arquitetura: como ele cobra por hora e por processamento de dados, manter apenas o IGW e o acesso de saída da EC2 pública evita esse custo recorrente. Isso é uma decisão condicionada ao escopo; uma arquitetura de EC2 privada exigiria um caminho de saída controlado.
