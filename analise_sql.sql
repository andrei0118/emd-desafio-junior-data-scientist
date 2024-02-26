-- Filtrando todos os chamados a partir de 2022
-- Criar uma tabela temporária para armazenar os chamados a partir de 2022

CREATE TEMP TABLE chamados_2022 AS
SELECT *
FROM `datario.administracao_servicos_publicos.chamado_1746`
WHERE EXTRACT(YEAR FROM data_inicio) >= 2022;

-- Selecionando todos os dados sobre os bairros
-- Criar uma tabela temporária para armazenar os dados dos bairros
CREATE TEMP TABLE dados_bairro AS
SELECT *
FROM `datario.dados_mestres.bairro`;


-- 1- Quantos chamados foram abertos no dia 01/04/2023?

SELECT *
FROM `chamados_2022`
WHERE DATE(data_inicio) = '2023-04-01';

-- 2- Qual o tipo de chamado que teve mais reclamações no dia 01/04/2023?

-- Identificar o tipo de chamado com mais reclamações em 01/04/2023

SELECT tipo, COUNT(id_chamado) AS total_reclamacoes
FROM `datario.administracao_servicos_publicos.chamado_1746`
WHERE DATE(data_inicio) = '2023-04-01'
GROUP BY tipo
ORDER BY total_reclamacoes DESC
LIMIT 1;


-- 3- Quais os nomes dos 3 bairros que mais tiveram chamados abertos nesse dia?

SELECT b.nome AS nome_bairro, COUNT(*) AS total_chamados
FROM `datario.administracao_servicos_publicos.chamado_1746` AS c
JOIN `datario.dados_mestres.bairro` AS b
ON c.id_bairro = b.id_bairro
WHERE DATE(c.data_inicio) = '2023-04-01'
GROUP BY nome
ORDER BY total_chamados DESC
LIMIT 6;

-- 4- Qual o nome da subprefeitura com mais chamados abertos nesse dia?

WITH chamados_por_subprefeitura AS (
    SELECT b.subprefeitura, COUNT(DISTINCT c.id_chamado) AS total_chamados_por_subprefeitura
    FROM `datario.administracao_servicos_publicos.chamado_1746` AS c
    JOIN `datario.dados_mestres.bairro` AS b ON c.id_bairro = b.id_bairro
    WHERE DATE(c.data_inicio) = '2023-04-01'
    GROUP BY b.subprefeitura
)

SELECT subprefeitura, total_chamados_por_subprefeitura
FROM chamados_por_subprefeitura
WHERE total_chamados_por_subprefeitura = (
    SELECT MAX(total_chamados_por_subprefeitura)
    FROM chamados_por_subprefeitura
);

-- 5- Existe algum chamado aberto nesse dia que não foi associado a um bairro ou subprefeitura na tabela de bairros? Se sim, por que isso acontece?

SELECT *
FROM `datario.administracao_servicos_publicos.chamado_1746` AS c
LEFT JOIN `datario.dados_mestres.bairro` AS b
ON c.id_bairro = b.id_bairro
WHERE DATE(c.data_inicio) = '2023-04-01'
AND (b.nome IS NULL OR b.subprefeitura IS NULL);

-- 6- Quantos chamados com o subtipo "Perturbação do sossego" foram abertos desde 01/01/2022 até 31/12/2023 (incluindo extremidades)?

SELECT COUNT(*) AS total_chamados
FROM `datario.administracao_servicos_publicos.chamado_1746`
WHERE subtipo = 'Perturbação do sossego'
AND data_inicio >= '2022-01-01'
AND data_inicio <= '2023-12-31';


-- 7- Selecione os chamados com esse subtipo que foram abertos durante os eventos contidos na tabela de eventos (Reveillon, Carnaval e Rock in Rio).

SELECT chamado.* 
FROM `datario.administracao_servicos_publicos.chamado_1746` chamado
JOIN `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` AS evento
ON DATE(chamado.data_inicio) BETWEEN evento.data_inicial AND evento.data_final
WHERE chamado.subtipo = 'Perturbação do sossego';

-- 8- Quantos chamados desse subtipo foram abertos em cada evento?

SELECT
  evento.evento AS nome_evento,
  COUNT(*) AS quantidade_chamados
FROM
  `datario.administracao_servicos_publicos.chamado_1746` AS chamado
JOIN
  `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` AS evento
ON
  DATE(chamado.data_inicio) BETWEEN evento.data_inicial AND evento.data_final
WHERE
  chamado.subtipo = 'Perturbação do sossego'
GROUP BY
  evento.evento;


-- 9- Qual evento teve a maior média diária de chamados abertos desse subtipo?
WITH dias_evento AS (
  SELECT
    evento,
    SUM(DATE_DIFF(data_final, data_inicial, DAY) + 1) AS total_dias 
  FROM
    `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos`
  GROUP BY
    evento
)
SELECT
  evento.evento AS nome_evento,
  COUNT(*) AS quantidade_chamados,
  ROUND(COUNT(*) / dias_evento.total_dias, 2) AS media_diaria
FROM
  `datario.administracao_servicos_publicos.chamado_1746` AS chamado
JOIN
  `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` AS evento
ON
  DATE(chamado.data_inicio) BETWEEN evento.data_inicial AND evento.data_final
JOIN
  dias_evento
ON
  evento.evento = dias_evento.evento
WHERE
  chamado.subtipo = 'Perturbação do sossego'
GROUP BY
  evento.evento, dias_evento.total_dias
ORDER BY
  media_diaria DESC
LIMIT
  3;



-- 10- Compare as médias diárias de chamados abertos desse subtipo durante os eventos específicos (Reveillon, Carnaval e Rock in Rio) e a média diária de chamados abertos desse subtipo considerando todo o período de 01/01/2022 até 31/12/2023.

WITH dias_evento AS (
  SELECT
    evento,
    SUM(DATE_DIFF(data_final, data_inicial, DAY) + 1) AS total_dias 
  FROM
    `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos`
  GROUP BY
    evento
),
media_diaria_eventos AS (
  SELECT
    evento.evento AS nome_evento,
    ROUND(COUNT(*) / dias_evento.total_dias, 2) AS media_diaria_evento
  FROM
    `datario.administracao_servicos_publicos.chamado_1746` AS chamado
  JOIN
    `datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos` AS evento
  ON
    DATE(chamado.data_inicio) BETWEEN evento.data_inicial AND evento.data_final
  JOIN
    dias_evento
  ON
    evento.evento = dias_evento.evento
  WHERE
    chamado.subtipo = 'Perturbação do sossego'
  GROUP BY
    evento.evento, dias_evento.total_dias
),
media_total AS (
  SELECT
    ROUND(COUNT(*) / (DATE_DIFF('2023-12-31', '2022-01-01', DAY) + 1), 2) AS media_diaria_periodo
  FROM
    `datario.administracao_servicos_publicos.chamado_1746`
  WHERE
    subtipo = 'Perturbação do sossego' AND DATE(data_inicio) BETWEEN '2022-01-01' AND '2023-12-31'
)
SELECT
  nome_evento,
  media_diaria_evento,
  media_diaria_periodo
FROM
  media_diaria_eventos
JOIN
  media_total
ON 1=1;