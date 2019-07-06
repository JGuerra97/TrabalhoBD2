/*
REGRA: Uma equipe não pode pegar mais de um projeto cuja permissao associada à categoria seja igual à permissão 
		da equipe (que é a menor permissão entre os funcionários da equipe).
TABELAS ASSOCIADAS:
	-categoria (permissao_assoc)
	-projeto (categoria ou equipe)
	-equipe (lider)
	-funcionario (permissao)
	-equipes_funcionarios (equipe ou funcionario)
*/

CREATE OR REPLACE FUNCTION verifica_se_equipe_ja_possui_projeto_no_limite_da_permissao(id_equipe INTEGER)
RETURNS boolean AS $$
	DECLARE
		quantidade_projetos_limite_permissao INTEGER;
		permissao_equipe INTEGER;
	BEGIN
		SELECT min(nivel_permissao)
			FROM funcionario
			JOIN equipes_funcionarios ON funcionario.id = equipes_funcionarios.funcionario_id
			WHERE equipes_funcionarios.equipe_id = id_equipe
			GROUP BY equipes_funcionarios.equipe_id
			INTO permissao_equipe;
		SELECT count(*)
			FROM projeto
			JOIN categoria ON projeto.categoria_nome = categoria.nome
			WHERE projeto.equipe_id = id_equipe AND
			categoria.permissao_assoc = permissao_equipe
			INTO quantidade_projetos_limite_permissao;
		IF quantidade_projetos_limite_permissao <= 1 THEN
			RETURN FALSE;
		ELSE
			RETURN TRUE;
		END IF;
	END;
$$ LANGUAGE plpgsql;


--verifica alteração em categoria
CREATE OR REPLACE FUNCTION altera_categoria_restricao_tres_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1Restricao3 CURSOR FOR --recupera todas as equipes com projetos nesta categoria
			SELECT equipe.id
			FROM equipe
			JOIN projeto ON projeto.equipe_id = equipe.id
			JOIN categoria ON projeto.categoria_nome = categoria.nome
			WHERE categoria.nome = NEW.nome;
		permissao_equipe INTEGER;
	BEGIN
		FOR equipe_linha IN cursor1Restricao3 LOOP
			SELECT min(nivel_permissao) AS permissao
				FROM funcionario
				JOIN equipes_funcionarios ON funcionario.id = equipes_funcionarios.funcionario_id
				WHERE equipes_funcionarios.equipe_id = equipe_linha.id
				GROUP BY equipes_funcionarios.equipe_id
				INTO permissao_equipe;
			IF NEW.permissao_assoc = permissao_equipe THEN
				IF verifica_se_equipe_ja_possui_projeto_no_limite_da_permissao(equipe_linha.id) THEN
					RAISE EXCEPTION 'Uma equipe só pode ter um projeto cuja permissão associada a sua categoria seja igual à permissão da equipe.';
				END IF;
			END IF;
		END LOOP;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

DROP TRIGGER altera_categoria_restricao_tres ON categoria;
CREATE TRIGGER altera_categoria_restricao_tres BEFORE UPDATE ON categoria
	FOR EACH ROW EXECUTE PROCEDURE altera_categoria_restricao_tres_function();