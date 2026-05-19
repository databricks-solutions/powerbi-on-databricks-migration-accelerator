let
    Source = AmazonRedshift.Database("mycluster.redshift.amazonaws.com:5439","sample_data_dev"),
    tpch = Source{[Name="tpch"]}[Data],
    nation = tpch{[Name="NATION"]}[Data]
in
    nation
