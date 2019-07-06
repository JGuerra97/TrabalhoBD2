/*
REGRA: Um lider de uma equipe não pode ter um nivel de permissão igual ou inferior aos funcionarios desta equipe que lidera.
TABELAS ASSOCIADAS:
	-funcionario (nivel_permissao)
	-equipe (lider)
	-equipes_funcionarios (equipes ou funcionarios)
*/

CREATE OR REPLACE FUNCTION verifica_situacao_funcionario_equipe(id_funcionario INTEGER, permissao_funcionario INTEGER, id_equipe INTEGER)
RETURNS boolean AS $$
	DECLARE
		lider_equipe_id INTEGER;
		maxima_permissao_equipe INTEGER;
		permissao_lider INTEGER;
	BEGIN
		SELECT lider_id --recupera o id do lider da equipe
			FROM equipe
			WHERE equipe.id = id_equipe
			INTO lider_equipe_id;
		IF lider_equipe_id = id_funcionario THEN --verifica se este funcionario tem a maior permissao
			SELECT max(nivel_permissao) AS permissao --recupera maior permissao dos funcionarios exceto o lider
				FROM funcionario
				JOIN equipes_funcionarios ON funcionario.id = equipes_funcionarios.funcionario_id
				WHERE equipes_funcionarios.equipe_id = id_equipe AND funcionario.id <> id_funcionario
				GROUP BY equipes_funcionarios.equipe_id
				INTO maxima_permissao_equipe;
			IF(maxima_permissao_equipe >= permissao_funcionario) THEN
				RETURN FALSE;
			END IF;
			RETURN TRUE;
		ELSE --verifica se a permissao do funcionario está abaixo do lider da equipe
			SELECT nivel_permissao AS permissao
				FROM funcionario
				WHERE funcionario.id = lider_equipe_id
				INTO permissao_lider;
			IF (permissao_lider <= permissao_funcionario) THEN
				RETURN FALSE;
			END IF;
			RETURN TRUE;
		END IF;
	END;
$$ LANGUAGE plpgsql;

--verifica alterações em funcionarios
CREATE OR REPLACE FUNCTION altera_funcionario_restricao_dois_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1Restricao2 CURSOR FOR
			SELECT equipes_funcionarios.equipe_id
			FROM equipes_funcionarios
			WHERE equipes_funcionarios.funcionario_id = NEW.id;
	BEGIN
		FOR id_equipe IN cursor1Restricao2 LOOP
			IF NOT verifica_situacao_funcionario_equipe(NEW.id, NEW.nivel_permissao, id_equipe.equipe_id) THEN
				RAISE EXCEPTION 'Todo lider de equipe deve ter permissao superior aos demais funcionarios da equipe que lidera.';
			END IF;
		END LOOP;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER altera_funcionario_restricao_dois BEFORE UPDATE ON funcionario
	FOR EACH ROW EXECUTE PROCEDURE altera_funcionario_restricao_dois_function();
	

--verifica alterações em equipe
CREATE OR REPLACE FUNCTION altera_equipe_restricao_dois_function() RETURNS TRIGGER AS $$
	DECLARE
		permissao_lider_equipe INTEGER;
	BEGIN
		SELECT nivel_permissao
			FROM funcionario
			WHERE funcionario.id = NEW.lider_id
			INTO permissao_lider_equipe;
		IF NOT verifica_situacao_funcionario_equipe(NEW.lider_id, permissao_lider_equipe, NEW.id) THEN
			RAISE EXCEPTION 'Todo lider de equipe deve ter permissao superior aos demais funcionarios da equipe que lidera.';
		END IF;
		RETURN NEW;	
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER altera_equipe_restricao_dois AFTER UPDATE ON equipe
	FOR EACH ROW EXECUTE PROCEDURE altera_equipe_restricao_dois_function();

	
--verifica alteracoes e insercoes em equipes_funcionarios
CREATE OR REPLACE FUNCTION altera_equipes_funcionarios_restricao_dois_function() RETURNS TRIGGER AS $$
	DECLARE
		permissao_funcionario INTEGER;
	BEGIN
		SELECT nivel_permissao
			FROM funcionario
			WHERE funcionario.id = NEW.funcionario_id
			INTO permissao_funcionario;
		IF NOT verifica_situacao_funcionario_equipe(NEW.funcionario_id, permissao_funcionario, NEW.equipe_id) THEN
			RAISE EXCEPTION 'Todo lider de equipe deve ter permissao superior aos demais funcionarios da equipe que lidera.';
		END IF;
		RETURN NEW;	
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER altera_equipes_funcionarios_restricao_dois BEFORE UPDATE OR INSERT ON equipes_funcionarios
	FOR EACH ROW EXECUTE PROCEDURE altera_equipes_funcionarios_restricao_dois_function();
	