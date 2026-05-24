let
    Source = Snowflake.Databases("myhost.snowflakecomputing.com","MY_WH"),
    SAMPLE_DB_Database = Source{[Name="SAMPLE_DB",Kind="Database"]}[Data],
    TPCH_SF1_Schema = SAMPLE_DB_Database{[Name="TPCH_SF1",Kind="Schema"]}[Data],
    NATION_Table = TPCH_SF1_Schema{[Name="NATION",Kind="Table"]}[Data]
in
    NATION_Table
