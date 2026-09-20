-- 研究進捗アプリ：記録の編集履歴（変更前の内容を残す）の追加SQL
-- supabase-setup.sql のあとで、SQL Editor に貼り付けて Run してください（パスワードの書き換えは不要）。
-- 何度実行しても安全です。
--
-- 電子実験ノートの作法にならい、編集しても元の内容は消さずに「変更前の内容・日付・編集した人・日時」を残します。
-- このSQLを実行しなくても編集はできますが、その場合は履歴が残りません。

alter table lab_notes add column if not exists edit_history jsonb not null default '[]'::jsonb;
alter table lab_logs  add column if not exists edit_history jsonb not null default '[]'::jsonb;
