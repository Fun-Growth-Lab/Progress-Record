-- 研究進捗アプリ：メンバー（管理者を含む）を完全に削除できるようにするSQL
-- ★ 先に supabase-admin.sql を実行済みであることが必要です（管理者の判定を使うため）。
-- SQL Editor に貼り付けて Run してください（パスワードの書き換えは不要）。何度実行しても安全です。
-- ※ 予定の表（supabase-events.sql）は、削除に影響しません。

-- ① 人を消したとき、その人のタスク・記録・メッセージも一緒に消える（残った参照でエラーにならない）ようにする
alter table lab_tasks    drop constraint if exists lab_tasks_assignee_id_fkey,
                         add  constraint lab_tasks_assignee_id_fkey foreign key (assignee_id) references lab_members(id) on delete cascade;
alter table lab_tasks    drop constraint if exists lab_tasks_created_by_fkey,
                         add  constraint lab_tasks_created_by_fkey  foreign key (created_by)  references lab_members(id) on delete set null;
alter table lab_logs     drop constraint if exists lab_logs_member_id_fkey,
                         add  constraint lab_logs_member_id_fkey    foreign key (member_id)   references lab_members(id) on delete set null;
alter table lab_notes    drop constraint if exists lab_notes_member_id_fkey,
                         add  constraint lab_notes_member_id_fkey   foreign key (member_id)   references lab_members(id) on delete cascade;
alter table lab_messages drop constraint if exists lab_messages_sender_id_fkey,
                         add  constraint lab_messages_sender_id_fkey foreign key (sender_id)  references lab_members(id) on delete cascade;
alter table lab_messages drop constraint if exists lab_messages_to_id_fkey,
                         add  constraint lab_messages_to_id_fkey    foreign key (to_id)      references lab_members(id) on delete cascade;

-- ② 人を消せるのは管理者だけ（管理者アカウントも消せる）
create or replace function lab_guard_member_delete() returns trigger
language plpgsql as $$
begin
  if not lab_admin_ok() then
    raise exception 'members can only be deleted by admin' using errcode = '42501';
  end if;
  return old;
end;
$$;
drop trigger if exists lab_guard_member_delete on lab_members;
create trigger lab_guard_member_delete before delete on lab_members
  for each row execute function lab_guard_member_delete();
