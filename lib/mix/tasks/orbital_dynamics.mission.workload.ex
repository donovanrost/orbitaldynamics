defmodule Mix.Tasks.OrbitalDynamics.Mission.Workload do
  use Mix.Task

  @shortdoc "Compare greedy, reassignment and replacement on repeated-service and fixed-time cases"
  @moduledoc """
  Runs a reference attitude study under three strategies. Defaults to
  studies/repeated_service_planning.json and four trials including the baseline.

      MIX_ENV=test mix orbital_dynamics.mission.workload --output-dir tmp/repeated_service

  Optional: --study PATH --max-trials 1..64. Studies must declare attitude,
  path constraints, horizon, and battery resources for every asset. The manifest
  path is resolved relative to the study, as in the mission attitude task.
  """
  alias OrbitalDynamics.MissionAnalysis.{ReferenceMission, ServiceWorkload}

  @impl true
  def run(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          output_dir: [:string, :keep],
          study: [:string, :keep],
          max_trials: [:integer, :keep]
        ]
      )

    unless rest == [] and invalid == [] and length(Keyword.get_values(opts, :output_dir)) == 1 and
             length(opts) == length(Enum.uniq(Keyword.keys(opts))),
           do:
             Mix.raise(
               "required: --output-dir DIRECTORY; optional: --study PATH --max-trials 1..64"
             )

    trials = Keyword.get(opts, :max_trials, 4)

    unless is_integer(trials) and trials in 1..64,
      do: Mix.raise("max-trials must be 1..64 including baseline")

    study_path = Path.expand(Keyword.get(opts, :study, "studies/repeated_service_planning.json"))
    study = ReferenceMission.load!(study_path)

    unless Enum.all?(~w(attitude path_constraints resources horizon), &is_map(study[&1])),
      do: Mix.raise("workload study requires attitude, path_constraints, resources and horizon")

    mission_path = Path.expand(study["mission_manifest"], Path.dirname(study_path))
    mission = ReferenceMission.load!(mission_path)
    directory = canonical_path(Path.expand(opts[:output_dir]))

    outputs =
      for name <-
            ~w(summary.json README.md report-greedy.json.gz report-bounded_reassignment.json.gz report-bounded_replacement.json.gz summary-greedy.json summary-bounded_reassignment.json summary-bounded_replacement.json),
          do: Path.join(directory, name)

    inputs = Enum.map([study_path, mission_path], &canonical_path/1)

    for output <- outputs do
      if output in inputs, do: Mix.raise("outputs must not overwrite study or mission inputs")

      case File.lstat(output) do
        {:ok, %{type: :symlink}} -> Mix.raise("output files must not be symlinks")
        _ -> :ok
      end
    end

    Mix.Task.run("app.start")

    Mix.shell().info(
      "Comparing repeated service on #{length(mission["assets"])} assets and #{length(mission["requests"])} requests..."
    )

    File.mkdir_p!(directory)

    on_run = fn run, report ->
      name = run["strategy"]

      File.write!(
        Path.join(directory, "report-#{name}.json.gz"),
        :zlib.gzip(IO.iodata_to_binary(:json.encode(report)))
      )

      File.write!(Path.join(directory, "summary-#{name}.json"), [:json.encode(run), "\n"])
    end

    {summary, _reports} = ServiceWorkload.run!(mission, study, trials, on_run)

    File.write!(Path.join(directory, "summary.json"), [:json.encode(summary), "\n"])
    File.write!(Path.join(directory, "README.md"), ServiceWorkload.markdown(summary))
    Mix.shell().info("Workload comparison written to #{Path.join(directory, "README.md")}")
  end

  defp canonical_path(path, links \\ 0)

  defp canonical_path(_, links) when links > 64,
    do: Mix.raise("output path contains a symlink cycle")

  defp canonical_path("/", _), do: "/"

  defp canonical_path(path, links) do
    parent = canonical_path(Path.dirname(path), links)
    resolved = Path.join(parent, Path.basename(path))

    case File.read_link(resolved) do
      {:ok, target} -> canonical_path(Path.expand(target, parent), links + 1)
      {:error, _} -> resolved
    end
  end
end
