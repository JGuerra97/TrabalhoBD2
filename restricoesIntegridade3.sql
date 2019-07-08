/*
REGRA: A soma das permissões dos projetos de uma equipe não deve ser maior do que metade da soma das permissões dos membros da equipe.
TABELAS ASSOCIADAS:
	-categoria (permissao_assoc)
	-projeto (categoria ou equipe)
	-funcionario (permissao)
	-equipes_funcionarios (equipe ou funcionario)
*/

CREATE OR REPLACE FUNCTION verifica_somatorio_das_permissoes(id_equipe INTEGER)
RETURNS boolean AS $$
	DECLARE
		somatorio_permissoes_projetos INTEGER;
		somatorio_permissao_equipe INTEGER;
	BEGIN
		IF coalesce(id_equipe, -1) = -1 THEN --se o id_equipe é nulo, não existe equipe para ter projetos
			RETURN TRUE;
		END IF;
		SELECT sum(nivel_permissao)
			FROM funcionario
			JOIN equipes_funcionarios ON funcionario.id = equipes_funcionarios.funcionario_id
			WHERE equipes_funcionarios.equipe_id = id_equipe
			GROUP BY equipes_funcionarios.equipe_id
			INTO somatorio_permissao_equipe; --recupera a soma das permissoes da equipe
		SELECT sum(categoria.permissao_assoc)
			FROM projeto
			JOIN categoria ON projeto.categoria_nome = categoria.nome
			WHERE projeto.equipe_id = id_equipe
			INTO somatorio_permissoes_projetos; --recupera a quantidade de projetos associados a essa equipe
		IF somatorio_permissoes_projetos <= (somatorio_permissao_equipe/2) THEN
			RETURN TRUE;
		END IF;
		RETURN FALSE;
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
	BEGIN
		IF NEW.permissao_assoc <> OLD.permissao_assoc THEN
			FOR equipe_linha IN cursor1Restricao3 LOOP
				IF NOT verifica_somatorio_das_permissoes(equipe_linha.id) THEN
					RAISE EXCEPTION 'Ao menos uma equipe tem ao menos um projeto desta categoria e não tem permissão suficiente para manter esta atualização';
				END IF;
			END LOOP;
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS altera_categoria_restricao_tres ON categoria;
CREATE TRIGGER altera_categoria_restricao_tres AFTER UPDATE ON categoria
	FOR EACH ROW EXECUTE PROCEDURE altera_categoria_restricao_tres_function();
	
	
--verifica inserção ou alteração em projeto
CREATE OR REPLACE FUNCTION altera_ou_insere_projeto_restricao_tres_function() RETURNS TRIGGER AS $$
	BEGIN
		IF NOT verifica_somatorio_das_permissoes(NEW.equipe_id) THEN
			RAISE EXCEPTION 'A equipe não tem permissão suficiente para assumir este projeto.';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS altera_ou_insere_projeto_restricao_tres ON projeto;
CREATE TRIGGER altera_ou_insere_projeto_restricao_tres AFTER UPDATE OR INSERT ON projeto
	FOR EACH ROW EXECUTE PROCEDURE altera_ou_insere_projeto_restricao_tres_function();
	
--verifica alteração em funcionario
CREATE OR REPLACE FUNCTION altera_funcionario_restricao_tres_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1Restricao3 CURSOR FOR --pega todas as equipes de um funcionário
			SELECT equipes_funcionarios.equipe_id
			FROM equipes_funcionarios
			WHERE equipes_funcionarios.funcionario_id = NEW.id;
	BEGIN
		IF NEW.nivel_permissao < OLD.nivel_permissao THEN
			FOR id_equipe IN cursor1Restricao3 LOOP
				IF NOT verifica_somatorio_das_permissoes(id_equipe.equipe_id) THEN
					RAISE EXCEPTION 'Alguma das equipes deste funcionario não terá permissão suficiente para os projetos que gerencia.';
				END IF;
			END LOOP;
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS altera_funcionario_restricao_tres ON funcionario;
CREATE TRIGGER altera_funcionario_restricao_tres AFTER UPDATE ON funcionario
	FOR EACH ROW EXECUTE PROCEDURE altera_funcionario_restricao_tres_function();
	
	
--verifica alteração ou inserção em equipes_funcionarios
CREATE OR REPLACE FUNCTION altera_ou_insere_equipes_funcionarios_restricao_tres_function() RETURNS TRIGGER AS $$
	BEGIN 
		IF NOT verifica_somatorio_das_permissoes(OLD.equipe_id) THEN
			RAISE EXCEPTION 'A equipe não terá perimssão suficiente para manter os projetos que gerencia.';
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS altera_ou_insere_equipes_funcionarios_restricao_tres ON equipes_funcionarios;
CREATE TRIGGER altera_ou_insere_equipes_funcionarios_restricao_tres AFTER UPDATE OR DELETE ON equipes_funcionarios
	FOR EACH ROW EXECUTE PROCEDURE altera_ou_insere_equipes_funcionarios_restricao_tres_function();