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

CREATE OR REPLACE FUNCTION verifica_se_equipe_ja_possui_projeto_no_limite_da_permissao(id_equipe INTEGER, permissao_equipe INTEGER)
RETURNS INTEGER AS $$
	DECLARE
		quantidade_projetos_limite_permissao INTEGER;
	BEGIN
		SELECT count(*)
			FROM projeto
			JOIN categoria ON projeto.categoria_nome = categoria.nome
			WHERE projeto.equipe_id = id_equipe AND
			categoria.permissao_assoc = permissao_equipe
			INTO quantidade_projetos_limite_permissao;
		RETURN quantidade_projetos_limite_permissao;
	END;
$$ LANGUAGE plpgsql;


--verifica alteração em categoria
CREATE OR REPLACE FUNCTION altera_categoria_restricao_tres_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1Restricao3 CURSOR FOR
			SELECT equipes_funcionarios.equipe_id, min(nivel_permissao) AS permissao
			FROM funcionario
			JOIN equipes_funcionarios ON funcionario.id = equipes_funcionarios.funcionario_id
			JOIN projeto ON projeto.equipe_id = equipes_funcionarios.equipe_id
			WHERE projeto.categoria_nome = NEW.nome
			GROUP BY equipes_funcionarios.equipe_id;
	BEGIN
		IF NEW.permissao_assoc <> OLD.permissao_assoc THEN
			FOR cursor_linha IN cursor1Restricao3 LOOP
				IF cursor_linha.permissao <> OLD.permissao_assoc AND cursor_linha.permissao = NEW.permissao_assoc THEN
					IF verifica_se_equipe_ja_possui_projeto_no_limite_da_permissao(cursor_linha.equipe_id, cursor_linha.permissao) <> 0 THEN
						RAISE EXCEPTION 'Uma equipe só pode ter um projeto cuja permissão associada a sua categoria seja igual à permissão da equipe.'; 
					END IF;
				END IF;
			END LOOP;
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS altera_categoria_restricao_tres ON categoria;
CREATE TRIGGER altera_categoria_restricao_tres BEFORE UPDATE ON categoria
	FOR EACH ROW EXECUTE PROCEDURE altera_categoria_restricao_tres_function();
	

--verifica alteração em projeto
CREATE OR REPLACE FUNCTION altera_ou_insere_projeto_restricao_tres_function() RETURNS TRIGGER AS $$
	DECLARE
		permissao_equipe INTEGER;
		permissao_categoria INTEGER;
	BEGIN
		SELECT min(nivel_permissao)
			FROM funcionario
			JOIN equipes_funcionarios ON equipes_funcionarios.funcionario_id = funcionario.id
			WHERE equipes_funcionarios.equipe_id = NEW.equipe_id
			INTO permissao_equipe;
		SELECT permissao_assoc
			FROM categoria
			WHERE categoria.nome = NEW.categoria_nome
			INTO permissao_categoria;
		IF permissao_categoria = permissao_equipe AND verifica_se_equipe_ja_possui_projeto_no_limite_da_permissao(NEW.equipe_id, permissao_equipe) <> 0 THEN
			RAISE EXCEPTION 'A equipe associada a esse projeto já tem um projeto com sua permissão máxima.'; 
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS altera_ou_insere_projeto_restricao_tres ON projeto;
CREATE TRIGGER altera_ou_insere_projeto_restricao_tres BEFORE UPDATE OR INSERT ON projeto
	FOR EACH ROW EXECUTE PROCEDURE altera_ou_insere_projeto_restricao_tres_function();


--verifica alteração em equipe