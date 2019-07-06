/*
REGRA: os profissionais de uma equipe não podem ter permissao inferior à necessaria para a categoria dos projetos associados.
TABELAS ASSOCIADAS:
	-categoria (permissao_assoc)
	-projeto (equipe ou categoria)
	-funcionario (permissao ou equipe)
	-equipe (lider)
	-equipes_funcionarios (equipe ou funcionario)
*/

-- verifica alterações em categoria
CREATE OR REPLACE FUNCTION altera_categoria_restricao_um_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1Restricao1 CURSOR FOR
			SELECT min(nivel_permissao) AS permissao
			FROM funcionario
			JOIN equipes_funcionarios ON funcionario.id = equipes_funcionarios.funcionario_id
			JOIN projeto ON projeto.equipe_id = equipes_funcionarios.equipe_id
			WHERE projeto.categoria_nome = NEW.nome
			GROUP BY equipes_funcionarios.equipe_id;
		recebe_cursor RECORD;
	BEGIN
		IF NEW.permissao_assoc > OLD.permissao_assoc THEN
			OPEN cursor1Restricao1;
			FETCH cursor1Restricao1 INTO recebe_cursor;
			IF recebe_cursor.permissao < NEW.permissao_assoc THEN
				RAISE EXCEPTION 'A permissão da equipe associada a um projeto desta categoria não é compatível.'; 
			END IF;
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER altera_categoria_restricao_um BEFORE UPDATE ON categoria
	FOR EACH ROW EXECUTE PROCEDURE altera_categoria_restricao_um_function();


-- verifica alterações em projeto
CREATE OR REPLACE FUNCTION altera_ou_insere_projeto_restricao_um_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1Restricao1 CURSOR FOR
			SELECT min(nivel_permissao) AS permissao
			FROM funcionario
			JOIN equipes_funcionarios ON equipes_funcionarios.funcionario_id = funcionario.id
			WHERE equipes_funcionarios.equipe_id = NEW.equipe_id
			GROUP BY equipes_funcionarios.equipe_id;
		cursor2Restricao1 CURSOR FOR
			SELECT permissao_assoc
			FROM categoria
			WHERE categoria.nome = NEW.categoria_nome;
		permissao_equipe RECORD;
		permissao_categoria RECORD;
	BEGIN
		OPEN cursor1Restricao1;
		FETCH cursor1Restricao1 INTO permissao_equipe;
		OPEN cursor2Restricao1;
		FETCH cursor2Restricao1 INTO permissao_categoria;
		IF permissao_equipe < permissao_categoria THEN
			RAISE EXCEPTION 'A permissão associada a categoria deste projeto não é compatível com a da equipe.';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER altera_ou_insere_projeto_restricao_um BEFORE UPDATE OR INSERT ON projeto
	FOR EACH ROW EXECUTE PROCEDURE altera_ou_insere_projeto_restricao_um_function();
	
--verifica alterações em funcionarios
CREATE OR REPLACE FUNCTION altera_funcionario_restricao_um_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1Restricao1 CURSOR FOR
			SELECT max(categoria.permissao_assoc) AS permissao
			FROM projeto
			JOIN categoria ON projeto.categoria_nome = categoria.nome
			JOIN equipes_funcionarios ON projeto.equipe_id = equipes_funcionarios.equipe_id
			WHERE equipes_funcionarios.funcionario_id = NEW.id
			GROUP BY projeto.equipe_id;
		maxima_permissao_equipes RECORD;
	BEGIN
		OPEN cursor1Restricao1;
		FETCH cursor1Restricao1 INTO maxima_permissao_equipes;
		IF maxima_permissao_equipes.permissao > NEW.nivel_permissao THEN
			RAISE EXCEPTION 'Ao menos uma equipe deste funcionário contém projetos cuja permissao necessária é maior que a do funcionario.';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER altera_funcionario_restricao_um BEFORE UPDATE ON funcionario
	FOR EACH ROW EXECUTE PROCEDURE altera_funcionario_restricao_um_function();

--verifica alterações em equipe
CREATE OR REPLACE FUNCTION altera_equipe_restricao_um_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1Restricao1 CURSOR FOR
			SELECT max(categoria.permissao_assoc) AS permissao
			FROM projeto JOIN categoria ON projeto.categoria_nome = categoria.nome
			WHERE projeto.equipe_id = NEW.id
			GROUP BY projeto.equipe_id;
		cursor2Restricao1 CURSOR FOR
			SELECT nivel_permissao
			FROM funcionario
			WHERE funcionario.id = NEW.lider_id;
		permissao_equipe RECORD;
		permissao_lider RECORD;
	BEGIN
		OPEN cursor1Restricao1;
		FETCH cursor1Restricao1 INTO permissao_equipe;
		OPEN cursor2Restricao1;
		FETCH cursor2Restricao1 INTO permissao_lider;
		IF permissao_lider < permissao_equipe THEN
			RAISE EXCEPTION 'O líder não tem permissão para participar dos projetos desta equipe.';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER altera_equipe_restricao_um BEFORE UPDATE ON equipe
	FOR EACH ROW EXECUTE PROCEDURE altera_equipe_restricao_um_function();
	
--verifica alterações em equipes_funcionarios
CREATE OR REPLACE FUNCTION altera_ou_insere_equipes_funcionarios_restricao_um_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1Restricao1 CURSOR FOR
			SELECT max(categoria.permissao_assoc) AS permissao
			FROM projeto JOIN categoria ON projeto.categoria_nome = categoria.nome
			WHERE projeto.equipe_id = NEW.equipe_id
			GROUP BY projeto.equipe_id;
		cursor2Restricao1 CURSOR FOR
			SELECT nivel_permissao
			FROM funcionario
			WHERE funcionario.id = NEW.funcionario_id;
		permissao_equipe RECORD;
		permissao_funcionario RECORD;
	BEGIN
		OPEN cursor1Restricao1;
		FETCH cursor1Restricao1 INTO permissao_equipe;
		OPEN cursor2Restricao1;
		FETCH cursor2Restricao1 INTO permissao_funcionario;
		IF permissao_funcionario < permissao_equipe THEN
			RAISE EXCEPTION 'O funcionário não tem permissão para os projetos da equipe.';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER altera_ou_insere_equipes_funcionarios_restricao_um BEFORE UPDATE OR INSERT ON equipes_funcionarios
	FOR EACH ROW EXECUTE PROCEDURE altera_ou_insere_equipes_funcionarios_restricao_um_function();