-- 研究進捗アプリ：管理者マーク ＋ 連絡の相手の制限
-- ★ 先に supabase-admin.sql を実行済みであることが必要です。
-- SQL Editor に貼り付けて Run してください（パスワードの書き換えは不要）。何度実行しても安全です。

-- ① 管理者マーク：管理者モードに一度でも入った人に付く（他の人からも見える）
alter table lab_members add column if not exists is_admin boolean not null default false;

-- is_hidden / is_admin を変えられるのは管理者だけ（マークを勝手に付ける・外すことはできない）
create or replace function lab_guard_hidden() returns trigger
language plpgsql as $$
begin
  if (new.is_hidden is distinct from old.is_hidden or new.is_admin is distinct from old.is_admin)
     and not lab_admin_ok() then
    raise exception 'is_hidden / is_admin can only be changed by admin' using errcode = '42501';
  end if;
  return new;
end;
$$;

-- 新規登録の時点で is_admin = true にすることもできない
create or replace function lab_guard_admin_insert() returns trigger
language plpgsql as $$
begin
  if new.is_admin and not lab_admin_ok() then
    raise exception 'is_admin can only be set by admin' using errcode = '42501';
  end if;
  return new;
end;
$$;
drop trigger if exists lab_guard_admin_insert on lab_members;
create trigger lab_guard_admin_insert before insert on lab_members
  for each row execute function lab_guard_admin_insert();

-- ② 連絡は「同じチームの中」と「管理者との間」だけ
--    ・管理者は、全員・全チームに送れる
--    ・チームのチャット：そのチームのメンバー（と管理者）だけが送れる
--    ・個別メッセージ：同じチームどうし、または、どちらかが管理者のとき
create or replace function lab_guard_message() returns trigger
language plpgsql security definer set search_path = public as $$
declare s lab_members; r lab_members;
begin
  select * into s from lab_members where id = new.sender_id;
  if s.is_admin then return new; end if;
  if new.to_id is null then
    if s.team <> '' and s.team = new.team then return new; end if;
    raise exception 'このチームのメンバーだけが、チームの連絡を送れます';
  end if;
  select * into r from lab_members where id = new.to_id;
  if r.is_admin or (s.team <> '' and s.team = r.team) then return new; end if;
  raise exception '同じチームの人か、管理者にだけ、メッセージを送れます';
end;
$$;
drop trigger if exists lab_guard_message on lab_messages;
create trigger lab_guard_message before insert on lab_messages
  for each row execute function lab_guard_message();
