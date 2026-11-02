defmodule Mix.Tasks.OrbitalDynamics.Mission.Resolution do
  use Mix.Task
  @shortdoc "Compare sampling and integration resolution with refined service windows"
  alias OrbitalDynamics.MissionAnalysis.{ReferenceMission, ReferenceResolution, ResolutionStudy}
  alias OrbitalDynamics.MissionAnalysis.Models.SurfaceSupport

  @impl true
  def run(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args, strict: [study: :string, output_dir: :string])

    unless rest == [] and invalid == [] and Enum.sort(Keyword.keys(opts)) == [:output_dir, :study],
      do: Mix.raise("required: --study PATH --output-dir DIRECTORY")

    Mix.Task.run("app.start")
    study = ReferenceMission.load!(opts[:study])

    SurfaceSupport.fields!(
      study,
      ~w(study_id baseline_manifest levels reference_level_id refinement window_time_tolerance_s schedule_time_tolerance_s margin_thresholds),
      "resolution study"
    )

    SurfaceSupport.fields!(
      study["refinement"],
      ~w(tracking_lookback_s time_tolerance_s max_extra_evaluations),
      "refinement settings"
    )

    refinement = study["refinement"]

    refinement_opts = [
      tracking_lookback_s: refinement["tracking_lookback_s"],
      time_tolerance_s: refinement["time_tolerance_s"],
      max_extra_evaluations: refinement["max_extra_evaluations"]
    ]

    baseline_path =
      Path.expand(study["baseline_manifest"], Path.dirname(Path.expand(opts[:study])))

    baseline = ReferenceMission.load!(baseline_path)

    report =
      ResolutionStudy.run!(
        study["levels"],
        &ReferenceResolution.evaluate(baseline, &1, refinement_opts),
        study_id: study["study_id"],
        reference_level_id: study["reference_level_id"],
        window_time_tolerance_s: study["window_time_tolerance_s"],
        schedule_time_tolerance_s: study["schedule_time_tolerance_s"],
        margin_thresholds: study["margin_thresholds"]
      )
      |> Map.put("baseline_configuration", baseline)
      |> Map.put("study_configuration", study)

    directory = Path.expand(opts[:output_dir])

    outputs = [
      {"report.json", [:json.encode(report), "\n"]},
      {"comparison.csv", ResolutionStudy.csv(report)},
      {"README.md", ResolutionStudy.markdown(report)}
    ]

    for {name, _} <- outputs do
      if Path.join(directory, name) in [Path.expand(opts[:study]), baseline_path],
        do: Mix.raise("output must not overwrite inputs")
    end

    File.mkdir_p!(directory)
    Enum.each(outputs, fn {name, bytes} -> File.write!(Path.join(directory, name), bytes) end)

    Mix.shell().info(
      "#{length(report["levels"])} resolution levels; #{report["error_level_count"]} errors. #{Path.join(directory, "README.md")}"
    )

    if report["error_level_count"] > 0,
      do: Mix.raise("resolution comparison incomplete; inspect report.json errors")
  end
end
