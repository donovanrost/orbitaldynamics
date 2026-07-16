defmodule OrbitalDynamics.OperatorReview.CandidateDiff do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  @candidate_diff_scoped_context_fields ~w(
    target_id
    target_ids
    collection_id
    collection_ids
    product_id
    product_ids
    payload_id
    payload_ids
    instrument_id
    instrument_ids
    objective_id
    objective_ids
    objective_type
    objective_types
    objective_status
    objective_statuses
    source_objective_status
    source_objective_statuses
    latency_objective
    max_latency_s
    planned_latency_s
    required_contacts
    planned_contacts
    required_downlink_mb
    planned_downlink_mb
    contact_result
    contact_results
    realized_status
    realized_statuses
    source_activity_id
    source_activity_ids
    missed_downlink_activity_id
    missed_downlink_activity_ids
    feedback_source
    feedback_sources
    feedback_scope
    feedback_scopes
    trust_boundary
    trust_boundaries
    derivation_reasons
    candidate_downlink_mb
    downlink_completion_ratio
    selected_downlink_shortfall_mb
    downlink_requirement_status
    downlink_completion_source
    downlink_completion_sources
  )

  def report_package(report) do
    {rows, source_artifact_id, provenance} = report_package_input(report)

    build_package(rows, "candidate_diff_report.v1", source_artifact_id, provenance)
  end

  def invalidated_candidate_package(candidate) do
    {rows, source_artifact_id, provenance} = invalidated_candidate_package_input(candidate)

    build_package(rows, "invalidated_candidate.v1", source_artifact_id, provenance)
  end

  def report_package_input(report) do
    report = stringify_keys(report || %{})

    {
      report_rows(
        report,
        "candidate_diff_report",
        Map.get(report, "source_window_lineage", [])
      ),
      Map.get(report, "id") || Map.get(report, "source") || "candidate_diff_report",
      Map.get(report, "provenance", %{})
    }
  end

  def invalidated_candidate_package_input(candidate) do
    candidate = stringify_keys(candidate || %{})

    {
      rows([candidate], "invalidated_candidate"),
      Map.get(candidate, "id") || Map.get(candidate, "invalidated_candidate_id") ||
        "invalidated_candidate",
      Map.get(candidate, "provenance", %{})
    }
  end

  def report_rows(report, source_prefix, source_window_lineage \\ []) do
    report = stringify_keys(report || %{})
    invalidated_candidates = Map.get(report, "invalidated_candidates", [])
    lineage_by_candidate_id = source_window_lineage_by_candidate_id(source_window_lineage)

    rows(
      invalidated_candidates,
      source_prefix <> ".invalidated_candidates",
      lineage_by_candidate_id
    ) ++
      rows(
        reviewable_new_rows(
          Map.get(report, "new_candidates", []),
          invalidated_candidates
        ),
        source_prefix <> ".new_candidates",
        lineage_by_candidate_id
      ) ++
      rows(
        reviewable_retained_rows(Map.get(report, "retained_candidates", [])),
        source_prefix <> ".retained_candidates",
        lineage_by_candidate_id
      )
  end

  defp source_window_lineage_by_candidate_id(source_window_lineage) do
    source_window_lineage
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(is_map(&1) and is_binary(&1["candidate_activity_id"])))
    |> Map.new(&{&1["candidate_activity_id"], &1})
  end

  defp reviewable_new_rows(candidates, invalidated_candidates) do
    reviewed_replacement_ids =
      invalidated_candidates
      |> List.wrap()
      |> Enum.map(&stringify_keys/1)
      |> Enum.map(& &1["replacement_candidate_id"])
      |> Enum.reject(&is_nil/1)
      |> MapSet.new()

    candidates
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.reject(&MapSet.member?(reviewed_replacement_ids, &1["id"]))
    |> Enum.filter(&reviewable_new_candidate_diff_row?/1)
  end

  defp reviewable_new_candidate_diff_row?(candidate) do
    List.wrap(candidate["semantic_change_reasons"]) != [] or
      not is_nil(candidate["semantic_match_status"]) or
      candidate["diff_reason"] in [
        "semantically_similar_prior_candidate_changed",
        "ambiguous_semantic_prior_candidate_match"
      ]
  end

  defp reviewable_retained_rows(candidates) do
    candidates
    |> List.wrap()
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(List.wrap(&1["semantic_change_reasons"]) != []))
  end

  def candidate_refresh_rows(artifact) do
    source_window_lineage = Map.get(artifact, "source_window_lineage", [])

    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_candidate_diff_report",
         get_in(artifact, ["accepted_planning_state", "source_candidate_diff_report"])},
        {"candidate_refresh.accepted_planning_state.candidate_diff_report",
         get_in(artifact, ["accepted_planning_state", "candidate_diff_report"])},
        {"candidate_refresh.mission_state.source_candidate_diff_report",
         get_in(artifact, ["mission_state", "source_candidate_diff_report"])},
        {"candidate_refresh.mission_state.candidate_diff_report",
         get_in(artifact, ["mission_state", "candidate_diff_report"])},
        {"candidate_refresh.source_candidate_diff_report",
         artifact["source_candidate_diff_report"]},
        {"candidate_refresh.candidate_diff_report", artifact["candidate_diff_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source, source_window_lineage)
      end)

    direct_rows ++ candidate_refresh_result_artifact_candidate_diff_rows(artifact)
  end

  defp source_report_rows(reports, source, source_window_lineage)
       when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]", source_window_lineage)
    end)
  end

  defp source_report_rows(%{} = report, source, source_window_lineage) do
    report = stringify_keys(report)
    report_source_window_lineage = Map.get(report, "source_window_lineage", source_window_lineage)

    report_rows(report, source, report_source_window_lineage)
  end

  defp source_report_rows(_report, _source, _source_window_lineage), do: []

  defp candidate_refresh_result_artifact_candidate_diff_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_candidate_diff_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_candidate_diff_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_candidate_diff_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_candidate_diff_rows(
         %{"schema_contract" => "candidate_diff_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source, [])
  end

  defp result_artifact_candidate_diff_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_candidate_diff_report", artifact["source_candidate_diff_report"]},
      {"#{source}.candidate_diff_report", artifact["candidate_diff_report"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_report_rows(report_or_reports, report_source, [])
    end)
  end

  defp result_artifact_candidate_diff_rows(_artifact, _source), do: []

  def rows(candidates, source, lineage_by_candidate_id \\ %{}) do
    candidates
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {candidate, index} ->
      candidate_id =
        candidate["id"] || candidate["invalidated_candidate_id"] || "candidate_diff:#{index}"

      source_window_lineage = lineage_by_candidate_id[candidate_id]

      replacement_source_window_lineage =
        lineage_by_candidate_id[candidate["replacement_candidate_id"]]

      action = candidate["required_operator_action"] || "review_candidate_diff"

      reason =
        candidate["invalidated_reason"] || candidate["diff_reason"] ||
          "candidate refresh changed candidate"

      invalidated_candidate_id =
        candidate["invalidated_candidate_id"] ||
          if(candidate["invalidated_reason"], do: candidate_id)

      semantic_change_reasons = semantic_change_reasons(candidate)
      changed_fields = candidate_diff_changed_fields(candidate)

      %{
        "id" => review_id(["candidate_diff_review", candidate_id, index]),
        "review_type" => "candidate_diff_review",
        "source" => source,
        "subject_id" => candidate_id,
        "activity_id" => candidate_id,
        "activity_type" => candidate["type"] || candidate["activity_type"],
        "scenario_id" => candidate["scenario_id"],
        "target_id" => candidate["target_id"],
        "source_target_id" => candidate["source_target_id"],
        "source_target" => candidate["source_target"],
        "target_latitude_deg" => candidate["target_latitude_deg"],
        "target_longitude_deg" => candidate["target_longitude_deg"],
        "target_minimum_elevation_deg" => candidate["target_minimum_elevation_deg"],
        "target_priority" => candidate["target_priority"],
        "target_priority_source" => candidate["target_priority_source"],
        "target_priority_objective_ids" => candidate["target_priority_objective_ids"],
        "target_priority_objective_type" => candidate["target_priority_objective_type"],
        "ground_station_id" => candidate["ground_station_id"],
        "direction" => candidate["direction"],
        "source_window_id" => candidate["source_window_id"],
        "source_window_type" =>
          candidate["source_window_type"] || source_window_lineage_type(source_window_lineage),
        "source_window" => source_window_from_lineage(source_window_lineage),
        "source_window_lineage" => source_window_lineage,
        "replacement_source_window_id" =>
          replacement_source_window_id(candidate, replacement_source_window_lineage),
        "replacement_source_window_type" =>
          source_window_lineage_type(replacement_source_window_lineage),
        "replacement_source_window" =>
          source_window_from_lineage(replacement_source_window_lineage),
        "replacement_source_window_lineage" => replacement_source_window_lineage,
        "starts_at_s" => candidate["starts_at_s"],
        "ends_at_s" => candidate["ends_at_s"],
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => candidate["approval_status"] || "operator_review_required",
        "reason" => "candidate diff requires review: #{reason}",
        "operator_action_reason" => candidate["operator_action_reason"],
        "candidate_diff" => candidate,
        "invalidated_candidate_id" => invalidated_candidate_id,
        "invalidated_candidate_ids" => candidate["invalidated_candidate_ids"],
        "replacement_candidate_id" => candidate["replacement_candidate_id"],
        "invalidated_reason" => candidate["invalidated_reason"],
        "semantic_change_reasons" => semantic_change_reasons,
        "semantic_change_details" => candidate["semantic_change_details"],
        "changed_fields" => changed_fields,
        "candidate_diff_changed_fields" => changed_fields,
        "candidate_diff_changed_field_count" =>
          candidate_diff_changed_field_count(changed_fields),
        "candidate_diff_match_status" => candidate["candidate_diff_match_status"],
        "candidate_diff_match_count" => candidate["candidate_diff_match_count"],
        "semantic_match_status" => candidate["semantic_match_status"],
        "semantic_match_candidate_count" => candidate["semantic_match_candidate_count"],
        "semantic_match_candidate_ids" => candidate["semantic_match_candidate_ids"],
        "candidate_budget_match_status" => candidate["candidate_budget_match_status"],
        "candidate_budget_match_count" => candidate["candidate_budget_match_count"],
        "budget_dropped_candidate_ids" => candidate["budget_dropped_candidate_ids"],
        "invalid_prior_candidate_input" => candidate["invalid_prior_candidate_input"],
        "invalid_prior_candidate_input_reason" =>
          candidate["invalid_prior_candidate_input_reason"],
        "source_candidate" => candidate["source_candidate"],
        "source_candidate_diff" => candidate
      }
      |> Map.merge(candidate_diff_scoped_context(candidate))
      |> compact_map()
    end)
  end

  defp candidate_diff_scoped_context(candidate) do
    candidate
    |> Map.take(@candidate_diff_scoped_context_fields)
    |> compact_map()
  end

  defp candidate_diff_changed_fields(row) do
    row
    |> Map.get("candidate_diff_changed_fields", Map.get(row, "changed_fields"))
    |> List.wrap()
    |> Enum.concat(semantic_change_detail_fields(row["semantic_change_details"]))
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp semantic_change_reasons(row) do
    detail_reasons = semantic_change_detail_reasons(row["semantic_change_details"])

    case detail_reasons do
      [] ->
        row
        |> Map.get("semantic_change_reasons")
        |> List.wrap()
        |> Enum.filter(&is_binary/1)
        |> Enum.uniq()

      reasons ->
        reasons
    end
  end

  defp semantic_change_detail_reasons(details) do
    details
    |> List.wrap()
    |> Enum.map(&Map.get(&1, "reason"))
    |> Enum.filter(&is_binary/1)
    |> Enum.uniq()
  end

  defp semantic_change_detail_fields(details) do
    details
    |> List.wrap()
    |> Enum.map(&Map.get(&1, "field"))
  end

  defp candidate_diff_changed_field_count([]), do: nil
  defp candidate_diff_changed_field_count(fields), do: length(fields)

  defp replacement_source_window_id(candidate, nil), do: candidate["replacement_source_window_id"]

  defp replacement_source_window_id(candidate, lineage) do
    candidate["replacement_source_window_id"] || lineage["source_window_id"] ||
      get_in(lineage, ["source_window", "id"])
  end

  defp source_window_lineage_type(nil), do: nil

  defp source_window_lineage_type(lineage) do
    lineage["source_window_type"] || get_in(lineage, ["source_window", "type"])
  end

  defp source_window_from_lineage(nil), do: nil

  defp source_window_from_lineage(lineage), do: lineage["source_window"]

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
