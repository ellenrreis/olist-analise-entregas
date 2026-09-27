# Análise dos Drivers do Frete e da Experiência do Cliente (Olist)

## 📋 Descrição
Este projeto analisa características associadas ao valor do frete dos pedidos da Olist e sua relação com a avaliação dos clientes. Também examina tempo de entrega e 
atrasos, além de recortes por peso, categoria de produto e vendedor. As análises foram feitas em SQL (PostgreSQL)

## 🎯 Objetivo
Investigar se pedidos com fretes mais altos apresentam avaliações diferentes e identificar características presentes nas faixas de maior frete. 
O projeto usa análise exploratória para formular hipóteses de negócio; as associações encontradas não estabelecem relações de causa e efeito.


## 🗂️ Base de Dados 
- Fonte: Olist Brazilian E-Commerce Public Dataset (Kaggle)
- Link: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce/data
- Tabelas utilizadas: order_items;customers;sellers;orders;products;order_reviews_dataset

## 🛠️ Pré-requisitos 
- PostgreSQL; ferramenta pgAdmin
- Importação CSVs conforme tabelas utilizadas (vide seção 'Base de Dados')

## 📁 Estrutura do Projeto 
```text
projeto/
├── 01. Criação das Tabelas.sql
├── 02. Qualidade dos Dados.sql
├── 03. Análise Exploratória.sql
├── 04. Insights de Negócios.sql
└── README.md
```

## 🔍 Metodologia / Perguntas Analisadas 
As consultas geradas respondem às seguintes perguntas:
1. Clientes que pagam fretes mais altos atribuem avaliações piores aos pedidos?
2. Existe relação entre o valor do frete e o tempo de entrega do pedido?
3. Existe relação entre o valor do frete e a ocorrência de atrasos nas entregas?
4. Há concentração de determinados vendedores entre os pedidos com maiores fretes?
5. Quais categorias de produtos se relacionam com maiores fretes?
6. Pedidos mais pesados apresentam fretes mais elevados?

## ▶️ Como Executar 
1. Baixe os arquivos CSV do dataset indicado na seção 'Base de dados' deste README
2. Execute o script '01. Criação das Tabelas.sql', que criará as tabelas a serem utilizadas
3. Importe os dados CSV nas tabelas criadas
4. Execute o script '02. Qualidade dos Dados.sql' para consulta sobre a estrutura e consistência dos dados
5. Execute o script '03. Análise Exploratória.sql', que permite entendimento sobre distribuição das informações de frete
6. Execute o script '04. Insights de Negócios.sql', que gera as consultas finais de negócio, para resposta aos questionamentos abordados em 'perguntas analisadas'

### 🔎 Validações e decisões analíticas
1. Valores de frete em pedidos com múltiplos itens
Dos 98.666 pedidos com itens, 9.803 têm mais de um item. Nesse grupo, 7.773 pedidos apresentam o mesmo valor de freight_value em todas as linhas e 2.030 apresentam 
valores diferentes. 
Foram identificados pedidos com múltiplos itens em que freight_value varia entre as linhas. Assim, freight_value não foi interpretado como um único valor de frete do 
pedido repetido em todas as linhas. 
Para fins de validação, foi realizada a verificação da biblioteca do Dataset (Seção Data Card), a qual confirma que freight_value representa o frete atribuído a cada
item. Por isso, o frete total foi calculado pela soma de freight_value das linhas de cada order_id.

2. Discretização dos dados de frete
Os pedidos foram inicialmente divididos em quintis de frete total. Em seguida, foram divididos em decis para observar com mais detalhe as faixas de frete mais alto.

3. Avaliações repetidas
Foram identificados 789 valores de `review_id` que aparecem mais de uma vez. Nesses casos, um mesmo `review_id` não apresenta notas diferentes, mas aparece associado a
 `order_id` distintos. A causa dessa repetição não foi determinada; por isso, não foram excluídas linhas apenas com base no `review_id`.
Também há pedidos com mais de uma linha de avaliação. Para calcular a nota média por decil e a correlação entre frete e nota, foi calculada primeiro a média das 
avaliações de cada pedido. Assim, cada pedido contribui com uma nota para essas análises.

## 📊 Principais Resultados

### Frete e avaliação do cliente
- A correlação entre o frete total do pedido e sua nota foi de -0,089, indicando uma associação linear negativa fraca nesta base.
- Esse resultado, isoladamente, não permite concluir que alterar o preço do frete causaria uma mudança na avaliação do cliente.
- A comparação das notas médias por decil permite observar como as avaliações variam entre faixas de frete, considerando uma nota por pedido.

### Frete e tempo de entrega
- Entre os pedidos entregues, a correlação entre o frete total do pedido e o tempo entre aprovação e entrega foi de 0,164, indicando uma associação linear positiva 
fraca.
- O resultado não permite concluir que pagar um frete maior cause uma entrega mais demorada. Outros fatores do pedido e da logística podem estar associados às duas 
medidas.

### Frete e atrasos
- Entre os pedidos entregues, a correlação entre o frete total e os dias de atraso foi de 0,024, indicando associação linear praticamente nula.
- Essa análise não mostra que o valor do frete, isoladamente, seja um bom indicador da quantidade de dias de atraso. Fatores como distância, vendedor e características
 do produto podem ser investigados em análises futuras; sua influência sobre o atraso não foi medida aqui.

### Características associadas ao valor do frete
- O peso total dos produtos do pedido apresentou correlação positiva de 0,639 com o frete total: nesta base, pedidos mais pesados tendem a ter fretes mais altos.
- A participação de categorias foi calculada sobre os itens de cada decil de frete. A participação dos vendedores foi calculada sobre as associações entre pedidos
 e vendedores de cada decil; um pedido pode estar associado a mais de um vendedor.
- Esses recortes descrevem a composição dos decis. Não permitem, isoladamente, atribuir a um vendedor ou categoria a causa dos fretes mais altos.

O valor do frete apresenta pouca relação com satisfação e atraso; peso é o fator analisado com associação mais forte ao frete; 
portanto, a investigação operacional deve priorizar composição física/logística dos pedidos em vez de assumir que frete alto, 
isoladamente, deteriora a experiência.

## Recomendações de Negócios
- Antes de propor mudanças no preço do frete para melhorar as avaliações, analisar a relação da nota com prazo e atraso de entrega. A associação entre frete e nota 
encontrada neste projeto é fraca e não estabelece um efeito causal.
- Aprofundar a análise dos pedidos mais pesados e com frete mais alto, incluindo dimensões dos produtos e localização de vendedores e clientes. 
Esses recortes podem ajudar a identificar oportunidades logísticas a serem avaliadas.
- Investigar separadamente o efeito de políticas de frete grátis sobre conversão e margem. O dataset e as consultas deste projeto não permitem estimar esse efeito.

## Próximos Passos
Uma análise futura pode investigar a relação de distância, localização dos vendedores e clientes, categoria e características dos produtos com o prazo e o atraso das 
entregas. Esses fatores não foram testados como explicações para os atrasos neste projeto.
A base Olist inclui dados de geolocalização que podem apoiar essa extensão, após o tratamento e a integração com os pedidos. A análise geográfica não faz parte dos 
resultados apresentados aqui.

## 🧰 Tecnologias 
- PostgreSQL
- SQL
- pgAdmin
- Git
- GitHub

## 👤 Autor 
Ellen Reis 
Linkedin: in/ellenrreis
