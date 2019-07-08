--CASOS DE EXEMPLO PARA OS TESTES

INSERT INTO funcionario (id, nome, nivel_permissao) VALUES (1, 'Rodolfo', 4),(2, 'Rosislene', 3),(3, 'Mario', 2),(4, 'Andreia', 6),(5, 'Leonardo', 1);
INSERT INTO equipe (id, lider_id) VALUES (1, 1),(2, 1),(3, 4);
INSERT INTO equipes_funcionarios VALUES (1, 1),(2, 1),(3, 1),(1, 2),(2, 2),(4, 3);
INSERT INTO categoria (nome, permissao_assoc) VALUES ('Administrativo', 2),('Vendas', 3),('Confidencial', 6);
INSERT INTO projeto (id, categoria_nome, equipe_id) VALUES (1, 'Administrativo', 1),(2, 'Vendas', 2),(3, 'Vendas', 3);
SELECT * FROM funcionario, equipe, categoria, projeto;

-------- TESTES RESTRIÇÃO 1 --------

-- Aumento da permissão associada a uma categoria
UPDATE categoria SET permissao_assoc = 4 WHERE nome = 'Administrativo';

-- Inserção ou atualização de projeto com categoria cuja permissão seja superior à da equipe
UPDATE projeto SET categoria_nome = 'Vendas' WHERE id = 1;
INSERT INTO projeto (id, categoria_nome, equipe_id) VALUES (4, 'Vendas', 1);

-- Diminuição do nível de permissão de um funcionário
UPDATE funcionario SET nivel_permissao = 1 WHERE id = 2;

-- Atualização em equipe com líder sem permissão para os projetos
UPDATE equipe SET lider_id = 3 WHERE id = 1;

-- Inserção ou atualização de membro da equipe para funcionário sem permissão para os projetos da equipe
INSERT INTO equipes_funcionarios VALUES (3, 2);
UPDATE equipes_funcionarios SET funcionario_id = 3 WHERE funcionario_id = 4;

-------- TESTES RESTRIÇÃO 2 --------

-- Diminuição do nível de permissão de um líder ou aumento do nível de permissão de um funcionário
UPDATE funcionario SET nivel_permissao = 2 WHERE id = 1;
UPDATE funcionario SET nivel_permissao = 5 WHERE id = 2;

-- Alteração do líder da equipe
UPDATE equipe SET lider_id = 2 WHERE id = 1;

-- Alteração ou inserção de membro da equipe com nível de permissão superior ao líder
UPDATE equipes_funcionarios SET funcionario_id = 4 WHERE equipe_id = 1 AND funcionario_id = 2;
INSERT INTO equipes_funcionarios VALUES (4, 1);

-------- TESTES RESTRIÇÃO 2 --------

-- Alteração da permissão associada a uma categoria
UPDATE categoria SET permissao_assoc = 4 WHERE nome = 'Vendas';

-- Inserção ou alteração de projeto
INSERT INTO projeto VALUES (4, 'Administrativo', 3);
UPDATE projeto SET categoria_nome = 'Confidencial' WHERE id = 3;

-- Diminuição no nível de permissão de um funcionário
UPDATE funcionario SET nivel_permissao = 5 WHERE id = 4;

-- Alteração ou remoção em equipes_funcionarios
UPDATE equipes_funcionarios SET funcionario_id = 5 WHERE equipe_id = 2 AND funcionario_id = 2;
DELETE FROM equipes_funcionarios WHERE funcionario_id = 2 AND equipe_id = 2;
