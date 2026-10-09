-- Reglas configurables de The Crown Games.
-- La partida lee esta tabla; el progreso y los descubrimientos permanecen en user:// local.

create table if not exists public.cardgame_reglas_v1 (
  clave text primary key,
  configuracion jsonb not null default '{}'::jsonb,
  activo boolean not null default true,
  version integer not null default 1 check (version > 0),
  updated_at timestamptz not null default now()
);

alter table public.cardgame_reglas_v1 enable row level security;

drop policy if exists "Las reglas activas de CardGame son legibles" on public.cardgame_reglas_v1;
create policy "Las reglas activas de CardGame son legibles"
  on public.cardgame_reglas_v1
  for select
  to anon, authenticated
  using (activo = true);

grant select on public.cardgame_reglas_v1 to anon, authenticated;

insert into public.cardgame_reglas_v1 (clave, configuracion, activo, version)
values (
  'reglas_base',
  '{
    "aventura": {
      "tablero_lado": 3,
      "vida_jugador": 30,
      "ataque_jugador": 5,
      "movimiento_jugador": 1,
      "acciones_por_turno": 2,
      "casilla_jugador_inicio": 7,
      "casilla_criatura_inicio": 1,
      "alcance_ataque_jugador": 1
    },
    "combate_tactico": {
      "acciones_por_turno": 2,
      "mano_maxima": 8,
      "mano_inicial": 5,
      "etherium_maximo": 10,
      "crecimiento_etherium_turno": 1,
      "vida_rey": 30,
      "ataque_rey": 5
    }
  }'::jsonb,
  true,
  1
)
on conflict (clave) do update
set configuracion = excluded.configuracion,
    activo = excluded.activo,
    version = excluded.version,
    updated_at = now();
