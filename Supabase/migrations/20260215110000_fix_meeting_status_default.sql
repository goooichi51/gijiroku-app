-- 議事録のデフォルトステータスを修正
-- 保存済み議事録が「録音中」になる問題への対処
alter table meetings alter column status set default 'readyForSummary';

-- 既存の「録音中」ステータスの議事録を修正
update meetings set status = 'completed' where status = 'recording' and summary_json != '{}' and summary_json is not null;
update meetings set status = 'readyForSummary' where status = 'recording' and transcription_text is not null and transcription_text != '';
update meetings set status = 'transcribing' where status = 'recording';
