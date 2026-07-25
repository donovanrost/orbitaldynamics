defmodule OrbitalDynamics.OperatorReview.TimelinePreservation do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def report_package(report) do
    {rows, source_artifact_id, provenance} = report_package_input(report)

    build_package(rows, "timeline_preservation_report.v1", source_artifact_id, provenance)
  end

  def status_package(status) do
    {rows, source_artifact_id, provenance} = status_package_input(status)

    build_package(rows, "timeline_preservation_status.v1", source_artifact_id, provenance)
  end

  def candidate_refresh_rows(artifact) do
    direct_rows =
      candidate_refresh_sources(artifact)
      |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
        source_rows(artifact_or_artifacts, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  def report_package_input(report) do
    report = stringify_keys(report || %{})
    report = Map.put_new(report, "schema_contract", "timeline_preservation_report.v1")

    {
      report_rows(report),
      Map.get(report, "id") || Map.get(report, "source") || "timeline_preservation_report",
      Map.get(report, "provenance", %{})
    }
  end

  def status_package_input(status) do
    status = stringify_keys(status || %{})
    status = Map.put_new(status, "schema_contract", "timeline_preservation_status.v1")

    {
      status_rows(status, "timeline_preservation_status.status"),
      source_id(status, "timeline_preservation_status"),
      Map.get(status, "provenance", %{})
    }
  end

  def report_rows(%{} = report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      review_row(row, index, "timeline_preservation_report.rows", report, row)
    end)
  end

  def status_rows(%{} = status, source) do
    [review_row(status, 1, source, status, status)]
  end

  def source_id(status, fallback) do
    Map.get(status, "id") || Map.get(status, "source") || Map.get(status, "timeline_id") ||
      Map.get(status, "activity_id") || fallback
  end

  defp candidate_refresh_sources(artifact) do
    [
      {"candidate_refresh.accepted_planning_state.source_timeline_preservation_report",
       get_in(artifact, ["accepted_planning_state", "source_timeline_preservation_report"])},
      {"candidate_refresh.accepted_planning_state.timeline_preservation_report",
       get_in(artifact, ["accepted_planning_state", "timeline_preservation_report"])},
      {"candidate_refresh.accepted_planning_state.source_timeline_preservation_status",
       get_in(artifact, ["accepted_planning_state", "source_timeline_preservation_status"])},
      {"candidate_refresh.accepted_planning_state.timeline_preservation_status",
       get_in(artifact, ["accepted_planning_state", "timeline_preservation_status"])},
      {"candidate_refresh.mission_state.source_timeline_preservation_report",
       get_in(artifact, ["mission_state", "source_timeline_preservation_report"])},
      {"candidate_refresh.mission_state.timeline_preservation_report",
       get_in(artifact, ["mission_state", "timeline_preservation_report"])},
      {"candidate_refresh.mission_state.source_timeline_preservation_status",
       get_in(artifact, ["mission_state", "source_timeline_preservation_status"])},
      {"candidate_refresh.mission_state.timeline_preservation_status",
       get_in(artifact, ["mission_state", "timeline_preservation_status"])},
      {"candidate_refresh.source_timeline_preservation_report",
       artifact["source_timeline_preservation_report"]},
      {"candidate_refresh.timeline_preservation_report",
       artifact["timeline_preservation_report"]},
      {"candidate_refresh.source_timeline_preservation_status",
       artifact["source_timeline_preservation_status"]},
      {"candidate_refresh.timeline_preservation_status", artifact["timeline_preservation_status"]}
    ]
  end

  defp source_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      source_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp source_rows(%{"schema_contract" => "timeline_preservation_report.v1"} = report, source) do
    source_report_rows(report, source)
  end

  defp source_rows(%{"schema_contract" => "timeline_preservation_status.v1"} = status, source) do
    source_status_rows(status, source)
  end

  defp source_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    cond do
      Map.has_key?(artifact, "rows") ->
        source_report_rows(artifact, source)

      Map.has_key?(artifact, "timeline_preservation_status") ->
        source_status_rows(artifact, source)

      true ->
        []
    end
  end

  defp source_rows(_artifact, _source), do: []

  def source_report_rows(nil, _source), do: []

  def source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  def source_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    report
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      review_row(row, index, "#{source}.rows", report, row)
    end)
  end

  def source_report_rows(_report, _source), do: []

  defp source_status_rows(%{} = status, source) do
    status = stringify_keys(status)
    [review_row(status, 1, "#{source}.status", status, status)]
  end

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

  defp result_artifact_rows(%{"schema_contract" => schema_contract} = artifact, source)
       when schema_contract in [
              "timeline_preservation_report.v1",
              "timeline_preservation_status.v1"
            ] do
    source_rows(artifact, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_preservation_report",
       artifact["source_timeline_preservation_report"]},
      {"#{source}.timeline_preservation_report", artifact["timeline_preservation_report"]},
      {"#{source}.source_timeline_preservation_status",
       artifact["source_timeline_preservation_status"]},
      {"#{source}.timeline_preservation_status", artifact["timeline_preservation_status"]}
    ]
    |> Enum.flat_map(fn {artifact_source, artifact_or_artifacts} ->
      source_rows(artifact_or_artifacts, artifact_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  defp review_row(row, index, source, summary, source_state) do
    subject_id = row["timeline_id"] || row["activity_id"]
    preservation_status = preservation_status(row, summary)
    protection_decision = row["protection_decision"]
    protection_category = row["protection_category"]
    protection_reason = row["protection_reason"] || row["reason"]

    %{
      "id" => review_id(["timeline_preservation", subject_id, index]),
      "review_type" => "timeline_preservation_review",
      "source" => source,
      "subject_id" => subject_id,
      "timeline_id" => row["timeline_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "timeline_preservation_status" => preservation_status,
      "requires_preservation" => requires_preservation?(row),
      "requires_operator_review" => requires_review?(row),
      "action" => required_operator_action(row),
      "required_operator_action" => required_operator_action(row),
      "approval_status" => approval_status(row),
      "reason" => protection_reason,
      "operator_action_reason" => protection_reason,
      "timeline_preservation_protection_decision" => protection_decision,
      "timeline_preservation_protection_category" => protection_category,
      "timeline_preservation_protection_reason" => protection_reason,
      "locked" => row["locked"],
      "approved" => row["approved"],
      "executed" => row["executed"],
      "status" => row["status"],
      "approval_status_value" => row["approval_status"],
      "invalid_activity_input" => row["invalid_activity_input"],
      "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
      "source_activity_count" => summary["activity_count"],
      "preserve_activity_count" => summary["preserve_activity_count"],
      "review_change_activity_count" => summary["review_change_activity_count"],
      "mutable_activity_count" => summary["mutable_activity_count"],
      "preservation_sensitive_activity_count" => summary["preservation_sensitive_activity_count"],
      "preserve_activity_ids" => summary["preserve_activity_ids"],
      "preserve_timeline_ids" => summary["preserve_timeline_ids"],
      "review_change_activity_ids" => summary["review_change_activity_ids"],
      "review_change_timeline_ids" => summary["review_change_timeline_ids"],
      "preservation_sensitive_activity_ids" => summary["preservation_sensitive_activity_ids"],
      "preservation_sensitive_timeline_ids" => summary["preservation_sensitive_timeline_ids"],
      "source_preservation_protection_category_counts" => summary["protection_category_counts"],
      "source_preservation_activity_id_sets_by_protection_category" =>
        summary["activity_id_sets_by_protection_category"],
      "source_preservation_timeline_id_sets_by_protection_category" =>
        summary["timeline_id_sets_by_protection_category"],
      "source_timeline_preservation" => source_state
    }
    |> compact_map()
  end

  defp preservation_status(%{"timeline_preservation_status" => status}, _summary), do: status

  defp preservation_status(%{"protection_decision" => "review_change"}, _summary),
    do: "review_required"

  defp preservation_status(%{"protection_decision" => "preserve"}, _summary),
    do: "preservation_required"

  defp preservation_status(_row, %{"timeline_preservation_status" => status}), do: status
  defp preservation_status(_row, _summary), do: "clear"

  defp requires_preservation?(%{"requires_preservation" => value}) when is_boolean(value),
    do: value

  defp requires_preservation?(%{"protection_decision" => "preserve"}), do: true
  defp requires_preservation?(_row), do: false

  defp requires_review?(%{"requires_operator_review" => value}) when is_boolean(value),
    do: value

  defp requires_review?(%{"protection_decision" => "review_change"}), do: true
  defp requires_review?(_row), do: false

  defp required_operator_action(%{"required_operator_action" => action}) when is_binary(action),
    do: action

  defp required_operator_action(%{"requires_operator_review" => true}),
    do: "review_timeline_preservation"

  defp required_operator_action(%{"protection_decision" => "review_change"}),
    do: "review_timeline_preservation"

  defp required_operator_action(%{"requires_preservation" => true}),
    do: "record_timeline_preservation"

  defp required_operator_action(%{"protection_decision" => "preserve"}),
    do: "record_timeline_preservation"

  defp required_operator_action(_row), do: "record_timeline_preservation"

  defp approval_status(row) do
    if requires_review?(row),
      do: "operator_review_required",
      else: "not_required"
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
