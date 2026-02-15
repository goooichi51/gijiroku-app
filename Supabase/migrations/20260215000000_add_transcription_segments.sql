-- 文字起こしセグメント（タイムスタンプ付き）をクラウド同期するためのカラム追加
alter table meetings
  add column if not exists transcription_segments_json jsonb default null;
