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

# Operating System: Linux
# CPU Information: AMD Ryzen 9 5900X 12-Core Processor
# Number of Available Cores: 24
# Available memory: 31.26 GB
# Elixir 1.18.3
# Erlang 27.3.2
# JIT enabled: true

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 3 s
# memory time: 2 s
# reduction time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 28 s

# Benchmarking ecto ...
# Benchmarking inspect ...
# Benchmarking to_sql ...
# Benchmarking to_string ...
# Calculating statistics...
# Formatting results...

# Name                ips        average  deviation         median         99th %
# to_sql          10.47 M       95.53 ns ±41507.95%          40 ns          90 ns
# to_string        8.03 M      124.51 ns ±42277.22%          50 ns         120 ns
# inspect          1.75 M      569.90 ns  ±8174.08%         330 ns         870 ns
# ecto            0.152 M     6559.75 ns   ±279.27%        6130 ns    11821.90 ns

# Comparison:
# to_sql          10.47 M
# to_string        8.03 M - 1.30x slower +28.99 ns
# inspect          1.75 M - 5.97x slower +474.37 ns
# ecto            0.152 M - 68.67x slower +6464.22 ns

# Memory usage statistics:

# Name         Memory usage
# to_sql              136 B
# to_string           112 B - 0.82x memory usage -24 B
# inspect             776 B - 5.71x memory usage +640 B
# ecto              18640 B - 137.06x memory usage +18504 B
