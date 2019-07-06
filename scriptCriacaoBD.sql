DROP TABLE IF EXISTS funcionario CASCADE;
CREATE TABLE funcionario(
	id INTEGER NOT NULL,
	nome VARCHAR(30),
	nivel_permissao INTEGER DEFAULT 1,
	CONSTRAINT funcionario_pk PRIMARY KEY(id)
);

DROP TABLE IF EXISTS equipe CASCADE;
CREATE TABLE equipe(
	id INTEGER NOT NULL,
	lider_id INTEGER NOT NULL,
	CONSTRAINT equipe_pk PRIMARY KEY(id),
	CONSTRAINT equipe_funcionario_fk FOREIGN KEY (lider_id) REFERENCES funcionario (id) ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE IF EXISTS equipes_funcionarios CASCADE;
CREATE TABLE equipes_funcionarios (
	funcionario_id INTEGER, 
	equipe_id INTEGER,
	CONSTRAINT EQUIPES_FUNCIONARIOS_PK
	PRIMARY KEY (funcionario_id, equipe_id),
	CONSTRAINT EQUIPES_FUNCIONARIOS_FUNCIONARIO_FK
	FOREIGN KEY (funcionario_id) REFERENCES funcionario (id),
	CONSTRAINT EQUIPES_FUNCIONARIOS_EQUIPE_FK
	FOREIGN KEY (equipe_id) REFERENCES  equipe (id)
);
	
DROP TABLE IF EXISTS categoria CASCADE;
CREATE TABLE categoria(
	nome VARCHAR(20) NOT NULL,
	permissao_assoc INTEGER NOT NULL,
	CONSTRAINT categoria_pk PRIMARY KEY(nome)
);
	
DROP TABLE IF EXISTS projeto CASCADE;
CREATE TABLE projeto(
	id INTEGER NOT NULL,
	categoria_nome VARCHAR(20) NOT NULL,
	equipe_id INTEGER NOT NULL,
	CONSTRAINT projeto_pk PRIMARY KEY(id),
	CONSTRAINT projeto_categoria_fk FOREIGN KEY (categoria_nome) REFERENCES categoria(nome) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT projeto_equipe_fk FOREIGN KEY (equipe_id) REFERENCES equipe(id) ON DELETE CASCADE ON UPDATE CASCADE
);


--CASOS DE EXEMPLO PARA OS TESTES
INSERT INTO funcionario (id, nome, nivel_permissao) VALUES (1, 'Rodolfo', 4),(2, 'Rosislene', 3);
INSERT INTO equipe (id, lider_id) VALUES (1, 1);
INSERT INTO equipes_funcionarios VALUES (1, 1), (2, 1);
INSERT INTO categoria (nome, permissao_assoc) VALUES ('Administrativo', 2);
INSERT INTO projeto (id, categoria_nome, equipe_id) VALUES (1, 'Administrativo', 1);
SELECT * FROM funcionario, equipe, categoria, projeto;