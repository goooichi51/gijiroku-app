-- メモ（シークレットモードで録音中に入力したテキスト）を保存するカラムを追加
alter table meetings add column if not exists notes text;
