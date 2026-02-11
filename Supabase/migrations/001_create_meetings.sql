-- プロフィールテーブル
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  display_name text,
  plan text default 'free' check (plan in ('free', 'standard')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 議事録テーブル
create table if not exists meetings (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) on delete cascade not null,
  title text not null default '',
  date timestamptz default now(),
  location text default '',
  participants text[] default '{}',
  template text not null default 'standard' check (template in ('standard', 'simple', 'sales', 'brainstorm')),
  status text not null default 'recording' check (status in ('recording', 'transcribing', 'readyForSummary', 'summarizing', 'completed')),
  audio_duration double precision default 0,
  transcription_text text default '',
  summary_raw_text text default '',
  summary_json jsonb default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- RLS有効化
alter table profiles enable row level security;
alter table meetings enable row level security;

-- プロフィールRLSポリシー
create policy "ユーザーは自分のプロフィールを閲覧可能"
  on profiles for select
  using (auth.uid() = id);

create policy "ユーザーは自分のプロフィールを更新可能"
  on profiles for update
  using (auth.uid() = id);

create policy "ユーザーは自分のプロフィールを作成可能"
  on profiles for insert
  with check (auth.uid() = id);

-- 議事録RLSポリシー
create policy "ユーザーは自分の議事録を閲覧可能"
  on meetings for select
  using (auth.uid() = user_id);

create policy "ユーザーは自分の議事録を作成可能"
  on meetings for insert
  with check (auth.uid() = user_id);

create policy "ユーザーは自分の議事録を更新可能"
  on meetings for update
  using (auth.uid() = user_id);

create policy "ユーザーは自分の議事録を削除可能"
  on meetings for delete
  using (auth.uid() = user_id);

-- 新規ユーザー登録時にプロフィール自動作成
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- updated_at自動更新トリガー
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at
  before update on profiles
  for each row execute function update_updated_at();

create trigger meetings_updated_at
  before update on meetings
  for each row execute function update_updated_at();
