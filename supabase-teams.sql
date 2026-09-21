-- 研究進捗アプリ：チーム表の追加SQL（メンバーが0人でもチームが残る／チームの削除は管理者だけ）
-- ★ 先に supabase-admin.sql を実行済みであることが必要です（管理者の判定を使うため）。
-- SQL Editor に貼り付けて Run してください（パスワードの書き換えは不要）。何度実行しても安全です。

-- チーム表：メンバーの所属とは別に、チームそのものを残す
create table if not exists lab_teams (
  id         uuid primary key default gen_random_uuid(),
  name       text not null unique,
  created_at timestamptz not null default now()
);

-- いま所属している人がいるチームを、最初の一覧として登録
insert into lab_teams (name)
select distinct team from lab_members where team <> ''
on conflict (name) do nothing;

alter table lab_teams enable row level security;
drop policy if exists lab_all on lab_teams;
create policy lab_all on lab_teams for all to anon using (lab_ok()) with check (lab_ok());
grant select, insert, update, delete on lab_teams to anon;

-- チームの削除は管理者だけ（作成・名前の変更は全メンバーができる）
create or replace function lab_guard_team_delete() returns trigger
language plpgsql as $$
begin
  if not lab_admin_ok() then
    raise exception 'teams can only be deleted by admin' using errcode = '42501';
  end if;
  return old;
end;
$$;

drop trigger if exists lab_guard_team_delete on lab_teams;
create trigger lab_guard_team_delete before delete on lab_teams
  for each row execute function lab_guard_team_delete();
