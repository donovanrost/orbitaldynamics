defmodule Mix.Tasks.OrbitalDynamics.Study.Run do
  @moduledoc """
  Runs a study from a JSON manifest and writes a compact result artifact.

  Usage:

      mix orbital_dynamics.study.run --manifest studies/leo_access_demo.json --output study_results/manifest_run.json
      mix orbital_dynamics.study.run --manifest studies/leo_access_demo.json --output study_results/manifest_run.json --generated-at 2026-05-14T00:00:00Z
      mix orbital_dynamics.study.run --manifest studies/leo_access_demo.json --output study_results/manifest_run.json --run-id leo_access_demo-20260514 --generated-at 2026-05-14T00:00:00Z
      mix orbital_dynamics.study.run --manifest studies/leo_access_demo.json --output /tmp/manifest_run.json --format json
      mix orbital_dynamics.study.run --manifest studies/leo_access_demo.json --output study_results/manifest_run.json --resume
      mix orbital_dynamics.study.run --manifest studies/leo_access_demo.json --retry-failed-from study_results/failed_run.json --output study_results/retry_run.json
  """

  use Mix.Task

  alias OrbitalDynamics.ResultSet.Artifact
  alias OrbitalDynamics.Study.Manifest
  alias OrbitalDynamics.StudyRunner

  @shortdoc "Runs a study from a JSON manifest"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    opts = parse_args!(args)
    manifest_path = Keyword.fetch!(opts, :manifest)

    {:ok, manifest} =
      manifest_path
      |> Manifest.from_file()
      |> case do
        {:ok, manifest} -> {:ok, manifest}
        {:error, reason} -> Mix.raise("invalid study manifest: #{inspect(reason)}")
      end

    output_path =
      Keyword.get_lazy(opts, :output, fn -> default_output_path(manifest.study.id) end)

    format = Keyword.fetch!(opts, :format)
    run_opts = run_opts(manifest.run_opts, opts)

    case Keyword.get(opts, :retry_failed_from) do
      nil ->
        run_or_resume!(manifest, manifest_path, output_path, run_opts, opts, format)

      source_path ->
        retry_failed!(
          manifest,
          manifest_path,
          source_path,
          output_path,
          run_opts,
          opts,
          format
        )
    end
  end

  defp parse_args!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          manifest: :string,
          output: :string,
          generated_at: :string,
          run_id: :string,
          format: :string,
          resume: :boolean,
          retry_failed_from: :string
        ]
      )

    unless rest == [] and invalid == [] do
      Mix.raise("invalid study run arguments: #{inspect(rest ++ invalid)}")
    end

    unless Keyword.has_key?(parsed, :manifest) do
      Mix.raise("--manifest is required")
    end

    format = Keyword.get(parsed, :format, "text")

    unless format in ["text", "json"] do
      Mix.raise("--format must be text or json")
    end

    if Keyword.get(parsed, :resume, false) and Keyword.has_key?(parsed, :retry_failed_from) do
      Mix.raise("--resume and --retry-failed-from cannot be used together")
    end

    Keyword.put(parsed, :format, format)
  end

  defp run_or_resume!(manifest, manifest_path, output_path, run_opts, opts, format) do
    if Keyword.get(opts, :resume, false) and File.exists?(output_path) do
      artifact = resume_artifact!(output_path, manifest_path, manifest, opts)
      print_summary(summary_from_artifact(artifact, manifest_path, output_path, true), format)
      :ok
    else
      result_set = run_study!(manifest.study, run_opts)
      artifact = Artifact.build(result_set, generated_at: generated_at(opts))
      Artifact.write_json!(artifact, output_path)

      print_summary(summary(result_set, artifact, manifest_path, output_path, false), format)
    end
  end

  defp retry_failed!(
         manifest,
         manifest_path,
         source_path,
         output_path,
         run_opts,
         opts,
         format
       ) do
    if Path.expand(source_path) == Path.expand(output_path) do
      Mix.raise("--retry-failed-from must differ from --output to preserve source evidence")
    end

    source_artifact = retry_source_artifact!(source_path, manifest_path, manifest)
    execution_report = Map.get(source_artifact, "execution_report")

    retry_source = %{
      path: source_path,
      sha256: source_path |> File.read!() |> sha256(),
      run_id: get_in(source_artifact, ["run", "id"]),
      generated_at: Map.get(source_artifact, "generated_at")
    }

    result_set =
      case StudyRunner.retry_failed(
             manifest.study,
             execution_report,
             Keyword.put(run_opts, :retry_source, retry_source)
           ) do
        {:ok, result_set} -> result_set
        {:error, reason} -> Mix.raise(retry_error_message(reason))
      end

    artifact = Artifact.build(result_set, generated_at: generated_at(opts))
    Artifact.write_json!(artifact, output_path)

    print_summary(summary(result_set, artifact, manifest_path, output_path, false), format)
  end

  defp run_study!(study, run_opts) do
    case OrbitalDynamics.run_study(study, run_opts) do
      {:ok, result_set} -> result_set
      {:error, reason} -> Mix.raise("study run failed: #{inspect(reason)}")
    end
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

  defp run_opts(manifest_run_opts, opts) do
    case Keyword.get(opts, :run_id) do
      nil -> manifest_run_opts
      run_id -> Keyword.put(manifest_run_opts, :run_id, run_id)
    end
  end

  defp default_output_path(study_id) do
    Path.join("study_results", "#{study_id}_result.json")
  end

  defp print_summary(summary, "json") do
    summary
    |> :json.encode()
    |> IO.iodata_to_binary()
    |> Mix.shell().info()
  end

  defp print_summary(summary, "text") do
    Mix.shell().info("")
    Mix.shell().info("OrbitalDynamics manifest study")
    Mix.shell().info("manifest: #{summary["manifest"]}")
    Mix.shell().info("study: #{summary["study"]}")
    Mix.shell().info("run: #{summary["run_id"]}")
    Mix.shell().info("generated_at: #{summary["generated_at"]}")
    Mix.shell().info("trajectories: #{summary["trajectory_count"]}")
    Mix.shell().info("event result groups: #{summary["event_result_group_count"]}")
    Mix.shell().info("access windows: #{summary["access_window_count"]}")
    Mix.shell().info("eclipse intervals: #{summary["eclipse_interval_count"]}")
    Mix.shell().info("errors: #{summary["error_count"]}")

    if summary["retry_failed"] do
      Mix.shell().info("retry source: #{summary["retry_source"]}")

      Mix.shell().info(
        "retried scenario indexes: #{inspect(summary["retried_scenario_indexes"])}"
      )
    end

    Mix.shell().info("#{summary["output_action"]}: #{summary["output"]}")
  end

  defp summary(result_set, artifact, manifest_path, output_path, resumed?) do
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

    %{
      "manifest" => manifest_path,
      "output" => output_path,
      "study" => to_string(result_set.study_id),
      "run_id" => run_id(result_set),
      "generated_at" => artifact.generated_at,
      "trajectory_count" => length(result_set.trajectory_results),
      "event_result_group_count" => length(result_set.event_results),
      "access_window_count" => access_window_count,
      "eclipse_interval_count" => eclipse_interval_count,
      "error_count" => length(result_set.errors),
      "resumed" => resumed?,
      "output_action" => if(resumed?, do: "reused", else: "wrote")
    }
    |> add_retry_summary(result_set)
  end

  defp summary_from_artifact(artifact, manifest_path, output_path, resumed?) do
    run = Map.get(artifact, "run", %{})
    run_metadata = Map.get(run, "metadata", %{})
    output_count = Map.get(run_metadata, "output_count", %{})

    %{
      "manifest" => manifest_path,
      "output" => output_path,
      "study" => to_string(Map.get(artifact, "study_id", "unknown")),
      "run_id" => Map.get(run, "id", "unknown"),
      "generated_at" => Map.get(artifact, "generated_at"),
      "trajectory_count" =>
        output_count_value(output_count, "trajectories", Map.get(artifact, "trajectories", [])),
      "event_result_group_count" =>
        output_count_value(output_count, "event_results", event_sections(artifact)),
      "access_window_count" => length(Map.get(artifact, "access_windows", [])),
      "eclipse_interval_count" => length(Map.get(artifact, "eclipse_intervals", [])),
      "error_count" => length(Map.get(artifact, "errors", [])),
      "resumed" => resumed?,
      "output_action" => if(resumed?, do: "reused", else: "wrote")
    }
  end

  defp resume_artifact!(output_path, manifest_path, manifest, opts) do
    case Artifact.resume_check(output_path,
           study_id: manifest.study.id,
           manifest_path: manifest_path,
           run_id: Keyword.get(opts, :run_id)
         ) do
      {:ok, artifact} ->
        artifact

      {:error, reason} ->
        Mix.raise(resume_error_message(reason))
    end
  end

  defp retry_source_artifact!(source_path, manifest_path, manifest) do
    case Artifact.resume_check(source_path,
           study_id: manifest.study.id,
           manifest_path: manifest_path
         ) do
      {:ok, artifact} ->
        artifact

      {:error, reason} ->
        Mix.raise("cannot retry failed scenarios: #{retry_source_error_message(reason)}")
    end
  end

  defp retry_error_message(:no_failed_scenarios),
    do: "cannot retry failed scenarios: source execution report has no failed scenarios"

  defp retry_error_message(reason),
    do: "cannot retry failed scenarios: invalid retry plan #{inspect(reason)}"

  defp retry_source_error_message(%{reason: :invalid_artifact, errors: errors}),
    do: "source artifact is invalid: #{inspect(errors)}"

  defp retry_source_error_message(%{
         reason: :study_id_mismatch,
         expected: expected,
         actual: actual
       }),
       do: "source study #{inspect(actual)} does not match manifest study #{inspect(expected)}"

  defp retry_source_error_message(%{reason: :manifest_sha_mismatch}),
    do: "source artifact manifest sha does not match"

  defp retry_source_error_message(%{reason: :read_error, path: path, error: error}),
    do: "could not read source artifact #{path}: #{inspect(error)}"

  defp retry_source_error_message(%{reason: :invalid_json, error: error}),
    do: "source artifact is invalid JSON: #{error}"

  defp retry_source_error_message(%{reason: :manifest_read_error, path: path, error: error}),
    do: "manifest #{path} could not be read: #{inspect(error)}"

  defp retry_source_error_message(reason), do: "invalid source artifact: #{inspect(reason)}"

  defp resume_error_message(%{reason: :invalid_artifact, errors: errors}) do
    "cannot resume from invalid study artifact: #{inspect(errors)}"
  end

  defp resume_error_message(%{reason: :study_id_mismatch, expected: expected, actual: actual}) do
    "cannot resume from study artifact for #{inspect(actual)} with manifest study #{inspect(expected)}"
  end

  defp resume_error_message(%{reason: :manifest_sha_mismatch}) do
    "cannot resume from study artifact whose manifest sha does not match"
  end

  defp resume_error_message(%{reason: :run_id_mismatch, expected: expected, actual: actual}) do
    "cannot resume from study artifact run #{inspect(actual)} with requested run #{inspect(expected)}"
  end

  defp resume_error_message(%{reason: :read_error, path: path, error: error}) do
    "cannot resume from #{path}: #{inspect(error)}"
  end

  defp resume_error_message(%{reason: :invalid_json, error: error}) do
    "cannot resume from invalid JSON artifact: #{error}"
  end

  defp resume_error_message(%{reason: :manifest_read_error, path: path, error: error}) do
    "cannot resume because manifest #{path} could not be read: #{inspect(error)}"
  end

  defp resume_error_message(reason), do: "cannot resume from study artifact: #{inspect(reason)}"

  defp output_count_value(output_count, key, fallback_list) do
    case Map.get(output_count, key) do
      value when is_integer(value) -> value
      _ -> length(fallback_list)
    end
  end

  defp event_sections(artifact) do
    [
      Map.get(artifact, "access_windows", []),
      Map.get(artifact, "eclipse_intervals", []),
      Map.get(artifact, "target_visibility_windows", []),
      Map.get(artifact, "ground_track_crossings", [])
    ]
    |> Enum.reject(&(&1 == []))
  end

  defp add_retry_summary(summary, result_set) do
    case Map.get(result_set.assumptions, :retry) || Map.get(result_set.assumptions, "retry") do
      %{} = retry ->
        source_artifact =
          Map.get(retry, :source_artifact) || Map.get(retry, "source_artifact") || %{}

        Map.merge(summary, %{
          "retry_failed" => true,
          "retry_source" => Map.get(source_artifact, :path) || Map.get(source_artifact, "path"),
          "retried_scenario_count" =>
            Map.get(retry, :scenario_count) || Map.get(retry, "scenario_count"),
          "retried_scenario_indexes" =>
            Map.get(retry, :scenario_indexes) || Map.get(retry, "scenario_indexes")
        })

      _value ->
        summary
    end
  end

  defp run_id(result_set) do
    run = Map.get(result_set.metadata, :run) || Map.get(result_set.metadata, "run") || %{}
    Map.get(run, :id) || Map.get(run, "id") || "unknown"
  end

  defp sha256(content) do
    :crypto.hash(:sha256, content)
    |> Base.encode16(case: :lower)
  end
end
