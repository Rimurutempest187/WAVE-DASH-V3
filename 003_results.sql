create table if not exists wd_runs (
  id         bigserial primary key,
  player_id  text not null references wd_profiles(id) on delete cascade,
  mode       text not null check (mode in ('classic','rank','endless','time_trial','challenge')),
  level_id   smallint not null default 0 check (level_id between 0 and 10),
  score      bigint   not null default 0 check (score between 0 and 1000000000),
  progress   smallint not null default 0 check (progress between 0 and 100),
  time_ms    integer  not null default 0 check (time_ms between 0 and 1800000),
  stars      smallint not null default 0 check (stars between 0 and 3),
  result     text     not null check (result in ('win','death')),
  created_at timestamptz not null default now()
);
create index if not exists wd_runs_player_idx on wd_runs(player_id, created_at desc);
create index if not exists wd_runs_mode_idx   on wd_runs(mode, score desc);

create table if not exists wd_achievement_claims (
  player_id      text not null references wd_profiles(id) on delete cascade,
  achievement_id text not null check (achievement_id ~ '^[a-z0-9_]{1,32}$'),
  claimed_at     timestamptz not null default now(),
  primary key (player_id, achievement_id)
);
