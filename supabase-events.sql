-- 研究進捗アプリ：予定（試合の日など）のための追加SQL
-- ★ 先に supabase-setup.sql を実行済みであることが必要です（lab_ok() を使うため）。
-- SQL Editor に貼り付けて Run してください（パスワードの書き換えは不要）。何度実行しても安全です。

create table if not exists lab_events (
  id         uuid primary key default gen_random_uuid(),
  team       text not null default '',
  title      text not null,
  start_date date not null,
  end_date   date,
  place      text not null default '',
  detail     text not null default '',
  created_by uuid,
  created_at timestamptz not null default now()
);
create index if not exists lab_events_team_start on lab_events (team, start_date);

alter table lab_events enable row level security;
drop policy if exists lab_all on lab_events;
create policy lab_all on lab_events for all to anon using (lab_ok()) with check (lab_ok());
grant select, insert, update, delete on lab_events to anon;
