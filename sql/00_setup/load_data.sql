CREATE TABLE baf_raw AS
    SELECT * FROM read_csv('data/baf.csv')