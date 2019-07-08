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
			SELECT min(nivel_permissao) AS permissao --recupera a permissao de cada equipe que tem algum projeto associado a esta categoria
			FROM funcionario
			JOIN equipes_funcionarios ON funcionario.id = equipes_funcionarios.funcionario_id
			JOIN projeto ON projeto.equipe_id = equipes_funcionarios.equipe_id
			WHERE projeto.categoria_nome = NEW.nome
			GROUP BY equipes_funcionarios.equipe_id;
	BEGIN
		IF NEW.permissao_assoc > OLD.permissao_assoc THEN
			FOR recebe_cursor IN cursor1Restricao1 LOOP
				IF recebe_cursor.permissao < NEW.permissao_assoc THEN
					RAISE EXCEPTION 'A permissão de uma equipe associada a um projeto desta categoria não é compatível.'; 
				END IF;
			END LOOP;
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS altera_categoria_restricao_um ON categoria;
CREATE TRIGGER altera_categoria_restricao_um BEFORE UPDATE ON categoria
	FOR EACH ROW EXECUTE PROCEDURE altera_categoria_restricao_um_function();


-- verifica alterações em projeto
CREATE OR REPLACE FUNCTION altera_ou_insere_projeto_restricao_um_function() RETURNS TRIGGER AS $$
	DECLARE
		permissao_equipe INTEGER;
		permissao_categoria INTEGER;
	BEGIN
		SELECT min(nivel_permissao)
			FROM funcionario
			JOIN equipes_funcionarios ON equipes_funcionarios.funcionario_id = funcionario.id
			WHERE equipes_funcionarios.equipe_id = NEW.equipe_id
			GROUP BY equipes_funcionarios.equipe_id
			INTO permissao_equipe; --recupera a permissao da equipe do projeto
		SELECT permissao_assoc
			FROM categoria
			WHERE categoria.nome = NEW.categoria_nome
			INTO permissao_categoria; --recupera a permissao da categoria do projeto
		IF permissao_equipe < permissao_categoria THEN
			RAISE EXCEPTION 'A permissão associada a categoria deste projeto não é compatível com a da equipe.';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS altera_ou_insere_projeto_restricao_um ON projeto;
CREATE TRIGGER altera_ou_insere_projeto_restricao_um BEFORE UPDATE OR INSERT ON projeto
	FOR EACH ROW EXECUTE PROCEDURE altera_ou_insere_projeto_restricao_um_function();
	
--verifica alterações em funcionarios
CREATE OR REPLACE FUNCTION altera_funcionario_restricao_um_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1Restricao1 CURSOR FOR
			SELECT max(categoria.permissao_assoc) AS permissaoNecessaria
			FROM projeto
			JOIN categoria ON projeto.categoria_nome = categoria.nome
			JOIN equipes_funcionarios ON projeto.equipe_id = equipes_funcionarios.equipe_id
			WHERE equipes_funcionarios.funcionario_id = NEW.id
			GROUP BY projeto.equipe_id;
	BEGIN
		FOR maxima_permissao_equipes IN cursor1Restricao1 LOOP
			IF maxima_permissao_equipes.permissaoNecessaria > NEW.nivel_permissao THEN
				RAISE EXCEPTION 'Ao menos uma equipe deste funcionário contém projetos cuja permissao necessária é maior que a do funcionario.';
			END IF;
		END LOOP;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS altera_funcionario_restricao_um ON funcionario;
CREATE TRIGGER altera_funcionario_restricao_um BEFORE UPDATE ON funcionario
	FOR EACH ROW EXECUTE PROCEDURE altera_funcionario_restricao_um_function();

--verifica alterações em equipe
CREATE OR REPLACE FUNCTION altera_equipe_restricao_um_function() RETURNS TRIGGER AS $$
	DECLARE
		permissao_equipe INTEGER;
		permissao_lider INTEGER;
	BEGIN
		SELECT max(categoria.permissao_assoc) AS permissao
			FROM projeto JOIN categoria ON projeto.categoria_nome = categoria.nome
			WHERE projeto.equipe_id = NEW.id
			INTO permissao_equipe;
		SELECT nivel_permissao
			FROM funcionario
			WHERE funcionario.id = NEW.lider_id
			INTO permissao_lider;
		IF permissao_lider < permissao_equipe THEN
			RAISE EXCEPTION 'O líder não tem permissão para participar dos projetos desta equipe.';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS altera_equipe_restricao_um ON equipe;
CREATE TRIGGER altera_equipe_restricao_um BEFORE UPDATE ON equipe
	FOR EACH ROW EXECUTE PROCEDURE altera_equipe_restricao_um_function();
	
--verifica alterações em equipes_funcionarios
CREATE OR REPLACE FUNCTION altera_ou_insere_equipes_funcionarios_restricao_um_function() RETURNS TRIGGER AS $$
	DECLARE
		permissao_projetos_equipe RECORD;
		permissao_funcionario INTEGER;
	BEGIN
		SELECT max(categoria.permissao_assoc) AS permissao, count(*) AS qtdProjetos
			FROM projeto JOIN categoria ON projeto.categoria_nome = categoria.nome
			WHERE projeto.equipe_id = NEW.equipe_id
			GROUP BY projeto.equipe_id
			INTO permissao_projetos_equipe;
		SELECT nivel_permissao
			FROM funcionario
			WHERE funcionario.id = NEW.funcionario_id
			INTO permissao_funcionario;
		IF permissao_projetos_equipe.qtdProjetos < 1 THEN
			RETURN NEW;
		END IF;
		IF permissao_funcionario < permissao_projetos_equipe.permissao THEN
			RAISE EXCEPTION 'O funcionário não tem permissão para os projetos da equipe.';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS altera_ou_insere_equipes_funcionarios_restricao_um ON equipes_funcionarios;
CREATE TRIGGER altera_ou_insere_equipes_funcionarios_restricao_um BEFORE UPDATE OR INSERT ON equipes_funcionarios
	FOR EACH ROW EXECUTE PROCEDURE altera_ou_insere_equipes_funcionarios_restricao_um_function();