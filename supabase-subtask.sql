-- 研究進捗アプリ：サブタスク（タスクの中に、入れ子でタスクを作る）のためのSQL
-- ★ 先に supabase-setup.sql を実行済みであることが必要です。
-- SQL Editor に貼り付けて Run してください（パスワードの書き換えは不要）。何度実行しても安全です。

-- 各タスクに「親のタスク」を持たせる（空なら、ふつうの単発タスク）。深さに制限はない。
-- 親のタスクが消えたときは、子は単発のタスクとして残る（子を巻き込んで消さない）。
alter table lab_tasks add column if not exists parent_id uuid references lab_tasks(id) on delete set null;
create index if not exists lab_tasks_parent on lab_tasks (parent_id);
