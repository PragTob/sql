import SQL
import Ecto.Query
defmodule SQL.Repo do
  use Ecto.Repo, otp_app: :sql, adapter: Ecto.Adapters.Postgres
end
Application.put_env(:sql, :ecto_repos, [SQL.Repo])
Application.put_env(:sql, SQL.Repo, username: "postgres", password: "postgres", hostname: "localhost", database: "sql_test#{System.get_env("MIX_TEST_PARTITION")}", pool: Ecto.Adapters.SQL.Sandbox, pool_size: 10)
SQL.Repo.__adapter__().storage_up(SQL.Repo.config())
SQL.Repo.start_link()

Benchee.run(
  %{
    "to_string" => fn -> to_string(~SQL[with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)]) end,
    "to_sql" => fn -> SQL.to_sql(~SQL[with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)]) end,
    "inspect" => fn -> inspect(~SQL[with recursive temp (n, fact) as (select 0, 1 union all select n+1, (n+1)*fact from temp where n < 9)]) end,
    "ecto" => fn -> SQL.Repo.to_sql(:all, "temp" |> recursive_ctes(true) |> with_cte("temp", as: ^union_all(select("temp", [t], %{n: 0, fact: 1}), ^where(select("temp", [t], [t.n+1, t.n+1*t.fact]), [t], t.n < 9))) |> select([t], [t.n])) end
  },
  time: 3,
  warmup: 2,
  memory_time: 2
)
