CREATE OR REPLACE FUNCTION altera_categoria_function() RETURNS TRIGGER AS $$
	DECLARE
		cursor1 CURSOR (nome_cat VARCHAR(20)) FOR
			SELECT min(nivel_permissao) AS permissao
			FROM funcionario
			NATURAL JOIN projeto
			WHERE projeto.categoria_nome = nome_cat
			GROUP BY funcionario.equipe_id;
		recebe_cursor RECORD;
	BEGIN
		IF NEW.permissao_assoc > OLD.permissao_assoc THEN
			OPEN cursor1(NEW.nome);
			FETCH cursor1 INTO recebe_cursor;
			IF recebe_cursor.permissao < NEW.permissao_assoc THEN
				RETURN OLD;
			END IF;
		END IF;
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER altera_categoria BEFORE UPDATE ON categoria
	FOR EACH ROW EXECUTE PROCEDURE altera_categoria_function();
	