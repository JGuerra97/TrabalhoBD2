/*FUNÇÃO: retornar uma lista de sugestões, dado um nível desejado.
A ideia é que se procure todos os funcionários que possam participar de uma equipe com um nível passado,
considerando que existe um limite de participações e que os funcionários mais disponíveis e com nível mais baixo devem aparecer primeiro.*/

DROP FUNCTION IF EXISTS sugestoes_nova_equipe_projeto;
CREATE OR REPLACE FUNCTION sugestoes_nova_equipe_projeto(permissao_desejada INTEGER, limite_projetos INTEGER) RETURNS TABLE(id INTEGER, nome VARCHAR(30), no_projetos BIGINT, nivel_permissao INTEGER) AS $$
	BEGIN
		RETURN QUERY WITH t1 AS (SELECT funcionario.id, funcionario.nome, count(projeto.id) AS no_projetos, funcionario.nivel_permissao
								FROM projeto
								JOIN equipe ON projeto.equipe_id = equipe.id
								JOIN equipes_funcionarios ON equipe.id = equipes_funcionarios.equipe_id
								JOIN funcionario ON equipes_funcionarios.funcionario_id = funcionario.id
								WHERE funcionario.nivel_permissao >= permissao_desejada
								GROUP BY funcionario.id)
							SELECT * FROM t1 WHERE t1.no_projetos < limite_projetos ORDER BY t1.no_projetos ASC, nivel_permissao ASC;
	END;
$$ LANGUAGE plpgsql;

--Utilização: 
--SELECT * FROM sugestoes_nova_equipe_projeto(<permissao desejada>, <limite de projetos>);