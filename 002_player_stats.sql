create table if not exists wd_player_stats (
  player_id        text primary key references wd_profiles(id) on delete cascade,
  coins            bigint  not null default 0 check (coins            between 0 and 100000000),
  diamonds         bigint  not null default 0 check (diamonds         between 0 and 10000000),
  classic_stars    integer not null default 0 check (classic_stars    between 0 and 30),
  rank_stars       integer not null default 0 check (rank_stars       between 0 and 100000),
  rank_tier        text    not null default 'warrior'
                     check (rank_tier in ('warrior','elite','master',
                                          'grandmaster','epic','legends','mythic')),
  endless_best     bigint  not null default 0 check (endless_best     between 0 and 1000000000),
  challenge_clears integer not null default 0 check (challenge_clears between 0 and 64),
  total_score      bigint  not null default 0 check (total_score      >= 0),
  total_distance   bigint  not null default 0 check (total_distance   >= 0),
  levels_completed integer not null default 0 check (levels_completed between 0 and 10),
  best_time_ms     integer check (best_time_ms between 1200 and 1800000),
  updated_at       timestamptz not null default now()
);

create index if not exists wd_stats_rank_idx     on wd_player_stats(rank_stars    desc, updated_at asc);
create index if not exists wd_stats_classic_idx  on wd_player_stats(classic_stars desc, levels_completed desc);
create index if not exists wd_stats_endless_idx  on wd_player_stats(endless_best  desc);
create index if not exists wd_stats_trial_idx    on wd_player_stats(best_time_ms  asc nulls last);
create index if not exists wd_stats_chal_idx     on wd_player_stats(challenge_clears desc, total_score desc);
create index if not exists wd_stats_coins_idx    on wd_player_stats(coins    desc);
create index if not exists wd_stats_diamonds_idx on wd_player_stats(diamonds desc);

