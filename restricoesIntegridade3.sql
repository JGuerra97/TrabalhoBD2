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
