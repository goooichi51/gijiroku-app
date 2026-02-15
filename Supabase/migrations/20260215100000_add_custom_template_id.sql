-- カスタムテンプレートIDカラムを追加
-- カスタムテンプレート使用時にテンプレートIDを保存する
alter table meetings
  add column if not exists custom_template_id uuid default null;

-- templateカラムのCHECK制約を更新して'custom'も許可
-- （カスタムテンプレート使用時はtemplate='standard'のまま、custom_template_idで識別）
