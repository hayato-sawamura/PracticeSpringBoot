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
