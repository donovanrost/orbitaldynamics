defmodule Mix.Tasks.OrbitalDynamics.Mission.Scaling do
  use Mix.Task

  @shortdoc "Bounded opt-in 6–100 spacecraft scaling study with optional statistical stack profile"
  alias OrbitalDynamics.MissionAnalysis.ConstellationScaling

  def run(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          output_dir: [:string, :keep],
          sizes: [:string, :keep],
          requests: [:integer, :keep],
          profile: [:boolean, :keep],
          full_diagnostics: [:boolean, :keep],
          memory_mb: [:integer, :keep],
          timeout_s: [:integer, :keep]
        ]
      )

    unless rest == [] and invalid == [] and is_binary(opts[:output_dir]) and
             length(opts) == length(Enum.uniq(Keyword.keys(opts))),
           do:
             Mix.raise(
               "required --output-dir DIR; optional --sizes 6,25,50,100 --requests 9 --profile --full-diagnostics --memory-mb 6000 --timeout-s 900"
             )

    sizes =
      String.split(Keyword.get(opts, :sizes, "6,25,50,100"), ",")
      |> Enum.map(fn x ->
        case Integer.parse(x) do
          {n, ""} when n in 6..100 -> n
          _ -> Mix.raise("sizes must be unique integers in 6..100")
        end
      end)

    demand = Keyword.get(opts, :requests, 9)
    mem = Keyword.get(opts, :memory_mb, 6000)
    timeout = Keyword.get(opts, :timeout_s, 900)

    unless length(sizes) == length(Enum.uniq(sizes)) and demand in 1..100 and mem in 16..8000 and
             timeout in 1..1800,
           do: Mix.raise("invalid scaling controls")

    dir = Path.expand(opts[:output_dir])
    if File.exists?(dir), do: Mix.raise("fresh output directory required")
    Mix.Task.run("app.start")
    File.mkdir_p!(dir)

    runtime = %{
      "elixir" => System.version(),
      "otp" => System.otp_release(),
      "schedulers_online" => System.schedulers_online(),
      "architecture" => to_string(:erlang.system_info(:system_architecture)),
      "warmup_runs" => 0
    }

    File.write!(Path.join(dir, "runtime.json"), :json.encode(runtime), [:exclusive])

    runs =
      Enum.reduce_while(sizes, [], fn size, rows ->
        Mix.shell().info("Scaling #{size} spacecraft / #{demand} requests")

        result =
          ConstellationScaling.run_case!(size, demand,
            max_memory_bytes: mem * 1_000_000,
            timeout_ms: timeout * 1000,
            profile: Keyword.get(opts, :profile, false),
            full_diagnostics: Keyword.get(opts, :full_diagnostics, false)
          )

        File.write!(Path.join(dir, "summary-#{size}.json"), :json.encode(result), [:exclusive])
        Mix.shell().info("#{size}: #{result["status"]}")
        rows = rows ++ [result]
        if ConstellationScaling.supported?(result), do: {:cont, rows}, else: {:halt, rows}
      end)

    report = %{
      "format" => "constellation_scaling.v1",
      "runtime" => runtime,
      "runs" => runs,
      "unprocessed_sizes" => Enum.drop(sizes, length(runs)),
      "limits" => [
        "Synthetic clustered short-horizon fleet; no global constellation design or operational acceptance",
        "Fixed demand measures fleet cost; most spacecraft may be idle",
        "Sampled VM memory is not peak RSS and may miss brief peaks; compilation/report persistence excluded from planner clock",
        "Summary digests establish compact projection parity, not complete report identity or independent physical validation"
      ]
    }

    File.write!(Path.join(dir, "summary.json"), :json.encode(report), [:exclusive])

    File.write!(Path.join(dir, "README.md"), ConstellationScaling.markdown(report), [:exclusive])

    unless length(runs) == length(sizes) and Enum.all?(runs, &ConstellationScaling.supported?/1),
      do: Mix.raise("scaling cases incomplete/unsupported; inspect saved summaries")
  end
end
