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
```
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
);

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

## カーディナリティ
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
