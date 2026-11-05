defmodule Mix.Tasks.OrbitalDynamics.Mission.Benchmark do
  use Mix.Task
  @shortdoc "Benchmark the synthetic 1/3/6-spacecraft mission and tiny exact assignment cases"
  alias OrbitalDynamics.MissionAnalysis.{
    ReferenceMission,
    ConstellationBenchmark,
    AssignmentQualityCases
  }

  @impl true
  def run(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          output_dir: [:string, :keep],
          repeats: [:integer, :keep],
          sizes: [:string, :keep],
          strategy: [:string, :keep],
          max_trials: [:integer, :keep]
        ]
      )

    unless rest == [] and invalid == [] and length(Keyword.get_values(opts, :output_dir)) == 1 and
             length(opts) == length(Enum.uniq(Keyword.keys(opts))),
           do:
             Mix.raise("required: --output-dir DIRECTORY; optional: --sizes 1,3,6 --repeats 1..5")

    repeats = Keyword.get(opts, :repeats, 1)

    sizes =
      Keyword.get(opts, :sizes, "1,3,6")
      |> String.split(",")
      |> Enum.map(fn s ->
        case Integer.parse(s) do
          {n, ""} when n in 1..6 -> n
          _ -> Mix.raise("sizes must be unique comma-separated integers in 1..6")
        end
      end)

    unless repeats in 1..5 and length(sizes) == length(Enum.uniq(sizes)),
      do: Mix.raise("invalid repeats or duplicate sizes")

    search_config =
      case {opts[:strategy], opts[:max_trials]} do
        {nil, nil} ->
          nil

        {strategy, n}
        when strategy in ["greedy", "bounded_reassignment", "bounded_replacement"] and
               is_integer(n) and n in 1..64 ->
          %{"strategy" => strategy, "max_trials" => n}

        _ ->
          Mix.raise(
            "strategy/max-trials require --strategy greedy|bounded_reassignment|bounded_replacement --max-trials 1..64"
          )
      end

    Mix.Task.run("app.start")
    mission = ReferenceMission.load!("studies/small_constellation.json")
    study = ReferenceMission.load!("studies/small_constellation_planning.json")
    study = if search_config, do: Map.put(study, "scheduling", search_config), else: study

    search_policy =
      if search_config,
        do: OrbitalDynamics.MissionAnalysis.Scheduling.Reference.policy!(search_config),
        else: nil

    directory = Path.expand(opts[:output_dir])
    File.mkdir_p!(directory)

    runs =
      for size <- sizes, repeat <- 1..repeats do
        Mix.shell().info("Planning #{size} spacecraft, repetition #{repeat}...")
        {summary, report} = ConstellationBenchmark.run_case!(mission, study, size)
        name = "report-#{size}-#{repeat}.json.gz"

        File.write!(
          Path.join(directory, name),
          :zlib.gzip(IO.iodata_to_binary(:json.encode(report)))
        )

        summary = Map.merge(summary, %{"repeat" => repeat, "report_file" => name})

        File.write!(Path.join(directory, "summary-#{size}-#{repeat}.json"), [
          :json.encode(summary),
          "\n"
        ])

        summary
      end

    summary = %{
      "format" => "constellation_benchmark.v1",
      "runs" => runs,
      "mission_configuration" => mission,
      "planning_configuration" => study,
      "quality_cases" => AssignmentQualityCases.run!(search_policy),
      "runtime" => %{
        "elixir" => System.version(),
        "otp" => System.otp_release(),
        "schedulers_online" => System.schedulers_online(),
        "architecture" => to_string(:erlang.system_info(:system_architecture)),
        "mix_env" => Atom.to_string(Mix.env()),
        "warmup_runs" => 0
      },
      "limits" => [
        "synthetic assumptions, not company specifications",
        "finite sampled feasibility; no operational acceptance",
        "nested fleet prefixes and fixed demand; no claim of general scaling law",
        "tiny exact quality cases do not bound the physical mission optimum"
      ]
    }

    File.write!(Path.join(directory, "summary.json"), [:json.encode(summary), "\n"])
    File.write!(Path.join(directory, "README.md"), ConstellationBenchmark.markdown(summary))
    Mix.shell().info("Benchmark written to #{Path.join(directory, "README.md")}")
  end
end
