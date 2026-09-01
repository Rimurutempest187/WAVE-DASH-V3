create or replace function wd_board(p_board text, p_limit int, p_offset int)
returns table (
  rank bigint, player_id text, display_name text, avatar text,
  rank_tier text, rank_stars int, classic_stars int, levels_completed int,
  endless_best bigint, total_distance bigint, best_time_ms int,
  challenge_clears int, total_score bigint, coins bigint, diamonds bigint,
  level_id int
) language sql stable security definer set search_path = public as $$
  with ordered as (
    select s.*, pr.display_name, pr.avatar,
      row_number() over (order by
        case p_board
          when 'rank'      then s.rank_stars
          when 'classic'   then s.classic_stars
          when 'endless'   then s.endless_best
          when 'challenge' then s.challenge_clears
          when 'coins'     then s.coins
          when 'diamonds'  then s.diamonds
          else 0 end desc,
        case when p_board = 'trial' then s.best_time_ms end asc nulls last,
        s.total_score desc, s.updated_at asc) as rn
    from wd_player_stats s
    join wd_profiles pr on pr.id = s.player_id
    where p_board <> 'trial' or s.best_time_ms is not null
  )
  select rn, player_id, display_name, avatar, rank_tier, rank_stars,
         classic_stars, levels_completed, endless_best, total_distance,
         best_time_ms, challenge_clears, total_score, coins, diamonds, 0
  from ordered
  order by rn
  limit greatest(least(coalesce(p_limit,40),100),1)
  offset greatest(coalesce(p_offset,0),0);

$$;

create or replace function get_rank_leaderboard(p_limit int default 40, p_offset int default 0)
returns setof record language sql stable as $$ select * from wd_board('rank',$1,$2) $$;
-- repeat verbatim for classic / endless / trial / challenge / coins / diamonds,
-- changing only the function name and the board literal.

create or replace function get_player_rank(p_player_id text, p_board text)
returns table (rank bigint) language sql stable security definer set search_path = public as $$
  select rank from wd_board(p_board, 100000, 0) where player_id = p_player_id;

$$;
