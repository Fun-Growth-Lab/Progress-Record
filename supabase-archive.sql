-- 研究進捗アプリ：チームのアーカイブ／完全削除のためのSQL
-- ★ 先に supabase-admin.sql と supabase-teams.sql を実行済みであることが必要です。
-- SQL Editor に貼り付けて Run してください（パスワードの書き換えは不要）。何度実行しても安全です。

-- ① アーカイブ：チームを一覧から見えなくする（消さない。あとで復元できる）
alter table lab_teams add column if not exists archived boolean not null default false;

-- アーカイブの切り替え（アーカイブ・復元）は管理者だけ
create or replace function lab_guard_team_archive() returns trigger
language plpgsql as $$
begin
  if new.archived is distinct from old.archived and not lab_admin_ok() then
    raise exception 'teams can only be archived by admin' using errcode = '42501';
  end if;
  return new;
end;
$$;
drop trigger if exists lab_guard_team_archive on lab_teams;
create trigger lab_guard_team_archive before update on lab_teams
  for each row execute function lab_guard_team_archive();

-- ② 完全削除：チームの連絡（チャット）の履歴を消せるのは管理者だけ
--    （チーム自体の削除は supabase-teams.sql で、すでに管理者だけになっています）
create or replace function lab_guard_message_delete() returns trigger
language plpgsql as $$
begin
  if not lab_admin_ok() then
    raise exception 'messages can only be deleted by admin' using errcode = '42501';
  end if;
  return old;
end;
$$;
drop trigger if exists lab_guard_message_delete on lab_messages;
create trigger lab_guard_message_delete before delete on lab_messages
  for each row execute function lab_guard_message_delete();
