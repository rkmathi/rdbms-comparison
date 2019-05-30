DROP TABLE IF EXISTS comp_table;

CREATE TABLE IF NOT EXISTS comp_table (
  id  SERIAL,
  i_x BIGINT NOT NULL,
  i_y BIGINT NOT NULL,
  i_z BIGINT NOT NULL,
  c_x VARCHAR(128) NOT NULL,
  c_y VARCHAR(128) NOT NULL,
  c_z VARCHAR(128) NOT NULL,
  PRIMARY KEY (id)
);

CREATE INDEX idx_i ON comp_table(i_x, i_y);
CREATE INDEX idx_c ON comp_table(c_x, c_y);
