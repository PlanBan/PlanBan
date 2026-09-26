# Pravovyi Lider — full-stack website

Адаптивна оболонка юридичного сайту за візуальним напрямом pravovyilider.com.ua, тепер із робочим backend-контуром для заявок.

## Що працює

- адаптивний sticky-header і мобільне меню;
- hero, послуги, команда, відгуки, офіси та FAQ;
- усі CTA ведуть до потрібних секцій або контактних дій;
- три форми реально відправляють заявки на Supabase Edge Function;
- серверна валідація, honeypot і rate limit;
- заявки зберігаються в Postgres-таблиці `public.website_leads`;
- RLS не дозволяє анонімним користувачам читати заявки;
- `admin.html` підтримує вхід через Supabase Auth;
- в адмінці є список заявок, пошук, фільтр, зміна статусу, оновлення та CSV-експорт;
- `index.html` і `admin.html` можна відкривати напряму подвійним кліком.

## Backend

Supabase project:

- project ref: `kfvseygjvzljfspgjmiv`
- Edge Function: `submit-lead`
- endpoint: `https://kfvseygjvzljfspgjmiv.supabase.co/functions/v1/submit-lead`
- JWT verification: enabled

Міграції лежать у:

    backend/migrations/

Код Edge Function:

    backend/functions/submit-lead/index.ts

Публічний anon JWT присутній у фронтенді навмисно: це клієнтський ключ Supabase. Service Role key у репозиторій не записується.

## Локальний запуск

Найпростіше — відкрити `index.html` подвійним кліком.

Або:

    python -m http.server 8080

Потім:

    http://localhost:8080
    http://localhost:8080/admin.html

Для адмінки потрібен існуючий Supabase Auth користувач, який є активним учасником організації у `public.organization_members`.

## Статуси заявки

- `new` — нова;
- `contacted` — в роботі;
- `closed` — закрита;
- `spam` — спам.

## Безпека

- анонімний браузер не має SELECT/UPDATE доступу до таблиці заявок;
- insert виконується Edge Function через Service Role;
- endpoint вимагає валідний Supabase JWT;
- на endpoint є серверна перевірка полів;
- IP зберігається тільки як SHA-256 hash;
- частота заявок обмежена;
- присутнє honeypot-поле проти простих ботів.

## Важливо

Один демонстраційний фон у секції «Про нас» все ще завантажується з публічного ресурсу референсного сайту. Решта ключового інтерфейсу не залежить від backend-сервера для рендерингу.
