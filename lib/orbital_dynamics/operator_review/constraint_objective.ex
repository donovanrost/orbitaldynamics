defmodule OrbitalDynamics.OperatorReview.ConstraintObjective do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def constraint_package(report) do
    {rows, source_artifact_id, provenance} = constraint_package_input(report)

    build_package(rows, "constraint_report.v1", source_artifact_id, provenance)
  end

  def objective_satisfaction_package(report) do
    {rows, source_artifact_id, provenance} = objective_satisfaction_package_input(report)

    build_package(rows, "objective_satisfaction_report.v1", source_artifact_id, provenance)
  end

  def constraint_package_input(report) do
    report = stringify_keys(report || %{})

    {
      source_constraint_report_rows(report, "constraint_report"),
      constraint_report_id(report),
      Map.get(report, "provenance", %{})
    }
  end

  def objective_satisfaction_package_input(report) do
    report = stringify_keys(report || %{})

    {
      source_objective_satisfaction_report_rows(report, "objective_satisfaction_report"),
      Map.get(report, "id") || Map.get(report, "source") || "objective_satisfaction_report",
      Map.get(report, "provenance", %{})
    }
  end

  def constraint_rows(rows, source \\ "constraint_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.reject(fn {row, _index} -> Map.get(row, "status") == "pass" end)
    |> Enum.map(fn {row, index} ->
      constraint_id = row["constraint_id"]
      scenario_id = row["scenario_id"]
      status = row["status"] || "unknown"

      %{
        "id" => review_id(["constraint", constraint_id, scenario_id, index]),
        "review_type" => "constraint_review",
        "source" => source,
        "subject_id" => scenario_id || constraint_id || "constraint_report",
        "scenario_id" => scenario_id,
        "constraint_id" => constraint_id,
        "metric" => row["metric"],
        "operator" => row["operator"],
        "threshold" => row["threshold"],
        "value" => row["value"],
        "score" => row["score"],
        "violation_severity" => row["violation_severity"],
        "constraint_status" => status,
        "action" => "review_constraint",
        "required_operator_action" => "review_constraint",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "reason" => constraint_reason(row),
        "source_constraint_row" => row
      }
      |> compact_map()
    end)
  end

  def constraint_report_id(report) do
    review_id([
      "constraint_report",
      Map.get(report, "id") || get_in(report, ["assumptions", "source"]) || report["status"]
    ])
  end

  def objective_satisfaction_rows(rows, source \\ "objective_satisfaction_report.rows") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.reject(fn {row, _index} -> objective_satisfaction_pass_status?(row["status"]) end)
    |> Enum.map(fn {row, index} ->
      objective = row["objective"]
      target_id = row["target_id"]
      row_id = row["id"]

      %{
        "id" => review_id(["objective_satisfaction", objective, target_id || row_id, index]),
        "review_type" => "objective_satisfaction_review",
        "source" => source,
        "subject_id" => target_id || row_id || objective || "objective_satisfaction",
        "objective" => objective,
        "objective_status" => row["status"],
        "target_id" => target_id,
        "required_count" => row["required_count"],
        "candidate_count" => row["candidate_count"],
        "selected_count" => row["selected_count"],
        "satisfied_count" => row["satisfied_count"],
        "candidate_target_ids" => row["candidate_target_ids"],
        "selected_target_ids" => row["selected_target_ids"],
        "selected_activity_ids" => row["selected_activity_ids"],
        "selected_contact_ids" => row["selected_contact_ids"],
        "required_downlink_mb" => row["required_downlink_mb"],
        "candidate_downlink_mb" => row["candidate_downlink_mb"],
        "selected_downlink_mb" => row["selected_downlink_mb"],
        "satisfied_downlink_mb" => row["satisfied_downlink_mb"],
        "action" => "review_objective_satisfaction",
        "required_operator_action" => "review_objective_satisfaction",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "reason" => objective_satisfaction_reason(row),
        "source_objective_satisfaction" => row
      }
      |> compact_map()
    end)
  end

  def candidate_refresh_rows(artifact) do
    artifact = stringify_keys(artifact)

    candidate_refresh_constraint_rows(artifact) ++
      candidate_refresh_objective_satisfaction_rows(artifact)
  end

  defp candidate_refresh_constraint_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_constraint_report", artifact["source_constraint_report"]},
        {"candidate_refresh.constraint_report", artifact["constraint_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_constraint_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_constraint_rows(artifact)
  end

  defp source_constraint_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_constraint_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_constraint_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> constraint_rows("#{source}.rows")
  end

  defp source_constraint_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_constraint_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_constraint_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_constraint_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_constraint_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_constraint_rows(
         %{"schema_contract" => "constraint_report.v1"} = report,
         source
       ) do
    source_constraint_report_rows(report, source)
  end

  defp result_artifact_constraint_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_constraint_report", artifact["source_constraint_report"]},
      {"#{source}.constraint_report", artifact["constraint_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_constraint_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_constraint_rows(_artifact, _source), do: []

  defp candidate_refresh_objective_satisfaction_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_objective_satisfaction_report",
         artifact["source_objective_satisfaction_report"]},
        {"candidate_refresh.objective_satisfaction_report",
         artifact["objective_satisfaction_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_objective_satisfaction_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_objective_satisfaction_rows(artifact)
  end

  defp source_objective_satisfaction_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_objective_satisfaction_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_objective_satisfaction_report_rows(%{} = report, source) do
    report
    |> stringify_keys()
    |> Map.get("rows", [])
    |> objective_satisfaction_rows("#{source}.rows")
  end

  defp source_objective_satisfaction_report_rows(_report, _source), do: []

  defp candidate_refresh_result_artifact_objective_satisfaction_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_objective_satisfaction_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_objective_satisfaction_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_objective_satisfaction_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_objective_satisfaction_rows(
         %{"schema_contract" => "objective_satisfaction_report.v1"} = report,
         source
       ) do
    source_objective_satisfaction_report_rows(report, source)
  end

  defp result_artifact_objective_satisfaction_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_objective_satisfaction_report",
       artifact["source_objective_satisfaction_report"]},
      {"#{source}.objective_satisfaction_report", artifact["objective_satisfaction_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_objective_satisfaction_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_objective_satisfaction_rows(_artifact, _source), do: []

  defp constraint_reason(row) do
    status = row["status"] || "unknown"
    constraint_id = row["constraint_id"] || "constraint"
    subject = row["scenario_id"] || row["subject_id"] || "artifact"
    metric = row["metric"] || "metric"
    operator = row["operator"] || "operator"
    threshold = row["threshold"] || "threshold"

    "review #{status} constraint #{constraint_id} for #{subject}: #{metric} #{operator} #{threshold}"
  end

  defp objective_satisfaction_pass_status?(status)
       when status in ["met", "selected", "no_requirement"],
       do: true

  defp objective_satisfaction_pass_status?(_status), do: false

  defp objective_satisfaction_reason(row) do
    status = row["status"] || "unknown"
    objective = row["objective"] || "objective"
    subject = row["target_id"] || row["id"] || "objective_satisfaction"

    "review #{status} objective #{objective} for #{subject}"
  end

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

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
