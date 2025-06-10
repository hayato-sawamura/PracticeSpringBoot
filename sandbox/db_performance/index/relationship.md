# 検証
カーディナリティ高低とインデックスの有無よってどれくらい検索速度が変わるのか？
- 単体テーブル(users)
- 複数のテーブル（users, cars）
  - JOIN処理の最適化のありなし（結合速度の違い）

## 定義
### users テーブル

| Column   | Type        | Options  |
| ------| --------| ------|
| id       | SERIAL     | NOT NULL |
| username | VARCHAR(128) | NOT NULL |
| email    | VARCHAR(128) | NOT NULL |
| password | VARCHAR(128) | NOT NULL |
| gender   | gender_type | NOT NULL |

### cars テーブル

| Column   | Type        | Options  |
| ------| ---------- | -------- |
| id       | SERIAL     | NOT NULL |
| model | model_type(128) | NOT NULL |
| owner_id   | int | NULL |

## 使用するツール
＊todo 使用するツールのバージョンを記載する
- TablePlus → GUIでデータベースを操作
- PostgreSQL → 検証用のDBMS
- Homebrew → PostgreSQLのインストール用パッケージ管理ツール
 

## 準備
```sql
-- 利用者数
SET cars_app_users TO '2300000';
SELECT CAST(current_setting('cars_app_users') AS INT);

-- Usersのgenderの型定義
CREATE TYPE gender_type AS ENUM ('male', 'female', 'non-binary');

-- usersのテーブルの作成
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(128) NOT NULL,
    email VARCHAR(128) NOT NULL,
    password VARCHAR(128) NOT NULL,
    gender gender_type NOT NULL
);

-- 230万のusersのデータ作成
time: 5.504s
WITH genders AS (
    SELECT unnest(ARRAY['male', 'female', 'non-binary'])::gender_type AS gender,
    generate_series(1, 3) AS index
)
INSERT INTO users (username, email, password, gender)
SELECT 
    'User_' || i, 
    'user_' || i || '@example.com', 
    'password_' || i, 
    (SELECT gender FROM genders WHERE index = (i % 3) + 1)
FROM generate_series(1, 2300000) AS i;

-- usersのデータ削除
DELETE FROM users;

-- usersのテーブル削除
DROP TABLE users;

-- Carsのmodelの型定義
CREATE TYPE model_type AS ENUM (
    'Corolla',
    'Camry',
    'Prius',
    'Land Cruiser',
    'RAV4',
    'Yaris',
    'Hilux',
    'Alphard',
    'Vellfire',
    'Crown'
);

-- carsのテーブル作成
CREATE TABLE cars (
    id SERIAL PRIMARY KEY,
    model model_type NOT NULL,
    owner_id int NOT NULL,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL
);


-- 230万人の車のアプリ作成（厳密にはユーザーは車を2台以上持ってる可能性がある）
WITH car_models AS (
    SELECT unnest(ARRAY['Corolla', 'Camry', 'Prius', 'Land Cruiser', 'RAV4', 
                        'Yaris', 'Hilux', 'Alphard', 'Vellfire', 'Crown'])::model_type AS model,
    generate_series(1, 10) AS INDEX
)
INSERT INTO cars (model, owner_id)
SELECT
	(SELECT model FROM car_models WHERE index = (i % 10) + 1),
    i
FROM generate_series(1, 2300000) AS i;

-- carsの全データ削除
DELETE FROM cars;

-- carsのテーブル削除
DROP TABLE cars;
```
## カーディナリティ: データベースのカラム内にあるデータの種類

### 使用する構文
```sql
-- カーディナリティの確認
SELECT <column>, COUNT(*) FROM users GROUP BY <column> ORDER BY COUNT(*) DESC LIMIT 10;
```

### 検証結果
```sql
-- usersのemail
-- >> emailはデータの種類が一意のため、カーディナリティが高い
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

-- usersのgender
-- >> genderはデータの種類が3種類（male, female, non-binary）のため、カーディナリティが低い
SELECT gender, COUNT(*) FROM users GROUP BY gender ORDER BY COUNT(*) DESC LIMIT 10;

female	766667
non-binary	766667
male	766666

-- carsのmodel
-- >> genderはデータの種類が10種類のため、カーディナリティが低い
SELECT model, COUNT(*) FROM cars GROUP BY model ORDER BY COUNT(*) DESC LIMIT 10;

Corolla	230000
Camry	230000
Prius	230000
Land Cruiser	230000
RAV4	230000
Yaris	230000
Hilux	230000
Alphard	230000
Vellfire	230000
Crown	230000
```
## インデックス
### 使用する構文
```sql
-- インデックス作成
CREATE INDEX idx_users_email on users(email);

-- インデックス削除
DROP INDEX idx_users_email;

-- 指定したテーブルのインデックスの適用を確認
SELECT * FROM pg_indexes WHERE tablename = 'users';

public	users	users_pkey	NULL	CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id)
public	users	idx_users_email	NULL	CREATE INDEX idx_users_email ON public.users USING btree (email)
```

### 検証結果
```sql
-- usersのid主キー検索
EXPLAIN ANALYSE SELECT * FROM users WHERE id = 1099;

Index Scan using users_pkwy on users  (cost=0.29..8.30 rows=1 width=76) (actual time=0.025..0.027 rows=1 loops=1)
  Index Cond: (id = 10)
Planning Time: 0.226 ms
Execution Time: 0.057 ms

-- usersのemail検索（カーディナリティ高い、インデックスなし）
DROP INDEX idx_users_email;
EXPLAIN ANALYSE SELECT * FROM users WHERE email = 'user_1099@example.com';
Gather  (cost=1000.00..77210.53 rows=2 width=60) (actual time=0.469..98.378 rows=2 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Parallel Seq Scan on users  (cost=0.00..76210.33 rows=1 width=60) (actual time=61.503..93.267 rows=1 loops=3)
"        Filter: ((email)::text = 'user_1099@example.com'::text)"
        Rows Removed by Filter: 1533333
Planning Time: 0.084 ms
Execution Time: 98.404 ms

-- usersのemail検索（カーディナリティ高い、インデックスあり）
CREATE INDEX idx_users_email ON users(email);
EXPLAIN ANALYSE SELECT * FROM users WHERE email = 'user_1099@example.com';
Index Scan using idx_users_email on users  (cost=0.43..12.35 rows=2 width=60) (actual time=0.022..0.032 rows=2 loops=1)
"  Index Cond: ((email)::text = 'user_1099@example.com'::text)"
Planning Time: 0.200 ms
Execution Time: 0.047 ms

-- usersのgender検索（カーディナリティ低い、インデックスなし）
DROP INDEX idx_users_gender;
EXPLAIN ANALYSE SELECT * FROM users WHERE gender = 'non-binary'; 
Seq Scan on users  (cost=0.00..109752.00 rows=3099480 width=60) (actual time=0.047..274.595 rows=3066667 loops=1)
"  Filter: (gender = 'non-binary'::gender_type)"
  Rows Removed by Filter: 1533333
Planning Time: 0.059 ms
Execution Time: 337.121 ms

-- usersのgender検索（カーディナリティ低い、インデックスあり）
CREATE INDEX idx_users_gender ON users(gender);
EXPLAIN ANALYSE SELECT * FROM users WHERE gender = 'non-binary'; 

Seq Scan on users  (cost=0.00..109752.00 rows=3099480 width=60) (actual time=0.054..266.063 rows=3066667 loops=1)
"  Filter: (gender = 'non-binary'::gender_type)"
  Rows Removed by Filter: 1533333
Planning Time: 0.070 ms
Execution Time: 327.206 ms
```

*todo JOIN結合のテスト