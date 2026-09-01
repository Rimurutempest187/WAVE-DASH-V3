create extension if not exists pgcrypto;

create table if not exists wd_profiles (
  id           text primary key
                 check (id ~ '^player_[a-z0-9]{8,32}$'),
  display_name text not null
                 check (char_length(display_name) between 3 and 16
                        and display_name ~ '^[A-Za-z0-9 _.-]+$'),
  avatar       text not null default 'classic'
                 check (avatar ~ '^[a-z0-9_-]{1,32}$'),
  owner_uid    uuid references auth.users(id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists wd_profiles_owner_idx on wd_profiles(owner_uid);
