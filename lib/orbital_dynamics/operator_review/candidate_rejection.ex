defmodule OrbitalDynamics.OperatorReview.CandidateRejection do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def report_package(report) do
    {rows, source_artifact_id, provenance} = report_package_input(report)

    build_package(rows, "candidate_rejection_report.v1", source_artifact_id, provenance)
  end

  def report_package_input(report) do
    report = stringify_keys(report || %{})

    {
      report_rows(report, "candidate_rejection_report"),
      Map.get(report, "id") || Map.get(report, "source") || "candidate_rejection_report",
      Map.get(report, "provenance", %{})
    }
  end

  def rows(rows, source) do
    rows
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&review_row?/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      candidate_id = row["candidate_id"] || row["activity_id"] || "candidate_rejection:#{index}"
      action = row["required_operator_action"] || "review_candidate_rejection"
      reason = row["primary_rejection_reason"] || "candidate_rejected"

      %{
        "id" => review_id(["candidate_rejection_review", candidate_id, index]),
        "review_type" => "candidate_rejection_review",
        "source" => source,
        "subject_id" => candidate_id,
        "candidate_id" => candidate_id,
        "activity_id" => row["activity_id"] || candidate_id,
        "timeline_id" => row["timeline_id"],
        "activity_type" => row["activity_type"],
        "operational_kind" => row["operational_kind"],
        "source_window_id" => row["source_window_id"],
        "source_window_type" => row["source_window_type"],
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => "operator_review_required",
        "reason" => "candidate rejection requires review: #{reason}",
        "candidate_rejection_status" => row["rejection_status"],
        "candidate_rejection_reasons" => row["rejection_reasons"],
        "primary_rejection_reason" => row["primary_rejection_reason"],
        "candidate_rejection_reason_count" => row["reason_count"],
        "reviewable" => row["reviewable"],
        "violated_constraint" => row["violated_constraint"],
        "required_margin" => row["required_margin"],
        "actual_margin" => row["actual_margin"],
        "activity_context" => row["activity_context"],
        "source_candidate_rejection" => row
      }
      |> compact_map()
    end)
  end

  defp review_row?(row) do
    row["rejection_status"] == "rejected" and row["reviewable"] == true
  end

  def report_rows(report, source) do
    report = stringify_keys(report || %{})

    report
    |> Map.get("rows", [])
    |> rows(source <> ".rows")
  end

  def candidate_refresh_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_candidate_rejection_report",
         artifact["source_candidate_rejection_report"]},
        {"candidate_refresh.candidate_rejection_report", artifact["candidate_rejection_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  def source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  def source_report_rows(%{} = report, source),
    do: report_rows(report, source)

  def source_report_rows(_report, _source), do: []

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
         %{"schema_contract" => "candidate_rejection_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_candidate_rejection_report",
       artifact["source_candidate_rejection_report"]},
      {"#{source}.candidate_rejection_report", artifact["candidate_rejection_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

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
