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
	CONSTRAINT equipe_funcionario_fk FOREIGN KEY (lider_id) REFERENCES funcionario (id) ON DELETE RESTRICT ON UPDATE CASCADE
);

DROP TABLE IF EXISTS equipes_funcionarios CASCADE;
CREATE TABLE equipes_funcionarios (
	funcionario_id INTEGER, 
	equipe_id INTEGER,
	CONSTRAINT EQUIPES_FUNCIONARIOS_PK
	PRIMARY KEY (funcionario_id, equipe_id),
	CONSTRAINT EQUIPES_FUNCIONARIOS_FUNCIONARIO_FK
	FOREIGN KEY (funcionario_id) REFERENCES funcionario (id) ON DELETE CASCADE,
	CONSTRAINT EQUIPES_FUNCIONARIOS_EQUIPE_FK
	FOREIGN KEY (equipe_id) REFERENCES  equipe (id) ON DELETE CASCADE
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
	CONSTRAINT projeto_equipe_fk FOREIGN KEY (equipe_id) REFERENCES equipe(id) ON DELETE RESTRICT ON UPDATE CASCADE
);
