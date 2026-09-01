-- Monotonic merge: stats only ever move forward, so a replayed or
-- out-of-order submission can never reduce a player's standing.
create or replace function wd_touch_player(p jsonb)
returns text language plpgsql security definer set search_path = public as $$
declare pid text; nm text;
begin
  pid := p->>'player_id';
  nm  := nullif(trim(p->>'display_name'), '');
  if pid is null or pid !~ '^player_[a-z0-9]{8,32}$' then
    raise exception 'invalid player_id';
  end if;
  if nm is null or nm !~ '^[A-Za-z0-9 _.-]{3,16}$' then nm := 'Pilot'; end if;

  insert into wd_profiles (id, display_name, avatar, owner_uid)
  values (pid, nm, coalesce(p->>'avatar','classic'), (p->>'owner_uid')::uuid)
  on conflict (id) do update
    set display_name = excluded.display_name,
        avatar       = excluded.avatar,
        owner_uid    = coalesce(wd_profiles.owner_uid, excluded.owner_uid),
        updated_at   = now();

  insert into wd_player_stats as s (
    player_id, coins, diamonds, classic_stars, rank_stars, rank_tier,
    endless_best, challenge_clears, total_score, total_distance,
    levels_completed, best_time_ms)
  values (
    pid,
    least(greatest(coalesce((p->>'coins')::bigint,0),0), 100000000),
    least(greatest(coalesce((p->>'diamonds')::bigint,0),0), 10000000),
    least(greatest(coalesce((p->>'classic_stars')::int,0),0), 30),
    greatest(coalesce((p->>'rank_stars')::int,0),0),
    coalesce(nullif(p->>'rank_tier',''),'warrior'),
    greatest(coalesce((p->>'endless_best')::bigint,0),0),
    least(greatest(coalesce((p->>'challenge_clears')::int,0),0), 64),
    greatest(coalesce((p->>'total_score')::bigint,0),0),
    greatest(coalesce((p->>'total_distance')::bigint,0),0),
    least(greatest(coalesce((p->>'levels_completed')::int,0),0), 10),
    nullif((p->>'best_time_ms')::int, 0))
  on conflict (player_id) do update set
    coins            = greatest(s.coins,            excluded.coins),
    diamonds         = greatest(s.diamonds,         excluded.diamonds),
    classic_stars    = greatest(s.classic_stars,    excluded.classic_stars),
    rank_stars       = greatest(s.rank_stars,       excluded.rank_stars),
    rank_tier        = excluded.rank_tier,
    endless_best     = greatest(s.endless_best,     excluded.endless_best),
    challenge_clears = greatest(s.challenge_clears, excluded.challenge_clears),
    total_score      = greatest(s.total_score,      excluded.total_score),
    total_distance   = greatest(s.total_distance,   excluded.total_distance),
    levels_completed = greatest(s.levels_completed, excluded.levels_completed),
    best_time_ms     = least(coalesce(s.best_time_ms, excluded.best_time_ms),
                             coalesce(excluded.best_time_ms, s.best_time_ms)),
    updated_at       = now();
  return pid;
end $$;

create or replace function wd_log_run(p jsonb, m text)
returns void language sql security definer set search_path = public as $$
  insert into wd_runs (player_id, mode, level_id, score, progress, time_ms, stars, result)
  select p->>'player_id', m,
         least(greatest(coalesce((p->>'level_id')::int,0),0),10),
         least(greatest(coalesce((p->>'score')::bigint,0),0),1000000000),
         least(greatest(coalesce((p->>'progress')::int,0),0),100),
         least(greatest(coalesce((p->>'time_ms')::int,0),0),1800000),
         least(greatest(coalesce((p->>'stars')::int,0),0),3),
         case when p->>'result' = 'win' then 'win' else 'death' end;

$$;

create or replace function submit_classic_result(p jsonb)
returns text language plpgsql security definer set search_path = public as $$
begin perform wd_touch_player(p); perform wd_log_run(p,'classic'); return 'ok'; end $$;

create or replace function submit_rank_result(p jsonb)
returns text language plpgsql security definer set search_path = public as $$
begin perform wd_touch_player(p); perform wd_log_run(p,'rank'); return 'ok'; end $$;

create or replace function submit_endless_result(p jsonb)
returns text language plpgsql security definer set search_path = public as $$
begin perform wd_touch_player(p); perform wd_log_run(p,'endless'); return 'ok'; end $$;

create or replace function submit_time_trial(p jsonb)
returns text language plpgsql security definer set search_path = public as $$
begin
  -- reject impossible times outright rather than merging them
  if coalesce((p->>'time_ms')::int,0) between 1 and 1199 then
    raise exception 'implausible time';
  end if;
  perform wd_touch_player(p); perform wd_log_run(p,'time_trial'); return 'ok';
end $$;

create or replace function submit_challenge_result(p jsonb)
returns text language plpgsql security definer set search_path = public as $$
begin perform wd_touch_player(p); perform wd_log_run(p,'challenge'); return 'ok'; end $$;

create or replace function update_player_profile(p jsonb)
returns text language plpgsql security definer set search_path = public as $$
begin return wd_touch_player(p); end $$;

create or replace function claim_achievement_reward(p jsonb)
returns text language plpgsql security definer set search_path = public as $$
declare pid text;
begin
  pid := wd_touch_player(p);
  insert into wd_achievement_claims (player_id, achievement_id)
  values (pid, coalesce(p->>'achievement_id','unknown'))
  on conflict do nothing;
  return 'ok';
end $$;
