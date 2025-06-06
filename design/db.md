## user テーブル

| Column   | Type   | Options  |
| -------- | ------ | -------- |
| id       | SERIAL | NOT NULL |
| username | VARCHAR(128)    | NOT NULL |
| email | VARCHAR(128)    | NOT NULL |
| password | VARCHAR(128)    | NOT NULL |
| profile | VARCHAR(128)    | NOT NULL |
| company | VARCHAR(128)    | NOT NULL |
| role | VARCHAR(128)    | NOT NULL |


### Option
- PRIMARY KEY (id)


## prototype table

| Column | Type | Options |
| ------ | ------ | ------ |
| id     | SERIAL | NOT NULL|
| user_id     | SERIAL | NOT NULL|
| name     | VARCHAR(128) | NOT NULL|
| catchphrase     | VARCHAR(128) | NOT NULL|
| concept     | VARCHAR(128)  | NOT NULL|
| image    | BYTEA | NOT NULL|
| created_at     | DATETIME  | NOT NULL|
| updated_at     | DATETIME  | NOT NULL|

### Option
- PRIMARY KEY(id)
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE

## comment table

| Column | Type | Options |
| ------ | ------ | ------ |
| id     | SERIAL | NOT NULL|
| prototype_id     | SERIAL | NOT NULL|
| content    | TEXT | NULL|
| created_at     | DATETIME  | NOT NULL|

### Option
- PRIMARY KEY(id)
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
- FOREIGN KEY (prototype_id) REFERENCES prototypes(id) ON DELETE CASCADE

## user_and_comment table
| Column | Type | Options |
| ------ | ------ | ------ |
| id     | SERIAL | NOT NULL|
| user_id     | SERIAL | NOT NULL|
| created_at     | DATETIME  | NOT NULL|
