DROP TABLE IF EXISTS `comp_table`;

create table IF not exists `comp_table` (
 `id`  BIGINT(20) AUTO_INCREMENT,
 `i_x` BIGINT(20) NOT NULL,
 `i_y` BIGINT(20) NOT NULL,
 `i_z` BIGINT(20) NOT NULL,
 `c_x` VARCHAR(128) NOT NULL,
 `c_y` VARCHAR(128) NOT NULL,
 `c_z` VARCHAR(128) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `idx_i` USING BTREE (`i_x`, `i_y`),
  INDEX `idx_c` USING BTREE (`c_x`, `c_y`)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
