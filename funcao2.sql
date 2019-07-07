/*FUNÇÃO: retornar uma tabela com a relação de cada funcionario para cada equipe, informando seu cargo.
A ideia é que se faça uma multiplicação cartesiana entre cada funcionario e cada equipe, informando se o funcionário é o Lider, Membro ou Não participa.*/

DROP FUNCTION IF EXISTS relatorio_funcionario_equipe;
CREATE OR REPLACE FUNCTION relatorio_funcionario_equipe()
	RETURNS TABLE(equipe INTEGER, funcionario VARCHAR(30), cargo VARCHAR(15)) AS $$
	DECLARE
		cursorFuncionarioEquipe CURSOR FOR
			SELECT equipe.id AS eq_id,
				   equipe.lider_id AS eq_lider_id,
				   funcionario.id AS func_id,
				   funcionario.nome AS func_nome,
				   funcionario.nivel_permissao AS func_permissao,
				   equipes_funcionarios.equipe_id AS eq_func_eq_id,
				   equipes_funcionarios.funcionario_id AS eq_func_func_id
				FROM equipe
				CROSS JOIN funcionario
				JOIN equipes_funcionarios
				ON equipes_funcionarios.funcionario_id = funcionario.id; 
	BEGIN
		DROP TABLE IF EXISTS log_funcionarios_equipes;
		CREATE TEMPORARY TABLE log_funcionarios_equipes ( --criando tabela que será retornada como resposta
			equipe INTEGER,
			funcionario VARCHAR(30),
			cargo VARCHAR(15),
			PRIMARY KEY (funcionario, equipe)		
		);
		FOR linha IN cursorFuncionarioEquipe LOOP
			IF linha.eq_lider_id = linha.func_id THEN --se o funcionário é lider
				INSERT INTO log_funcionarios_equipes VALUES
					(linha.eq_id, concat(linha.func_nome, ' (', linha.func_id, ')'), 'Líder');
			ELSIF linha.eq_id = linha.eq_func_eq_id THEN --se o funcionário é parte da equipe e não é lider
				INSERT INTO log_funcionarios_equipes VALUES
					(linha.eq_id, concat(linha.func_nome, ' (', linha.func_id, ')'), 'Membro'); 
			ELSE
				INSERT INTO log_funcionarios_equipes VALUES
				(linha.eq_id, concat(linha.func_nome, ' (', linha.func_id, ')'), 'Não participa');
			END IF;
		END LOOP;
		RETURN QUERY SELECT * FROM log_funcionarios_equipes ORDER BY equipe;
	END;
$$ LANGUAGE plpgsql;

--Utilização:
--SELECT * FROM relatorio_funcionario_equipe();