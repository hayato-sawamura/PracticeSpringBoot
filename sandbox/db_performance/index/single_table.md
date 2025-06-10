# 前提

## user テーブル

| Column   | Type   | Options  |
| -------- | ------ | -------- |
| id       | SERIAL | NOT NULL |
| username | VARCHAR(128)    | NOT NULL |
| email | VARCHAR(128)    | NOT NULL |
| password | VARCHAR(128)    | NOT NULL |
| profile | VARCHAR(128)    | NOT NULL |
| company | VARCHAR(128)    | NOT NULL |
| role | VARCHAR(128)    | NOT NULL ｜


---

# 検証

## 準備
```sql
-- usersの作成
CREATE TABLE users (
  id SERIAL NOT NULL ,
  username VARCHAR(128) NOT NULL,
  email VARCHAR(128) NOT NULL,
  password VARCHAR(128) NOT NULL,
  profile VARCHAR(128) NOT NULL,
  company VARCHAR(128) NOT NULL,
  role VARCHAR(128) NOT NULL,
  PRIMARY KEY(id)
);か

-- 一万人のユーザー作成
INSERT INTO users (username, email, password, profile, company, role)
SELECT 
    'User_' || i, 
    'user_' || i || '@example.com', 
    'password_' || i, 
    'Profile_' || i, 
    'Company_' || (i % 10), 
    'Role_' || (i % 5)
FROM generate_series(1, 10000) AS i;
```

## カーディナリティ: データベースのカラム内にあるデータの種類
```sql
SELECT <column>, COUNT(*) FROM users GROUP BY <column> ORDER BY COUNT(*) DESC LIMIT 10;

-- カーディナリティが高い場合
SELECT email, COUNT(*) FROM users GROUP BY email ORDER BY COUNT(*) DESC LIMIT 10;
user_2990@example.com	1
user_8524@example.com	1
user_8450@example.com	1
user_8455@example.com	1
user_3052@example.com	1
user_4630@example.com	1
user_8731@example.com	1
user_8057@example.com	1
user_8750@example.com	1
user_4175@example.com	1

-- カーディナリティが低い場合
SELECT role, COUNT(*) FROM users GROUP BY role ORDER BY COUNT(*) DESC LIMIT 10;
Role_3	2000
Role_2	2000
Role_0	2000
Role_1	2000
Role_4	2000
sawa_role	1
```

## インデックス
```sql
-- インデックス作成
CREATE INDEX <index_name> ON <table_name(<column>)>

-- インデックス削除
DROP INDEX　<index_name>

-- テーブルのインデックスの適用を確認
SELECT * FROM pg_indexes WHERE tablename = 'users';

public	users	users_pkey	NULL	CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id)
public	users	idx_users_email	NULL	CREATE INDEX idx_users_email ON public.users USING btree (email)

-- usersの主キー検索
EXPLAIN ANALYSE SELECT * FROM users WHERE id = 1099;

Index Scan using users_pkwy on users  (cost=0.29..8.30 rows=1 width=76) (actual time=0.025..0.027 rows=1 loops=1)
  Index Cond: (id = 10)
Planning Time: 0.226 ms
Execution Time: 0.057 ms

-- 約10~100倍ぐらい速度が違う
-- usersのemail検索（カーディナリティ高い、インデックスなし）
EXPLAIN ANALYSE SELECT * FROM users WHERE email = 'user_1099@example.com';

Seq Scan on users  (cost=0.00..259.01 rows=1 width=76) (actual time=0.114..1.161 rows=1 loops=1)
"  Filter: ((email)::text = 'user_1099@example.com'::text)"
  Rows Removed by Filter: 10000
Planning Time: 0.098 ms
Execution Time: 1.175 ms

-- usersのemail検索（カーディナリティ高い、インデックスあり）
CREATE INDEX idx_users_email ON users(email);
EXPLAIN ANALYSE SELECT * FROM users WHERE email = 'user_1099@example.com';

Index Scan using idx_users_email on users  (cost=0.29..8.30 rows=1 width=76) (actual time=0.134..0.136 rows=1 loops=1)
"  Index Cond: ((email)::text = 'user_10@example.com'::text)"
Planning Time: 0.075 ms
Execution Time: 0.034 ms


-- 約2倍ぐらい速度が違う
-- usersのrole検索（カーディナリティ低い、インデックスなし）
EXPLAIN ANALYSE SELECT * FROM users WHERE role = 'Role_3'; 

Seq Scan on users  (cost=0.00..259.01 rows=2000 width=76) (actual time=0.007..0.719 rows=2000 loops=1)
"  Filter: ((role)::text = 'Role_3'::text)"
  Rows Removed by Filter: 8001
Planning Time: 0.115 ms
Execution Time: 0.778 ms

-- usersのrole検索（カーディナリティ低い、インデックスあり）
CREATE INDEX index_users_role ON users(role);
EXPLAIN ANALYSE SELECT * FROM users WHERE role = 'Role_3'; 

Bitmap Heap Scan on users  (cost=27.79..186.78 rows=2000 width=76) (actual time=0.118..0.386 rows=2000 loops=1)
"  Recheck Cond: ((role)::text = 'Role_3'::text)"
  Heap Blocks: exact=134
  ->  Bitmap Index Scan on index_users_role  (cost=0.00..27.29 rows=2000 width=0) (actual time=0.103..0.103 rows=2000 loops=1)
"        Index Cond: ((role)::text = 'Role_3'::text)"
Planning Time: 0.292 ms
Execution Time: 0.458 ms

```

```sql
-- インデックス作成
CREATE INDEX

-- インデックス削除
DROP INDEX　

-- テーブルのインデックスの適用を確認
SELECT * FROM pg_indexes WHERE tablename = 'users';

public	users	users_pkey	NULL	CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id)
public	users	idx_users_email	NULL	CREATE INDEX idx_users_email ON public.users USING btree (email)
```
