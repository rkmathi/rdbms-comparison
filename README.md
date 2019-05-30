# rdbms-comparison

- MySQL (v8.0.16)
- PostgreSQL (v11.3)


# Usage

## Prepare
```shell
$ ./docker/mysql/prepare-db.sh
$ ./docker/postgres/prepare-db.sh
$ docker-compose up
```


## MySQL
```shell
$ mysql -h127.0.0.1 -P13306 -uuser -ppass comp_db

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


## PostgreSQL
```shell
$ psql -h127.0.0.1 -p15432 -Uuser -duser

mysql> \d comp_table
                                    Table "public.comp_table"
 Column |          Type          | Collation | Nullable |                Default
--------+------------------------+-----------+----------+----------------------------------------
 id     | integer                |           | not null | nextval('comp_table_id_seq'::regclass)
 i_x    | bigint                 |           | not null |
 i_y    | bigint                 |           | not null |
 i_z    | bigint                 |           | not null |
 c_x    | character varying(128) |           | not null |
 c_y    | character varying(128) |           | not null |
 c_z    | character varying(128) |           | not null |
Indexes:
    "comp_table_pkey" PRIMARY KEY, btree (id)
    "idx_c" btree (c_x, c_y)
    "idx_i" btree (i_x, i_y)
```

<details><summary>インデックスの効き方の実験</summary>


### 1カラムだけ選択

```txt
user=# analyze;
user=# \timing

user=# select * from comp_table where i_x = 1;
   id   | i_x |  i_y   |  i_z   |    c_x     |    c_y     |    c_z
--------+-----+--------+--------+------------+------------+------------
 169228 |   1 | 477213 | 790091 | hoge634835 | fuga248866 | piyo55335
 263157 |   1 | 510284 |  29200 | hoge481194 | fuga808109 | piyo450468
 720160 |   1 | 695252 | 373254 | hoge320516 | fuga80711  | piyo898816
(3 rows)
Time: 6.170 ms

user=# select * from comp_table where i_y = 1;
   id   |  i_x   | i_y |  i_z   |    c_x     |    c_y     |    c_z
--------+--------+-----+--------+------------+------------+------------
 346010 | 228451 |   1 | 610270 | hoge141758 | fuga296078 | piyo977291
 290182 | 222829 |   1 |  23977 | hoge400759 | fuga244409 | piyo402686
 726403 |  87525 |   1 | 402581 | hoge737902 | fuga243630 | piyo869985
(3 rows)
Time: 232.617 ms

user=# select * from comp_table where i_z = 1;
   id   |  i_x   |  i_y   | i_z |    c_x     |    c_y     |    c_z
--------+--------+--------+-----+------------+------------+------------
  38970 |  29587 | 808489 |   1 | hoge804136 | fuga361746 | piyo933422
 354923 | 300002 | 751630 |   1 | hoge67119  | fuga221030 | piyo883097
 804388 | 462545 | 347316 |   1 | hoge373689 | fuga672686 | piyo761175
(3 rows)
Time: 248.215 ms


user=# explain select * from comp_table where i_x = 1;
                                QUERY PLAN
--------------------------------------------------------------------------
 Index Scan using idx_i on comp_table  (cost=0.42..12.46 rows=2 width=58)
   Index Cond: (i_x = 1)
(2 rows)

user=# explain select * from comp_table where i_y = 1;
                                  QUERY PLAN
------------------------------------------------------------------------------
 Gather  (cost=1000.00..18255.53 rows=2 width=58)
   Workers Planned: 2
   ->  Parallel Seq Scan on comp_table  (cost=0.00..17255.33 rows=1 width=58)
         Filter: (i_y = 1)
(4 rows)

user=# explain select * from comp_table where i_z = 1;
                                  QUERY PLAN
------------------------------------------------------------------------------
 Gather  (cost=1000.00..18255.53 rows=2 width=58)
   Workers Planned: 2
   ->  Parallel Seq Scan on comp_table  (cost=0.00..17255.33 rows=1 width=58)
         Filter: (i_z = 1)
(4 rows)
```

### 2カラム選択

```txt
user=# select * from comp_table where i_x = 1 AND i_y = 1;
 id | i_x | i_y | i_z | c_x | c_y | c_z
----+-----+-----+-----+-----+-----+-----
(0 rows)
Time: 4.135 ms

user=# select * from comp_table where i_x = 1 AND i_z = 1;
 id | i_x | i_y | i_z | c_x | c_y | c_z
----+-----+-----+-----+-----+-----+-----
(0 rows)
Time: 4.249 ms

user=# select * from comp_table where i_y = 1 AND i_z = 1;
 id | i_x | i_y | i_z | c_x | c_y | c_z
----+-----+-----+-----+-----+-----+-----
(0 rows)
Time: 224.347 ms


user=# explain select * from comp_table where i_x = 1 AND i_y = 1;
                               QUERY PLAN
-------------------------------------------------------------------------
 Index Scan using idx_i on comp_table  (cost=0.42..8.45 rows=1 width=58)
   Index Cond: ((i_x = 1) AND (i_y = 1))
(2 rows)

user=# explain select * from comp_table where i_x = 1 AND i_z = 1;
                                QUERY PLAN
--------------------------------------------------------------------------
 Index Scan using idx_i on comp_table  (cost=0.42..12.46 rows=1 width=58)
   Index Cond: (i_x = 1)
   Filter: (i_z = 1)
(3 rows)

user=# explain select * from comp_table where i_y = 1 AND i_z = 1;
                                  QUERY PLAN
------------------------------------------------------------------------------
 Gather  (cost=1000.00..19297.10 rows=1 width=58)
   Workers Planned: 2
   ->  Parallel Seq Scan on comp_table  (cost=0.00..18297.00 rows=1 width=58)
         Filter: ((i_y = 1) AND (i_z = 1))
(4 rows)
```

### カバリングインデックス

```txt
user=# select i_x, i_y from comp_table where i_x = 1;
 i_x |  i_y
-----+--------
   1 | 477213
   1 | 510284
   1 | 695252
(3 rows)
Time: 3.744 ms

user=# select id, i_x, i_y from comp_table where i_x = 1;
   id   | i_x |  i_y
--------+-----+--------
 169228 |   1 | 477213
 263157 |   1 | 510284
 720160 |   1 | 695252
(3 rows)
Time: 4.177 ms

user=# select i_x, i_y, i_z from comp_table where i_x = 1;
 i_x |  i_y   |  i_z
-----+--------+--------
   1 | 477213 | 790091
   1 | 510284 |  29200
   1 | 695252 | 373254
(3 rows)
Time: 4.161 ms


user=# explain select i_x, i_y from comp_table where i_x = 1;
                                  QUERY PLAN
-------------------------------------------------------------------------------
 Index Only Scan using idx_i on comp_table  (cost=0.42..12.46 rows=2 width=16)
   Index Cond: (i_x = 1)
(2 rows)

user=# explain select id, i_x, i_y from comp_table where i_x = 1;
                                QUERY PLAN
--------------------------------------------------------------------------
 Index Scan using idx_i on comp_table  (cost=0.42..12.46 rows=2 width=20)
   Index Cond: (i_x = 1)
(2 rows)

user=# explain select i_x, i_y, i_z from comp_table where i_x = 1;
                                QUERY PLAN
--------------------------------------------------------------------------
 Index Scan using idx_i on comp_table  (cost=0.42..12.46 rows=2 width=24)
   Index Cond: (i_x = 1)
(2 rows)
```
</details>