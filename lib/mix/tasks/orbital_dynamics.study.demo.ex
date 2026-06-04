defmodule Mix.Tasks.OrbitalDynamics.Study.Demo do
  @moduledoc """
  Runs a small LEO access-window and eclipse demo study.

  Usage:

      mix orbital_dynamics.study.demo
      mix orbital_dynamics.study.demo --output study_results/leo_access_demo.json
      mix orbital_dynamics.study.demo --output study_results/leo_access_demo.json --run-id leo_access_demo-20260514 --generated-at 2026-05-14T00:00:00Z
  """

  use Mix.Task

  alias OrbitalDynamics.Benchmark.ScenarioFixture
  alias OrbitalDynamics.Propagators.J2
  alias OrbitalDynamics.ResultSet.Artifact
  alias OrbitalDynamics.{CentralBody, GroundStation, Study}

  @shortdoc "Runs a demo LEO access-window and eclipse study"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    opts = parse_args!(args)
    output_path = Keyword.get(opts, :output, "study_results/leo_access_demo.json")
    generated_at = generated_at(opts)

    earth = CentralBody.earth()

    scenarios =
      ScenarioFixture.circular_leo(
        count: 2,
        duration_s: 3_600.0,
        output_step_s: 60.0,
        id_prefix: "leo_access_demo"
      )

    stations = [
      GroundStation.new!(:equator_prime, 0.0, 0.0, minimum_elevation_deg: 5.0),
      GroundStation.new!(:equator_90e, 0.0, 90.0, minimum_elevation_deg: 5.0)
    ]

    study =
      Study.new!(:leo_access_demo, scenarios,
        propagator: J2,
        propagator_opts: [max_step_s: 10.0],
        outputs: [:trajectories, :access_windows, :eclipses],
        metadata: %{description: "Demo LEO J2 access-window and eclipse study"}
      )

    {:ok, result_set} =
      study
      |> OrbitalDynamics.run_study(
        run_opts(opts,
          ground_stations: stations,
          central_body: earth,
          sun_direction: {1.0, 0.0, 0.0},
          max_concurrency: System.schedulers_online()
        )
      )

    artifact = Artifact.build(result_set, generated_at: generated_at)
    Artifact.write_json!(artifact, output_path)
    print_summary(result_set, output_path)
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          output: :string,
          generated_at: :string,
          run_id: :string
        ]
      )

    unless rest == [] and invalid == [] do
      Mix.raise("invalid demo arguments: #{inspect(rest ++ invalid)}")
    end

    parsed
  end

  defp generated_at(opts) do
    case Keyword.get(opts, :generated_at) do
      nil ->
        DateTime.utc_now()

      value ->
        case DateTime.from_iso8601(value) do
          {:ok, generated_at, _offset} ->
            generated_at

          {:error, reason} ->
            Mix.raise("invalid --generated-at: #{inspect(reason)}")
        end
    end
  end

  defp run_opts(opts, run_opts) do
    case Keyword.get(opts, :run_id) do
      nil -> run_opts
      run_id -> Keyword.put(run_opts, :run_id, run_id)
    end
  end

  defp print_summary(result_set, output_path) do
    access_window_count =
      result_set.event_results
      |> Enum.filter(&(&1.event_type == :ground_station_access))
      |> Enum.flat_map(& &1.events)
      |> length()

    eclipse_interval_count =
      result_set.event_results
      |> Enum.filter(&(&1.event_type == :eclipse))
      |> Enum.flat_map(& &1.events)
      |> length()

    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics LEO access and eclipse demo")
    Mix.shell().info("study: #{result_set.study_id}")
    Mix.shell().info("trajectories: #{length(result_set.trajectory_results)}")
    Mix.shell().info("event result groups: #{length(result_set.event_results)}")
    Mix.shell().info("access windows: #{access_window_count}")
    Mix.shell().info("eclipse intervals: #{eclipse_interval_count}")
    Mix.shell().info("errors: #{length(result_set.errors)}")
    Mix.shell().info("wrote: #{output_path}")
  end
end
