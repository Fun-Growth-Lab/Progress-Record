-- 研究進捗アプリ：アドバイザー（チームに所属せず、全チームを見て、全員に連絡できる役割）のSQL
-- ★ 先に supabase-admin.sql と supabase-admin-badge.sql を実行済みであることが必要です。
-- SQL Editor に貼り付けて Run してください（パスワードの書き換えは不要）。何度実行しても安全です。

-- ① アドバイザーのマーク
alter table lab_members add column if not exists is_advisor boolean not null default false;

-- is_hidden / is_admin / is_advisor を変えられるのは管理者だけ（自分で付ける・外すことはできない）
create or replace function lab_guard_hidden() returns trigger
language plpgsql as $$
begin
  if (new.is_hidden is distinct from old.is_hidden
      or new.is_admin is distinct from old.is_admin
      or new.is_advisor is distinct from old.is_advisor)
     and not lab_admin_ok() then
    raise exception 'is_hidden / is_admin / is_advisor can only be changed by admin' using errcode = '42501';
  end if;
  return new;
end;
$$;

-- アドバイザーとして新規登録するときは、チームなし・管理者ではない、に固定する
create or replace function lab_guard_advisor_insert() returns trigger
language plpgsql as $$
begin
  if new.is_advisor then
    new.team := '';
    new.is_admin := false;
  end if;
  return new;
end;
$$;
drop trigger if exists lab_guard_advisor_insert on lab_members;
create trigger lab_guard_advisor_insert before insert on lab_members
  for each row execute function lab_guard_advisor_insert();

-- ② 連絡：アドバイザーは、全員に送れる。メンバーは、アドバイザーにも送れる
create or replace function lab_guard_message() returns trigger
language plpgsql security definer set search_path = public as $$
declare s lab_members; r lab_members;
begin
  select * into s from lab_members where id = new.sender_id;
  if s.is_admin or s.is_advisor then return new; end if;
  if new.to_id is null then
    if s.team <> '' and s.team = new.team then return new; end if;
    raise exception 'このチームのメンバーだけが、チームの連絡を送れます';
  end if;
  select * into r from lab_members where id = new.to_id;
  if r.is_admin or r.is_advisor or (s.team <> '' and s.team = r.team) then return new; end if;
  raise exception '同じチームの人か、管理者・アドバイザーにだけ、メッセージを送れます';
end;
$$;
drop trigger if exists lab_guard_message on lab_messages;
create trigger lab_guard_message before insert on lab_messages
  for each row execute function lab_guard_message();
