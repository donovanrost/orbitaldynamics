defmodule OrbitalDynamics.OperatorReview.ModelAcceptance do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def package(report) do
    {rows, source_artifact_id, provenance} = package_input(report)

    build_package(rows, "model_acceptance_report.v1", source_artifact_id, provenance)
  end

  def package_input(report) do
    report = stringify_keys(report || %{})

    {
      rows(report),
      Map.get(report, "report_id") || report_id(report),
      Map.get(report, "provenance", %{})
    }
  end

  def rows(report, source \\ "model_acceptance_report.rows") do
    report = stringify_keys(report)

    report
    |> Map.get("rows", [])
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&reviewable_row?/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      model_id = row["model_id"] || row["id"] || "model_acceptance"
      status = row["status"] || "review_required"

      %{
        "id" =>
          review_id([
            "model_acceptance_review",
            stable_id_fragment(source),
            model_id,
            index
          ]),
        "review_type" => "model_acceptance_review",
        "source" => source,
        "subject_id" => model_id,
        "action" => action(status),
        "required_operator_action" => action(status),
        "approval_status" => approval_status(status),
        "reason" => row["reason"] || reason(report, row, status),
        "model_acceptance_report_id" => report["report_id"],
        "model_acceptance_status" => status,
        "model_acceptance_intended_use" => report["intended_use"],
        "model_acceptance_validation_level" => row["validation_level"],
        "model_acceptance_model_id" => row["model_id"],
        "model_acceptance_implementation" => row["implementation"],
        "model_acceptance_model_count" => report["model_count"],
        "model_acceptance_accepted_count" => report["accepted_count"],
        "model_acceptance_review_required_count" => report["review_required_count"],
        "model_acceptance_blocked_count" => report["blocked_count"],
        "model_acceptance_unknown_model_count" => report["unknown_model_count"],
        "source_model_acceptance_row" => row,
        "source_model_acceptance_report" => context(report)
      }
      |> compact_map()
    end)
  end

  def report_id(report) do
    review_id([
      "model_acceptance_report",
      report["intended_use"],
      report["status"],
      report["model_count"]
    ])
  end

  def candidate_refresh_rows(artifact) do
    artifact = stringify_keys(artifact)

    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_model_acceptance_report",
         get_in(artifact, ["accepted_planning_state", "source_model_acceptance_report"])},
        {"candidate_refresh.accepted_planning_state.model_acceptance_report",
         get_in(artifact, ["accepted_planning_state", "model_acceptance_report"])},
        {"candidate_refresh.mission_state.source_model_acceptance_report",
         get_in(artifact, ["mission_state", "source_model_acceptance_report"])},
        {"candidate_refresh.mission_state.model_acceptance_report",
         get_in(artifact, ["mission_state", "model_acceptance_report"])},
        {"candidate_refresh.source_model_acceptance_report",
         artifact["source_model_acceptance_report"]},
        {"candidate_refresh.model_acceptance_report", artifact["model_acceptance_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  defp source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_report_rows(%{} = report, source), do: rows(report, "#{source}.rows")
  defp source_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_rows(
         %{"schema_contract" => "model_acceptance_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_model_acceptance_report", artifact["source_model_acceptance_report"]},
      {"#{source}.model_acceptance_report", artifact["model_acceptance_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  defp reviewable_row?(%{} = row),
    do: row["status"] not in [nil, "accepted", "accepted_for_use"]

  defp reviewable_row?(_row), do: false

  defp action("blocked"), do: "review_blocked_model_acceptance"
  defp action(_status), do: "review_model_acceptance"

  defp approval_status("blocked"), do: "blocked_by_policy"
  defp approval_status(_status), do: "operator_review_required"

  defp reason(report, row, status) do
    intended_use = report["intended_use"] || "intended use"
    model_id = row["model_id"] || "model"
    validation_level = row["validation_level"] || "unknown"

    "model #{model_id} is #{status} for #{intended_use} with #{validation_level} validation"
  end

  defp context(report) do
    Map.take(report, [
      "schema_contract",
      "schema_version",
      "model",
      "report_id",
      "intended_use",
      "status",
      "model_count",
      "accepted_count",
      "review_required_count",
      "blocked_count",
      "unknown_model_count",
      "status_counts",
      "validation_level_counts",
      "model_ids_by_status",
      "model_ids_by_validation_level",
      "model_ids_by_intended_use",
      "assumptions",
      "model_limits"
    ])
  end

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stable_id_fragment(nil), do: nil

  defp stable_id_fragment(value) when is_binary(value) do
    value
    |> String.replace(~r/[^A-Za-z0-9._:@-]/, "_")
    |> String.trim("_")
    |> case do
      "" ->
        "root"

      fragment ->
        if Regex.match?(~r/^[A-Za-z0-9]/, fragment) do
          fragment
        else
          "path:#{fragment}"
        end
    end
  end

  defp stable_id_fragment(value), do: encode_value(value)

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp build_package(rows, source_artifact_type, source_artifact_id, provenance) do
    PackageBuilder.build(
      rows,
      source_artifact_type,
      source_artifact_id,
      provenance,
      @schema_contract,
      Capabilities.model_limits()
    )
  end
end
