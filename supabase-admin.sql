-- ロボ研究ノート：管理者機能（メンバーの非表示・復元）の追加SQL
-- supabase-setup.sql を実行したあとで、SQL Editor に貼り付けて Run してください。
-- 何度実行しても安全です（管理者パスワードを変えたいときも、この文を書き換えてもう一度 Run）。
--
-- ★ 下の '管理者パスワード' を、あなた（制作者）だけが知るパスワードに書き換えてから実行してください。
--   チーム共通パスワードとは別のものにしてください。半角英数字12文字以上を推奨。

-- 非表示フラグ（消すのではなく「隠す」だけ。記録は残る）
alter table lab_members add column if not exists is_hidden boolean not null default false;

-- 管理者パスワード（ハッシュで保存。anon からは読めない）
alter table lab_config add column if not exists admin_hash text;
update lab_config
   set admin_hash = encode(sha256(convert_to('管理者パスワード', 'UTF8')), 'hex')
 where id = 1;

-- リクエストヘッダ x-lab-admin が管理者ハッシュと一致するときだけ true
create or replace function lab_admin_ok() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from lab_config c
    where c.admin_hash is not null
      and c.admin_hash = (nullif(current_setting('request.headers', true), '')::json ->> 'x-lab-admin')
  );
$$;

-- アプリが「管理者パスワードは合っているか」を確かめるための関数
create or replace function lab_admin_check() returns boolean
language sql stable security definer set search_path = public as $$
  select lab_ok() and lab_admin_ok();
$$;

grant execute on function lab_admin_ok()    to anon;
grant execute on function lab_admin_check() to anon;

-- is_hidden を変えられるのは管理者だけ（チームのパスワードを知っているだけの人は変更できない）
create or replace function lab_guard_hidden() returns trigger
language plpgsql as $$
begin
  if new.is_hidden is distinct from old.is_hidden and not lab_admin_ok() then
    raise exception 'is_hidden can only be changed by admin' using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists lab_guard_hidden on lab_members;
create trigger lab_guard_hidden before update on lab_members
  for each row execute function lab_guard_hidden();
