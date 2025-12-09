# Лабораторна робота 5. Нормалізація бази даних Campus Events

У попередніх лабораторних роботах я спроєктувала схему соціальної мережі подій для студентів (Campus Events) і реалізувала її в PostgreSQL.

У цій роботі я формально описую:

- початкові (ненормалізовані) таблиці;
- функціональні залежності (ФЗ) для них;
- перевірку нормальних форм (1NF, 2NF, 3NF);
- поетапну нормалізацію до 3НФ;
- фінальну нормалізовану схему (реалізовано в `lab5.sql`).

Фінальна схема (у 3НФ) містить таблиці:

- `User`
- `Event`
- `Category`
- `EventCategory`
- `Follow`
- `EventParticipant`
- `Comment`
- `EventMention`
- `CommentMention`

---

## 1. Початкова (ненормалізована) схема та аномалії

На концептуальному рівні можна було уявити дані «плоскіше», об'єднавши кілька сутностей в одну таблицю. Для демонстрації нормалізації розглядаю дві проблемні таблиці:

- `EventFlat` – «сплющена» таблиця подій разом з організатором і категорією;
- `ParticipantFlat` – «сплющена» таблиця участей з дублюванням назви події та імені користувача.

### 1.1. Таблиця EventFlat

Уявна початкова структура:

`EventFlat(event_id, title, description, start_time, end_time, location,
           visibility, status, capacity,
           creator_id, creator_name, creator_email,
           category_name, category_description)`

Первинний ключ: `event_id`.

#### 1.1.1. Функціональні залежності для EventFlat

Позначаю атрибути:

- `E = event_id`
- `T = title`
- `D = description`
- `ST = start_time`
- `ET = end_time`
- `L = location`
- `V = visibility`
- `S = status`
- `C = capacity`
- `CRID = creator_id`
- `CRN = creator_name`
- `CRE = creator_email`
- `CN = category_name`
- `CD = category_description`

Мінімальний набір ФЗ:

1. `E → T, D, ST, ET, L, V, S, C, CRID, CN`
2. `CRID → CRN, CRE`
3. `CN → CD`

Звідси:

- `E → CRID → CRN, CRE` (транзитивна залежність)
- `E → CN → CD` (транзитивна залежність)

#### 1.1.2. Нормальна форма EventFlat

- 1НФ: усі атрибути атомарні, повторюваних груп немає → 1НФ виконується.
- 2НФ: первинний ключ простий (`event_id`), часткових залежностей немає → 2НФ формально виконується.
- 3НФ: є транзитивні залежності:
  - `event_id → creator_id → creator_name, creator_email`
  - `event_id → category_name → category_description`

Отже таблиця **не в 3НФ**.

#### 1.1.3. Аномалії EventFlat

- Надлишковість:
  - Ім'я та email організатора дублюються для всіх його подій.
  - Назва категорії й опис дублюються для всіх подій цієї категорії.
- Аномалії оновлення:
  - Якщо змінюється email організатора – потрібно оновити всі рядки його подій.
  - Якщо змінюється опис категорії – оновлюються всі події в цій категорії.
- Аномалії вставки:
  - Неможливо зберегти нову категорію без жодної події.
- Аномалії видалення:
  - При видаленні останньої події певної категорії ми втрачаємо інформацію про саму категорію.

---

### 1.2. Таблиця ParticipantFlat

Початкова структура:

`ParticipantFlat(event_id, event_title,
                 user_id, user_name,
                 status)`

Первинний ключ: складений `(event_id, user_id)`.

#### 1.2.1. Функціональні залежності для ParticipantFlat

Позначення:

- `E = event_id`
- `ET = event_title`
- `U = user_id`
- `UN = user_name`
- `ST = status`

Мінімальний набір ФЗ:

1. `(E, U) → ST`
2. `E → ET`
3. `U → UN`

Наслідки:

- `(E, U) → E → ET`
- `(E, U) → U → UN`

#### 1.2.2. Нормальна форма ParticipantFlat

- 1НФ: атрибути атомарні → 1НФ виконується.
- 2НФ: первинний ключ – складений `(E, U)`.  
  Є часткові залежності:
  - `E → ET` (атрибут залежить тільки від частини ключа),
  - `U → UN`.

  Отже 2НФ порушена.
- 3НФ: через порушення 2НФ автоматично не виконується 3НФ.

#### 1.2.3. Аномалії ParticipantFlat

- Надлишковість:
  - Назва події дублюється в кожному рядку з тим самим `event_id`.
  - Ім'я користувача дублюється в кожному рядку з тим самим `user_id`.
- Аномалії оновлення:
  - При зміні назви події потрібно редагувати всі рядки з цим `event_id`.
  - При зміні імені користувача – всі рядки з цим `user_id`.
- Аномалії вставки:
  - Неможливо зберегти подію без жодного учасника через структуру цієї таблиці.
- Аномалії видалення:
  - Якщо видалено останнього учасника події, втрачається інформація про саму подію (її назву).

---

## 2. Нормалізація крок за кроком

У цьому розділі показані переходи до 3НФ для `EventFlat` і `ParticipantFlat`. Результатом є розділення на кілька таблиць, які реалізовані у файлі `lab5.sql`.

### 2.1. Нормалізація EventFlat до 3НФ

#### Крок 1. 1НФ

Таблиця вже в 1НФ: усі атрибути атомарні.

#### Крок 2. 2НФ

Первинний ключ простий (`event_id`), тому часткових залежностей немає. Таблиця формально задовольняє 2НФ.

#### Крок 3. Перехід до 3НФ

Проблема – транзитивні залежності:

- `event_id → creator_id → creator_name, creator_email`
- `event_id → category_name → category_description`

Щоб усунути транзитивні залежності, розбиваємо таблицю на кілька:

1. Таблиця користувачів (організаторів):

   `User(id, email, password_hash, name, avatar_url, bio, role, created_at)`

   - Первинний ключ: `id`.
   - ФЗ: `id → всі_інші_поля`.
   - `email` також є унікальним (альтернативний ключ).

2. Таблиця категорій:

   `Category(id, name, description)`

   - Первинний ключ: `id`.
   - ФЗ: `id → name, description`.
   - `name` унікальний.

3. Таблиця подій:

   `Event(id, creator_id, title, description,
          start_time, end_time,
          location, visibility, status, capacity, created_at)`

   - Первинний ключ: `id`.
   - ФЗ: `id → creator_id, title, description, start_time, end_time,
          location, visibility, status, capacity, created_at`.
   - `creator_id` – зовнішній ключ на `User(id)`.

4. Зв’язувальна таблиця подія–категорія:

   `EventCategory(event_id, category_id)`

   - Первинний ключ: `(event_id, category_id)`.
   - Обидва поля – зовнішні ключі:
     - `event_id` → `Event(id)`
     - `category_id` → `Category(id)`.

У результаті:

- Дані про користувача зберігаються тільки в таблиці `User`.
- Дані про категорію – тільки в `Category`.
- Подія містить лише посилання (`creator_id`) і не дублює ім'я та email організатора чи опис категорії.
- Таблиця `EventCategory` реалізує зв’язок багато-до-багатьох між подіями й категоріями.

Усі неключові атрибути у кожній з цих таблиць залежать тільки від свого первинного ключа → 3НФ.

---

### 2.2. Нормалізація ParticipantFlat до 3НФ

#### Крок 1. 1НФ

Таблиця вже в 1НФ: атрибути атомарні.

#### Крок 2. 2НФ

Первинний ключ: `(event_id, user_id)`.

Надлишкові залежності:

- `event_id → event_title`
- `user_id → user_name`

Тобто часткові залежності від частин складеного ключа → порушення 2НФ.

#### Крок 3. Усунення часткових залежностей і перехід до 3НФ

Інформація про подію (`event_title`) і користувача (`user_name`) винесена у відповідні таблиці `Event` та `User` (описані вище). Таблиця участі зберігає тільки ключі та статус:

`EventParticipant(id, event_id, user_id, status, created_at)`

- Первинний ключ: `id` (сурогатний).
- Додатково унікальний ключ: `(event_id, user_id)`.
- ФЗ:
  - `id → event_id, user_id, status, created_at`
  - `(event_id, user_id) → status, created_at`

Жоден неключовий атрибут не залежить від іншого неключового атрибута → 3НФ.

---

## 3. Фінальна нормалізована схема (3НФ)

Фінальна схема у файлі `lab5.sql` відповідає 3НФ. Нижче коротко аналізую нормальні форми для кожної таблиці.

### 3.1. User

Атрибути: `id`, `email`, `password_hash`, `name`, `avatar_url`, `bio`, `role`, `created_at`.

- Ключ: `id` (кандидат – `email`).
- ФЗ: `id → всі_інші_поля`.
- Усі неключові атрибути залежать тільки від `id`.
- Часткових і транзитивних залежностей немає.
- НФ: **3НФ**.

### 3.2. Category

Атрибути: `id`, `name`, `description`.

- Ключ: `id`.
- ФЗ: `id → name, description`.
- `name` – унікальний, але не використовується як основний ключ.
- НФ: **3НФ**.

### 3.3. Event

Атрибути:  
`id`, `creator_id`, `title`, `description`, `start_time`, `end_time`,  
`location`, `visibility`, `status`, `capacity`, `created_at`.

- Ключ: `id`.
- ФЗ: `id → creator_id, title, description, start_time, end_time, location, visibility, status, capacity, created_at`.
- `creator_id` – лише зовнішній ключ на `User(id)`, не визначає інші неключові атрибути в цій таблиці.
- НФ: **3НФ**.

### 3.4. EventCategory

Атрибути: `event_id`, `category_id`.

- Ключ: складений `(event_id, category_id)`.
- Немає неключових атрибутів.
- НФ: **3НФ** (фактично BCNF).

### 3.5. Follow

Атрибути: `follower_id`, `followee_id`, `status`, `created_at`.

- Первинний ключ: `(follower_id, followee_id)`.
- ФЗ: `(follower_id, followee_id) → status, created_at`.
- Жодних транзитивних залежностей.
- НФ: **3НФ**.

### 3.6. EventParticipant

Атрибути: `id`, `event_id`, `user_id`, `status`, `created_at`.

- Ключ: `id`; додатково `UNIQUE(event_id, user_id)`.
- ФЗ: `id → event_id, user_id, status, created_at`.
- НФ: **3НФ**.

### 3.7. Comment

Атрибути: `id`, `event_id`, `user_id`, `text`, `created_at`.

- Ключ: `id`.
- ФЗ: `id → event_id, user_id, text, created_at`.
- НФ: **3НФ**.

### 3.8. EventMention

Атрибути: `id`, `event_id`, `user_id`, `created_at`.

- Ключ: `id`.
- ФЗ: `id → event_id, user_id, created_at`.
- НФ: **3НФ**.

### 3.9. CommentMention

Атрибути: `id`, `comment_id`, `user_id`, `created_at`.

- Ключ: `id`.
- ФЗ: `id → comment_id, user_id, created_at`.
- НФ: **3НФ**.

Усі таблиці фінальної схеми перебувають у 3НФ, транзитивні й часткові залежності винесені в окремі таблиці.

---

## 4. SQL DDL для фінальної схеми

Повний DDL-скрипт фінальної схеми (3НФ) наведений у файлі `lab5.sql`. Він містить:

- команди `DROP TABLE` / `DROP TYPE` для очищення схеми;
- створення перерахувань (`ENUM`) для логічних полів:
  - `user_role`
  - `follow_status`
  - `event_visibility`
  - `event_status`
  - `participant_status`
- створення таблиць:
  - `User`, `Category`, `Event`, `EventCategory`,
  - `Follow`, `EventParticipant`, `Comment`,
  - `EventMention`, `CommentMention`;
- первинні ключі, зовнішні ключі, унікальні обмеження та перевірку `CHECK` для заборони самопідписки у таблиці `Follow`.

Ці визначення можна виконати в PostgreSQL (pgAdmin/psql) і використовувати як основу для подальших лабораторних (аналітичні запити, OLAP з ЛР4 тощо).

---

## 5. Оновлена ER-діаграма

Фінальна ER-діаграма повинна відображати:

- сутності:
  - `User`, `Event`, `Category`, `EventCategory`,
  - `Follow`, `EventParticipant`, `Comment`,
  - `EventMention`, `CommentMention`;
- зв’язки:
  - `User` –< `Event` (кожен користувач може створювати багато подій);
  - `Event` >–< `Category` (через `EventCategory`);
  - `User` >–< `User` (через `Follow`);
  - `User` >–< `Event` (через `EventParticipant`);
  - `Event` –< `Comment`;
  - `Comment` –< `CommentMention` >– `User`;
  - `Event` –< `EventMention` >– `User`.

Оновлену діаграму потрібно експортувати у форматі зображення (PNG/PDF) і додати до репозиторію разом із цим файлом та `lab5.sql`.
