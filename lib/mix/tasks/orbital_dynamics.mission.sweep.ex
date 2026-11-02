defmodule Mix.Tasks.OrbitalDynamics.Mission.Sweep do
  use Mix.Task
  @shortdoc "Compare a bounded grid of configurable reference missions"
  alias OrbitalDynamics.MissionAnalysis.{ReferenceMission, TradeStudy}
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport

  @impl true
  def run(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args, strict: [study: :string, output_dir: :string])

    unless rest == [] and invalid == [] and Enum.sort(Keyword.keys(opts)) == [:output_dir, :study],
      do: Mix.raise("required: --study PATH --output-dir DIRECTORY")

    Mix.Task.run("app.start")
    study = ReferenceMission.load!(opts[:study])
    SurfaceSupport.fields!(study, ~w(study_id baseline_manifest max_cases axes), "trade study")

    unless is_binary(study["baseline_manifest"]),
      do: Mix.raise("baseline_manifest must be a path")

    base_path = Path.expand(study["baseline_manifest"], Path.dirname(Path.expand(opts[:study])))
    base = ReferenceMission.load!(base_path)

    evaluator = fn config ->
      try do
        {:ok, ReferenceMission.run!(config)}
      rescue
        e in [ArgumentError, KeyError, MatchError] -> {:error, Exception.message(e)}
      end
    end

    report =
      TradeStudy.run!(base, study["axes"], evaluator,
        study_id: study["study_id"],
        max_cases: study["max_cases"]
      )

    directory = Path.expand(opts[:output_dir])

    outputs = [
      {"report.json", [:json.encode(report), "\n"]},
      {"comparison.csv", TradeStudy.csv(report)},
      {"metrics.csv", TradeStudy.metric_csv(report)},
      {"checks.csv", TradeStudy.check_csv(report)},
      {"README.md", TradeStudy.markdown(report)}
    ]

    for {name, _} <- outputs do
      if Path.join(directory, name) in [Path.expand(opts[:study]), base_path],
        do: Mix.raise("output must not overwrite study or baseline manifest")
    end

    File.mkdir_p!(directory)
    Enum.each(outputs, fn {name, bytes} -> File.write!(Path.join(directory, name), bytes) end)

    Mix.shell().info(
      "#{report["case_count"]} cases + baseline; #{report["error_case_count"]} case errors. Comparison: #{Path.join(directory, "README.md")}"
    )
  end
end
