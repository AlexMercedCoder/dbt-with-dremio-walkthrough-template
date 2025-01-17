{{ config(
    dremio_space_folder='raw'
) }}

SELECT * FROM Samples."samples.dremio.com"."NYC-weather.csv";