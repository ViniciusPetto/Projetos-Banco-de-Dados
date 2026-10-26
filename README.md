# Projetos-Banco-de-Dados
Repositório criado para armazenamento de projetos de banco de dados criados na Unicamp

# Nexus Imóveis (pendências):
- Mapeamento físico (classe Pessoa) não deve ter atributo tipo em relação a Funcionário (triângulo preenchido);
- Deve existir atributo tipo na relação Pessoa Física <-> Pessoa Jurídica e em relação à Funcionário;
- Na entidade Agendamento, não existe o atributo ID_agendamento, com o ideal sendo ID_locatario e ID_agente sendo PK ao mesmo tempo;
- Colocar os índices junto das respectivas entidades;
- Revisar os índices existentes, existem muitos. Ideal é ter apenas para campos chave das tabelas;
- Ideal deixar chave composta na entidade Reparo: num_reparo e ID_vistoria.

# Nexus Imóveis (dicas):
- Para relatório e consultas, ideal o uso de views ou procedures;
- CRUD: identificar primeiro quais pontos usarão triggers, e o que sobrar utilizará procedure;
- Entrega: procedures devem implementar transactions mais complexas. CRUDs, consultas ou relatórios simples não são importantes para entrega;
- Triggers são mais simples, dando consistência maior que do procedures por evitar transactions;
- Trigger é ideal ter um rollback para cada operação feita e não possui begin nem commit transaction;
- Para fazer triggers, procedure, view, deve-se classificar as transactions (pelo menos 2 operações). 1 operação pode ser considerado muito simples
(ex.: select * from pessoa é uma consulta muito simples sem necessidade de entrega);
- Nem sempre os triggers vão atender ao que é necessário, pois os dados de uma tabela que serão inseridos em outra (via inserted e deleted) podem ter uma
estrutura imcompatível. Por exemplo, nem sempre uma Pessoa é um Agente (campos divergentes entre diferentes pessoas).
