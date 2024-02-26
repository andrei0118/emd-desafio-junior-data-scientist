 1) Quantos chamados foram abertos no dia 01/04/2023?
-- Resposta: 73 chamados.
-- Query:
SELECT COUNT(*) AS quantidade_chamados FROM datario.administracao_servicos_publicos.chamado_1746 
WHERE DATE(data_inicio) = '2023-04-01';


-- 2) Qual o tipo de chamado que teve mais teve chamados abertos no dia 01/04/2023?
-- Resposta: Poluição Sonora.
-- Query:
SELECT tipo FROM datario.administracao_servicos_publicos.chamado_1746 
WHERE DATE(data_inicio) = '2023-04-01'
GROUP BY tipo
ORDER BY COUNT(*) DESC
LIMIT 1;


-- 3) Quais os nomes dos 3 bairros que mais tiveram chamados abertos nesse dia?
-- Resposta: Engenho de Dentro, Leblon, Campo Grande.
-- Query:
SELECT bairros.nome as nome_bairro FROM datario.administracao_servicos_publicos.chamado_1746 AS chamados
JOIN datario.dados_mestres.bairro as bairros ON chamados.id_bairro = bairros.id_bairro
WHERE DATE(data_inicio) = '2023-04-01'
GROUP BY bairros.nome
ORDER BY COUNT(*) DESC
LIMIT 3;


-- 4) Qual o nome da subprefeitura com mais chamados abertos nesse dia?
-- Resposta: Zona Norte.
-- Query:
SELECT bairros.subprefeitura as nome_subprefeitura FROM datario.administracao_servicos_publicos.chamado_1746 AS chamados
JOIN datario.dados_mestres.bairro as bairros ON chamados.id_bairro = bairros.id_bairro
WHERE DATE(data_inicio) = '2023-04-01'
GROUP BY bairros.subprefeitura
ORDER BY COUNT(*) DESC
LIMIT 1;


-- 5) Existe algum chamado aberto nesse dia que não foi associado a um bairro ou subprefeitura na tabela de bairros? Se sim, por que isso acontece?
-- Resposta: Existe 1 chamado que não possui id_bairro (id 18516246), logo, não possui bairro associado. Isso se deve pelo fato de ser uma chamada do tipo Ônibus, sendo assim, não possui necessariamente uma localização fixa para o chamado.
-- Query:
SELECT * FROM datario.administracao_servicos_publicos.chamado_1746 
WHERE DATE(data_inicio) = '2023-04-01' AND id_bairro IS NULL;


-- 6) Quantos chamados com o subtipo "Perturbação do sossego" foram abertos desde 01/01/2022 até 31/12/2023 (incluindo extremidades)?
-- Resposta: 42408 chamados.
-- Query:
SELECT COUNT(*) AS quantidade_chamados FROM datario.administracao_servicos_publicos.chamado_1746 
WHERE subtipo = 'Perturbação do sossego' AND DATE(data_inicio) BETWEEN '2022-01-01' AND '2023-12-31';


-- 7) Selecione os chamados com esse subtipo que foram abertos durante os eventos contidos na tabela de eventos (Reveillon, Carnaval e Rock in Rio).
-- Resposta: Total de 1212 chamados.
-- Query:
SELECT chamados.* FROM datario.administracao_servicos_publicos.chamado_1746 chamados
JOIN datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos eventos ON DATE(chamados.data_inicio) BETWEEN eventos.data_inicial AND eventos.data_final
WHERE chamados.subtipo = 'Perturbação do sossego';


-- 8) Quantos chamados desse subtipo foram abertos em cada evento?
-- Resposta: Reveillon - 137 chamados; Carnaval - 241 chamados; Rock in Rio - 834 chamados.
-- Query:
SELECT eventos.evento AS nome_evento, COUNT(*) AS quantidade_chamados FROM datario.administracao_servicos_publicos.chamado_1746 chamados
JOIN datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos eventos ON DATE(chamados.data_inicio) BETWEEN eventos.data_inicial AND eventos.data_final
WHERE chamados.subtipo = 'Perturbação do sossego'
GROUP BY eventos.evento;


-- 9) Qual evento teve a maior média diária de chamados abertos desse subtipo?
-- Resposta: Rock in Rio, com uma média diária de 119.14 chamados.
-- Query:
WITH duracao_eventos AS (
  SELECT evento, SUM(DATE_DIFF(data_final, data_inicial, DAY)+1) AS total_dias FROM datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos
  GROUP BY evento
)
SELECT eventos.evento AS nome_evento, ROUND(COUNT(*)/duracao_eventos.total_dias, 2) AS media_diaria
FROM datario.administracao_servicos_publicos.chamado_1746 chamados
JOIN datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos eventos ON DATE(chamados.data_inicio) BETWEEN eventos.data_inicial AND eventos.data_final
JOIN duracao_eventos ON eventos.evento = duracao_eventos.evento
WHERE chamados.subtipo = 'Perturbação do sossego'
GROUP BY eventos.evento, duracao_eventos.total_dias
ORDER BY media_diaria DESC
LIMIT 1;


-- 10) Compare as médias diárias de chamados abertos desse subtipo durante os eventos específicos (Reveillon, Carnaval e Rock in Rio) e a média diária de chamados abertos desse subtipo considerando todo o período de 01/01/2022 até 31/12/2023.
-- Resposta: A média diária de chamados no período de 01/01/2022 até 31/12/2023 foi de 58.09 chamados, a média do Reveillon foi de 45.67 chamados diários, a do Carnaval foi de 60.25 chamados diários e a do Rock in Rio foi de 119.14 chamados diários. Assim, ao compararmos as médias temos que: a média diária do Carnaval foi 3.72% maior que a média diária anual; a média diária do Reveillon foi 21.38% menor que a média diária anual; e a média diária do Rock in Rio foi 105.1% maior que a média diária anual. 
-- Query:
WITH duracao_eventos AS (
  SELECT evento, SUM(DATE_DIFF(data_final, data_inicial, DAY)+1) AS total_dias FROM datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos
  GROUP BY evento
),
media_diaria_eventos AS (
  SELECT eventos.evento AS nome_evento, ROUND(COUNT(*)/duracao_eventos.total_dias, 2) AS media_diaria_evento
  FROM datario.administracao_servicos_publicos.chamado_1746 chamados
  JOIN datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos eventos ON DATE(chamados.data_inicio) BETWEEN eventos.data_inicial AND eventos.data_final
  JOIN duracao_eventos ON eventos.evento = duracao_eventos.evento
  WHERE chamados.subtipo = 'Perturbação do sossego'
  GROUP BY eventos.evento, duracao_eventos.total_dias
),
media_total AS (
  SELECT ROUND(COUNT(*)/(DATE_DIFF('2023-12-31', '2022-01-01', DAY)+1), 2) AS media_diaria_anual
  FROM datario.administracao_servicos_publicos.chamado_1746
  WHERE subtipo = 'Perturbação do sossego' AND DATE(data_inicio) BETWEEN '2022-01-01' AND '2023-12-31'
)
SELECT *, ROUND((media_diaria_evento*100)/media_diaria_anual - 100, 2) AS porcentagem_variacao FROM media_diaria_eventos
JOIN media_total ON 1=1;