alter table wd_profiles            enable row level security;
alter table wd_player_stats        enable row level security;
alter table wd_runs                enable row level security;
alter table wd_achievement_claims  enable row level security;

-- Boards are public; nothing is directly writable by anon or authenticated.
create policy wd_profiles_read on wd_profiles     for select to anon, authenticated using (true);
create policy wd_stats_read    on wd_player_stats for select to anon, authenticated using (true);
create policy wd_runs_own      on wd_runs         for select to authenticated
  using (exists (select 1 from wd_profiles p
                 where p.id = wd_runs.player_id and p.owner_uid = auth.uid()));

revoke insert, update, delete on wd_profiles, wd_player_stats,
  wd_runs, wd_achievement_claims from anon, authenticated;

revoke all on function wd_touch_player(jsonb), wd_log_run(jsonb, text) from anon, authenticated;
grant execute on function submit_classic_result(jsonb), submit_rank_result(jsonb),
  submit_endless_result(jsonb), submit_time_trial(jsonb), submit_challenge_result(jsonb),
  update_player_profile(jsonb), claim_achievement_reward(jsonb) to anon, authenticated;
