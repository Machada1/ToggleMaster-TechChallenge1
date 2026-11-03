# Estimativa de custos

Preencha os valores abaixo com o resultado real da **AWS Pricing Calculator**, região `us-east-1`. Os campos permanecem deliberadamente como `<valor>`.

- **EC2:** `t3.micro`, On-Demand, 730 h/mês: `<valor>`.
- **EBS:** volume raiz gp3 (capacidade e IOPS/throughput informados pela configuração): `<valor>`.
- **RDS PostgreSQL:** `db.t3.micro`, Single-AZ, 730 h/mês: `<valor>`.
- **Armazenamento RDS:** 20 GB gp3: `<valor>`.
- **Backup RDS:** armazenamento/backup previsto na calculadora: `<valor>`.
- **IPv4 público:** endereço público associado à EC2, conforme a cobrança vigente: `<valor>`.
- **Data transfer out:** estimativa mensal de saída para Internet: `<valor>`.
- **Total mensal estimado:** `<valor>`.

O Free Tier pode reduzir ou zerar parte do consumo elegível, dependendo da idade da conta, região, tipo de recurso e limites vigentes. Confirme a elegibilidade na conta AWS Academy/Free Tier antes de concluir. Não use o Free Tier como garantia de custo zero.

Não há NAT Gateway nesta arquitetura: como ele cobra por hora e por processamento de dados, manter apenas o IGW e o acesso de saída da EC2 pública evita esse custo recorrente. Isso é uma decisão condicionada ao escopo; uma arquitetura de EC2 privada exigiria um caminho de saída controlado.
