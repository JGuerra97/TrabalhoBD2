/*
REGRA: os profissionais de uma equipe não podem ter permissao inferior à necessaria para a categoria dos projetos associados.
TABELAS ASSOCIADAS:
	-categoria (permissao_assoc)
	-projeto (equipe ou categoria)
	-funcionario (permissao ou equipe)
	-equipe (lider)
*/

-- verifica alterações em categoria
CREATE OR REPLACE FUNCTION altera_categoria_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1 CURSOR (nome_cat VARCHAR(20)) FOR
			SELECT min(nivel_permissao) AS permissao
			FROM funcionario
			JOIN projeto on projeto.equipe_id = projeto.equipe_id
			WHERE projeto.categoria_nome = nome_cat
			GROUP BY funcionario.equipe_id;
		recebe_cursor RECORD;
	BEGIN
		IF NEW.permissao_assoc > OLD.permissao_assoc THEN
			OPEN cursor1(NEW.nome);
			FETCH cursor1 INTO recebe_cursor;
			IF recebe_cursor.permissao < NEW.permissao_assoc THEN
				RAISE EXCEPTION 'A permissão da equipe associada a um projeto desta categoria não é compatível.'; 
			END IF;
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER altera_categoria BEFORE UPDATE ON categoria
	FOR EACH ROW EXECUTE PROCEDURE altera_categoria_function();


-- verifica alterações em projeto
CREATE OR REPLACE FUNCTION altera_ou_insere_projeto_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1 CURSOR (equipe_proj INTEGER) FOR
			SELECT min(nivel_permissao) AS permissao
			FROM funcionario
			WHERE funcionario.equipe_id = equipe_proj
			GROUP BY funcionario.equipe_id;
		cursor2 CURSOR (nome_cat VARCHAR(20)) FOR
			SELECT permissao_assoc
			FROM categoria
			WHERE categoria.nome = nome_cat;
		permissao_equipe RECORD;
		permissao_categoria RECORD;
	BEGIN
		OPEN cursor1(NEW.equipe_id);
		FETCH cursor1 INTO permissao_equipe;
		OPEN cursor2(NEW.categoria_nome);
		FETCH cursor2 INTO permissao_categoria;
		IF permissao_equipe < permissao_categoria THEN
			RAISE EXCEPTION 'A permissão associada a categoria deste projeto não é compatível com a da equipe.';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER altera_ou_insere_projeto BEFORE UPDATE OR INSERT ON projeto
	FOR EACH ROW EXECUTE PROCEDURE altera_ou_insere_projeto_function();
	
--verifica alterações em funcionarios
CREATE OR REPLACE FUNCTION altera_ou_insere_funcionario_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1 CURSOR (equipe_proj INTEGER) FOR
			SELECT max(categoria.permissao_assoc) AS permissao
			FROM projeto JOIN categoria ON projeto.categoria_nome = categoria.nome
			WHERE projeto.equipe_id = equipe_proj
			GROUP BY projeto.equipe_id;
		maxima_permissao_equipe RECORD;
	BEGIN
		OPEN cursor1(NEW.equipe_id);
		FETCH cursor1 INTO maxima_permissao_equipe;
		IF maxima_permissao_equipe.permissao > NEW.nivel_permissao THEN
			RAISE EXCEPTION 'A equipe deste funcionário contém projetos cuja permissao necessária é maior que a do funcionario.';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER altera_ou_insere_funcionario BEFORE UPDATE OR INSERT on funcionario
	FOR EACH ROW EXECUTE PROCEDURE altera_ou_insere_funcionario_function();

--verifica alterações em equipe
CREATE OR REPLACE FUNCTION altera_equipe_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1 CURSOR (id_equipe INTEGER) FOR --permissao mínima para participar da equipe
			SELECT max(categoria.permissao_assoc) AS permissao
			FROM projeto JOIN categoria ON projeto.categoria_nome = categoria.nome
			WHERE projeto.equipe_id = id_equipe
			GROUP BY projeto.equipe_id;
		cursor2 CURSOR (id_funcionario INTEGER) FOR --permissao de um funcionario
			SELECT nivel_permissao
			FROM funcionario
			WHERE funcionario.id = id_funcionario;
		permissao_equipe RECORD;
		permissao_lider RECORD;
	BEGIN
		OPEN cursor1(NEW.id);
		FETCH cursor1 INTO permissao_equipe;
		OPEN cursor2(NEW.lider_id);
		FETCH cursor2 INTO permissao_lider;
		IF permissao_lider < permissao_equipe THEN
			RAISE EXCEPTION 'O líder não tem permissão para participar dos projetos desta equipe.';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER altera_equipe BEFORE UPDATE ON equipe
	FOR EACH ROW EXECUTE PROCEDURE altera_equipe_function();