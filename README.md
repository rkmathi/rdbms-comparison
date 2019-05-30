# rdbms-comparison

- MySQL (v8.0.16)

# Usage

## MySQL
```shell
$ docker-compose up

$ ./docker/mysql/prepare-db.sh

$ docker-compose exec mysql mysql -uuser -ppass comp_db

mysql> SHOW CREATE TABLE comp_table\G
*************************** 1. row ***************************
       Table: comp_table
Create Table: CREATE TABLE `comp_table` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `i_x` bigint(20) NOT NULL,
  `i_y` bigint(20) NOT NULL,
  `i_z` bigint(20) NOT NULL,
  `c_x` varchar(128) COLLATE utf8mb4_bin NOT NULL,
  `c_y` varchar(128) COLLATE utf8mb4_bin NOT NULL,
  `c_z` varchar(128) COLLATE utf8mb4_bin NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_i` (`i_x`,`i_y`) USING BTREE,
  KEY `idx_c` (`c_x`,`c_y`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=1000001 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin
1 row in set (0.00 sec)
```

<details><summary>インデックスの効き方の実験</summary>

### 1カラムだけ選択

```txt
mysql> select * from comp_table where i_x = 1;
3 rows in set (0.00 sec)

mysql> select * from comp_table where i_y = 1;
3 rows in set (0.48 sec)

mysql> select * from comp_table where i_z = 1;
3 rows in set (0.49 sec)


mysql> explain select * from comp_table where i_x = 1;
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------+
| id | select_type | table      | partitions | type | possible_keys | key   | key_len | ref   | rows | filtered | Extra |
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | comp_table | NULL       | ref  | idx_i         | idx_i | 8       | const |    3 |   100.00 | NULL  |
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------+
1 row in set, 1 warning (0.00 sec)

mysql> explain select * from comp_table where i_y = 1;
+----+-------------+------------+------------+------+---------------+------+---------+------+--------+----------+-------------+
| id | select_type | table      | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
+----+-------------+------------+------------+------+---------------+------+---------+------+--------+----------+-------------+
|  1 | SIMPLE      | comp_table | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 994719 |    10.00 | Using where |
+----+-------------+------------+------------+------+---------------+------+---------+------+--------+----------+-------------+
1 row in set, 1 warning (0.00 sec)

mysql> explain select * from comp_table where i_z = 1;
+----+-------------+------------+------------+------+---------------+------+---------+------+--------+----------+-------------+
| id | select_type | table      | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
+----+-------------+------------+------------+------+---------------+------+---------+------+--------+----------+-------------+
|  1 | SIMPLE      | comp_table | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 994719 |    10.00 | Using where |
+----+-------------+------------+------------+------+---------------+------+---------+------+--------+----------+-------------+
1 row in set, 1 warning (0.00 sec)
```

### 2カラム選択

```txt
mysql> select * from comp_table where i_x = 1 AND i_y = 1;
Empty set (0.00 sec)

mysql> select * from comp_table where i_x = 1 AND i_z = 1;
Empty set (0.00 sec)

mysql> select * from comp_table where i_y = 1 AND i_z = 1;
Empty set (0.50 sec)


mysql> explain select * from comp_table where i_x = 1 AND i_y = 1;
+----+-------------+------------+------------+------+---------------+-------+---------+-------------+------+----------+-------+
| id | select_type | table      | partitions | type | possible_keys | key   | key_len | ref         | rows | filtered | Extra |
+----+-------------+------------+------------+------+---------------+-------+---------+-------------+------+----------+-------+
|  1 | SIMPLE      | comp_table | NULL       | ref  | idx_i         | idx_i | 16      | const,const |    1 |   100.00 | NULL  |
+----+-------------+------------+------------+------+---------------+-------+---------+-------------+------+----------+-------+
1 row in set, 1 warning (0.00 sec)

mysql> explain select * from comp_table where i_x = 1 AND i_z = 1;
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------------+
| id | select_type | table      | partitions | type | possible_keys | key   | key_len | ref   | rows | filtered | Extra       |
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------------+
|  1 | SIMPLE      | comp_table | NULL       | ref  | idx_i         | idx_i | 8       | const |    3 |    10.00 | Using where |
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------------+
1 row in set, 1 warning (0.00 sec)

mysql> explain select * from comp_table where i_y = 1 AND i_z = 1;
+----+-------------+------------+------------+------+---------------+------+---------+------+--------+----------+-------------+
| id | select_type | table      | partitions | type | possible_keys | key  | key_len | ref  | rows   | filtered | Extra       |
+----+-------------+------------+------------+------+---------------+------+---------+------+--------+----------+-------------+
|  1 | SIMPLE      | comp_table | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 994719 |     1.00 | Using where |
+----+-------------+------------+------------+------+---------------+------+---------+------+--------+----------+-------------+
1 row in set, 1 warning (0.00 sec)
```

### カバリングインデックス

```txt
mysql> select i_x, i_y from comp_table where i_x = 1;
+-----+--------+
| i_x | i_y    |
+-----+--------+
|   1 | 477213 |
|   1 | 510284 |
|   1 | 695252 |
+-----+--------+
3 rows in set (0.00 sec)

mysql> select id, i_x, i_y from comp_table where i_x = 1;
+--------+-----+--------+
| id     | i_x | i_y    |
+--------+-----+--------+
| 169228 |   1 | 477213 |
| 263157 |   1 | 510284 |
| 720160 |   1 | 695252 |
+--------+-----+--------+
3 rows in set (0.00 sec)

mysql> select i_x, i_y, i_z from comp_table where i_x = 1;
+-----+--------+--------+
| i_x | i_y    | i_z    |
+-----+--------+--------+
|   1 | 477213 | 790091 |
|   1 | 510284 |  29200 |
|   1 | 695252 | 373254 |
+-----+--------+--------+
3 rows in set (0.00 sec)


mysql> explain select i_x, i_y from comp_table where i_x = 1;
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------------+
| id | select_type | table      | partitions | type | possible_keys | key   | key_len | ref   | rows | filtered | Extra       |
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------------+
|  1 | SIMPLE      | comp_table | NULL       | ref  | idx_i         | idx_i | 8       | const |    3 |   100.00 | Using index |
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------------+
1 row in set, 1 warning (0.00 sec)

mysql> explain select id, i_x, i_y from comp_table where i_x = 1;
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------------+
| id | select_type | table      | partitions | type | possible_keys | key   | key_len | ref   | rows | filtered | Extra       |
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------------+
|  1 | SIMPLE      | comp_table | NULL       | ref  | idx_i         | idx_i | 8       | const |    3 |   100.00 | Using index |
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------------+
1 row in set, 1 warning (0.00 sec)

mysql> explain select i_x, i_y, i_z from comp_table where i_x = 1;
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------+
| id | select_type | table      | partitions | type | possible_keys | key   | key_len | ref   | rows | filtered | Extra |
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | comp_table | NULL       | ref  | idx_i         | idx_i | 8       | const |    3 |   100.00 | NULL  |
+----+-------------+------------+------------+------+---------------+-------+---------+-------+------+----------+-------+
1 row in set, 1 warning (0.00 sec)
```
</details>
