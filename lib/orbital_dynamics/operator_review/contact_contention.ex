defmodule OrbitalDynamics.OperatorReview.ContactContention do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def report_package(report) do
    {rows, source_artifact_id, provenance} = report_package_input(report)

    build_package(rows, "contact_contention_report.v1", source_artifact_id, provenance)
  end

  def resolution_package(report) do
    {rows, source_artifact_id, provenance} = resolution_package_input(report)

    build_package(
      rows,
      "contact_contention_resolution_report.v1",
      source_artifact_id,
      provenance
    )
  end

  def report_package_input(report) do
    report = stringify_keys(report || %{})

    {
      source_contact_contention_report_rows(report, "contact_contention_report"),
      Map.get(report, "id") || "contact_contention_report",
      Map.get(report, "provenance", %{})
    }
  end

  def resolution_package_input(report) do
    report = stringify_keys(report || %{})

    {
      source_resolution_report_rows(report, "contact_contention_resolution_report"),
      Map.get(report, "id") || "contact_contention_resolution_report",
      Map.get(report, "provenance", %{})
    }
  end

  def rows(recommendations),
    do:
      rows(
        recommendations,
        "campaign_plan.contact_contention_resolution_report.recommendations"
      )

  def rows(recommendations, source) do
    recommendations
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {recommendation, index} ->
      requirement = recommendation["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = recommendation["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(recommendation["policy_decision"] || %{})
      policy_escalation = recommendation |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["contact_contention", recommendation["group_id"], index]),
        "review_type" => "contact_contention_recommendation",
        "source" => source,
        "subject_id" => recommendation["group_id"],
        "action" =>
          Map.get(recommendation, "action", "recommend_preferred_contact_for_operator_review"),
        "required_operator_action" =>
          Map.get(recommendation, "action", "recommend_preferred_contact_for_operator_review"),
        "approval_status" => Map.get(recommendation, "review_status", "operator_review_required"),
        "reason" =>
          "resolve #{Map.get(recommendation, "ground_station_id", "station")} contact contention",
        "resource_scope" => recommendation["resource_scope"],
        "ground_station_id" => recommendation["ground_station_id"],
        "ground_station_ids" => recommendation["ground_station_ids"],
        "spacecraft_id" => recommendation["spacecraft_id"],
        "spacecraft_ids" => recommendation["spacecraft_ids"],
        "direction" => recommendation["direction"],
        "directions" => recommendation["directions"],
        "starts_at_s" => recommendation["starts_at_s"],
        "ends_at_s" => recommendation["ends_at_s"],
        "contention_window_s" => recommendation["contention_window_s"],
        "total_contact_duration_s" => recommendation["total_contact_duration_s"],
        "overlap_duration_s" => recommendation["overlap_duration_s"],
        "max_concurrent_contacts" => recommendation["max_concurrent_contacts"],
        "overlap_contact_pair_count" => recommendation["overlap_contact_pair_count"],
        "selected_contact_id" => recommendation["selected_contact_id"],
        "selected_contact_ids" => recommendation["selected_contact_ids"],
        "selected_priority" => recommendation["selected_priority"],
        "selected_priority_source" => recommendation["selected_priority_source"],
        "deferred_contact_ids" => Map.get(recommendation, "deferred_contact_ids", []),
        "review_contact_ids" => recommendation["review_contact_ids"],
        "deferred_contact_priorities" => recommendation["deferred_contact_priorities"],
        "candidate_count" => recommendation["candidate_count"],
        "selection_reason" => recommendation["selection_reason"],
        "resolution_selection_rule" => recommendation["resolution_selection_rule"],
        "resolution_priority_fields" => recommendation["resolution_priority_fields"],
        "requested_priority_fields" => recommendation["requested_priority_fields"],
        "priority_field_evidence_counts" => recommendation["priority_field_evidence_counts"],
        "priority_fields_without_numeric_evidence_count" =>
          recommendation["priority_fields_without_numeric_evidence_count"],
        "priority_fields_without_numeric_evidence" =>
          recommendation["priority_fields_without_numeric_evidence"],
        "resolution_priority_override_count" =>
          recommendation["resolution_priority_override_count"],
        "resolution_priority_override_contact_ids" =>
          recommendation["resolution_priority_override_contact_ids"],
        "ignored_priority_override_count" => recommendation["ignored_priority_override_count"],
        "ignored_priority_override_keys" => recommendation["ignored_priority_override_keys"],
        "ignored_priority_override_contact_ids" =>
          recommendation["ignored_priority_override_contact_ids"],
        "ignored_priority_override_input" => recommendation["ignored_priority_override_input"],
        "resolution_tie_breakers" => recommendation["resolution_tie_breakers"],
        "requested_selection_rule" => recommendation["requested_selection_rule"],
        "ignored_tie_breakers" => recommendation["ignored_tie_breakers"],
        "ignored_policy_input" => recommendation["ignored_policy_input"],
        "policy_warnings" => recommendation["policy_warnings"],
        "contact_success" => recommendation["contact_success"],
        "contact_success_factor" => recommendation["contact_success_factor"],
        "contact_success_factor_source" => recommendation["contact_success_factor_source"],
        "command_success" => recommendation["command_success"],
        "contact_result" => provider_result_artifact_value(recommendation["contact_result"]),
        "command_result" => provider_result_artifact_value(recommendation["command_result"]),
        "command_success_factor" => recommendation["command_success_factor"],
        "command_success_factor_source" => recommendation["command_success_factor_source"],
        "actual_throughput_mb" => recommendation["actual_throughput_mb"],
        "actual_data_rate_throughput_derivations" =>
          recommendation["actual_data_rate_throughput_derivations"],
        "resolution_status" => recommendation["resolution_status"],
        "resolution_issue" => recommendation["resolution_issue"],
        "capacity_pack_required_capacity_fraction" =>
          recommendation["capacity_pack_required_capacity_fraction"],
        "capacity_pack_selected_required_capacity_fraction" =>
          recommendation["capacity_pack_selected_required_capacity_fraction"],
        "capacity_pack_deferred_required_capacity_fraction" =>
          recommendation["capacity_pack_deferred_required_capacity_fraction"],
        "capacity_pack_required_capacity_fraction_by_status" =>
          recommendation["capacity_pack_required_capacity_fraction_by_status"],
        "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
          recommendation["capacity_pack_required_capacity_fraction_by_ground_station_id"],
        "required_capacity_fraction_source_counts" =>
          recommendation["required_capacity_fraction_source_counts"],
        "source_summary_model" => recommendation["source_summary_model"],
        "source_summary_schema_contract" => recommendation["source_summary_schema_contract"],
        "source_summary_source" => recommendation["source_summary_source"],
        "source_artifact_type" => recommendation["source_artifact_type"],
        "schema_contract" => recommendation["schema_contract"],
        "duplicate_contact_ids" => recommendation["duplicate_contact_ids"],
        "duplicate_contact_id_count" => recommendation["duplicate_contact_id_count"],
        "duplicate_contact_candidate_count" =>
          recommendation["duplicate_contact_candidate_count"],
        "duplicate_contact_candidates" => recommendation["duplicate_contact_candidates"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => recommendation["approval_requirements"],
        "approval_rule_matches" => recommendation["approval_rule_matches"],
        "source_policy_decision" => recommendation["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_contact_contention_resolution_summary" =>
          recommendation["source_contact_contention_resolution_summary"],
        "source_recommendation" => recommendation
      }
      |> Map.merge(Map.take(recommendation, station_calendar_context_fields()))
      |> compact_map()
    end)
  end

  def group_rows(groups, source \\ "contact_contention_report.conflict_groups") do
    groups
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {group, index} ->
      requirement = group["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = group["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(group["policy_decision"] || %{})
      policy_escalation = group |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["contact_contention_group", group["id"], index]),
        "review_type" => "contact_contention_review",
        "source" => source,
        "subject_id" => group["id"],
        "resource_scope" => group["resource_scope"],
        "ground_station_id" => group["ground_station_id"],
        "ground_station_ids" => group["ground_station_ids"],
        "spacecraft_id" => group["spacecraft_id"],
        "spacecraft_ids" => group["spacecraft_ids"],
        "starts_at_s" => group["starts_at_s"],
        "ends_at_s" => group["ends_at_s"],
        "direction" => group["direction"],
        "directions" => group["directions"],
        "contact_count" => group["contact_count"],
        "contention_window_s" => group["contention_window_s"],
        "total_contact_duration_s" => group["total_contact_duration_s"],
        "overlap_duration_s" => group["overlap_duration_s"],
        "max_concurrent_contacts" => group["max_concurrent_contacts"],
        "overlap_contact_pair_count" => group["overlap_contact_pair_count"],
        "contact_ids" => Map.get(group, "contact_ids", []),
        "duplicate_contact_ids" => group["duplicate_contact_ids"],
        "duplicate_contact_id_count" => group["duplicate_contact_id_count"],
        "duplicate_contact_candidate_count" => group["duplicate_contact_candidate_count"],
        "source_contact_candidates" => group["source_contact_candidates"],
        "contact_success" => group["contact_success"],
        "contact_success_factor" => group["contact_success_factor"],
        "contact_success_factor_source" => group["contact_success_factor_source"],
        "command_success" => group["command_success"],
        "contact_result" => provider_result_artifact_value(group["contact_result"]),
        "command_result" => provider_result_artifact_value(group["command_result"]),
        "command_success_factor" => group["command_success_factor"],
        "command_success_factor_source" => group["command_success_factor_source"],
        "actual_throughput_mb" => group["actual_throughput_mb"],
        "actual_data_rate_throughput_derivations" =>
          group["actual_data_rate_throughput_derivations"],
        "source_window_ids" => Map.get(group, "source_window_ids", []),
        "scenario_ids" => Map.get(group, "scenario_ids", []),
        "action" => Map.get(group, "required_operator_action", "review_contact_contention"),
        "required_operator_action" =>
          Map.get(group, "required_operator_action", "review_contact_contention"),
        "approval_status" => Map.get(group, "approval_status", "operator_review_required"),
        "operator_action_reason" => group["operator_action_reason"],
        "reason" => group_reason(group),
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => group["approval_requirements"],
        "approval_rule_matches" => group["approval_rule_matches"],
        "source_policy_decision" => group["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_contention_group" => group
      }
      |> Map.merge(Map.take(group, station_calendar_context_fields()))
      |> compact_map()
    end)
  end

  def invalid_input_rows(rows, source \\ "contact_contention_report.invalid_contact_inputs") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["contact_contention_invalid_input", row["contact_id"], index]),
        "review_type" => "contact_contention_review",
        "source" => source,
        "subject_id" => row["id"],
        "contact_id" => row["contact_id"],
        "contact_ids" => Map.get(row, "contact_ids", []),
        "ground_station_id" => row["ground_station_id"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "direction" => row["direction"],
        "directions" => row["directions"],
        "contact_count" => Map.get(row, "contact_count", 1),
        "scenario_ids" => Map.get(row, "scenario_ids", []),
        "action" =>
          Map.get(row, "required_operator_action", "review_invalid_contact_contention_input"),
        "required_operator_action" =>
          Map.get(row, "required_operator_action", "review_invalid_contact_contention_input"),
        "approval_status" => Map.get(row, "approval_status", "operator_review_required"),
        "operator_action_reason" => row["operator_action_reason"],
        "reason" => invalid_input_reason(row),
        "invalid_contact_input" => true,
        "invalid_contact_input_reason" => row["invalid_contact_input_reason"],
        "requirement_type" => requirement["requirement_type"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "approval_requirements" => row["approval_requirements"],
        "approval_rule_matches" => row["approval_rule_matches"],
        "source_policy_decision" => row["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_invalid_contact_input" => row
      }
      |> compact_map()
    end)
  end

  def candidate_refresh_rows(artifact) do
    artifact = stringify_keys(artifact)

    direct_rows =
      [
        {"candidate_refresh.source_contact_contention_report",
         artifact["source_contact_contention_report"]},
        {"candidate_refresh.contact_contention_report", artifact["contact_contention_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_contact_contention_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  defp source_contact_contention_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_contact_contention_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_contact_contention_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    invalid_input_rows(
      Map.get(report, "invalid_contact_inputs", []),
      "#{source}.invalid_contact_inputs"
    ) ++
      group_rows(
        Map.get(report, "conflict_groups", []),
        "#{source}.conflict_groups"
      )
  end

  defp source_contact_contention_report_rows(_report, _source), do: []

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
         %{"schema_contract" => "contact_contention_report.v1"} = report,
         source
       ) do
    source_contact_contention_report_rows(report, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_contact_contention_report",
       artifact["source_contact_contention_report"]},
      {"#{source}.contact_contention_report", artifact["contact_contention_report"]},
      {"#{source}.contact_allocation_report.contact_contention_report",
       get_in(artifact, ["contact_allocation_report", "contact_contention_report"])}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_contact_contention_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

  def candidate_refresh_resolution_rows(artifact) do
    artifact = stringify_keys(artifact)

    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_contact_contention_resolution_report",
         get_in(artifact, [
           "accepted_planning_state",
           "source_contact_contention_resolution_report"
         ])},
        {"candidate_refresh.accepted_planning_state.contact_contention_resolution_report",
         get_in(artifact, ["accepted_planning_state", "contact_contention_resolution_report"])},
        {"candidate_refresh.accepted_planning_state.source_contact_contention_resolution_summary",
         get_in(artifact, [
           "accepted_planning_state",
           "source_contact_contention_resolution_summary"
         ])},
        {"candidate_refresh.accepted_planning_state.contact_contention_resolution_summary",
         get_in(artifact, ["accepted_planning_state", "contact_contention_resolution_summary"])},
        {"candidate_refresh.mission_state.source_contact_contention_resolution_report",
         get_in(artifact, ["mission_state", "source_contact_contention_resolution_report"])},
        {"candidate_refresh.mission_state.contact_contention_resolution_report",
         get_in(artifact, ["mission_state", "contact_contention_resolution_report"])},
        {"candidate_refresh.mission_state.source_contact_contention_resolution_summary",
         get_in(artifact, ["mission_state", "source_contact_contention_resolution_summary"])},
        {"candidate_refresh.mission_state.contact_contention_resolution_summary",
         get_in(artifact, ["mission_state", "contact_contention_resolution_summary"])},
        {"candidate_refresh.source_contact_contention_resolution_report",
         artifact["source_contact_contention_resolution_report"]},
        {"candidate_refresh.contact_contention_resolution_report",
         artifact["contact_contention_resolution_report"]},
        {"candidate_refresh.source_contact_contention_resolution_summary",
         artifact["source_contact_contention_resolution_summary"]},
        {"candidate_refresh.contact_contention_resolution_summary",
         artifact["contact_contention_resolution_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_resolution_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_resolution_rows(artifact)
  end

  def source_resolution_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_resolution_report_rows(report, "#{source}[#{index}]")
    end)
  end

  def source_resolution_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    if resolution_summary?(report) do
      source_resolution_summary_rows(report, source)
    else
      report
      |> Map.get("recommendations", [])
      |> rows("#{source}.recommendations")
    end
  end

  def source_resolution_report_rows(_report, _source), do: []

  defp source_resolution_summary_rows(%{} = summary, source) do
    summary = stringify_keys(summary)
    summary_context = resolution_summary_context(summary)

    summary
    |> resolution_summary_recommendation_rows()
    |> Enum.map(fn row ->
      row
      |> Map.put("source_contact_contention_resolution_summary", summary_context)
      |> Map.put("source_summary_model", summary["model"])
      |> Map.put("source_summary_schema_contract", summary["schema_contract"])
      |> Map.put("source_summary_source", summary["source"])
      |> Map.put("source_artifact_type", summary["source_artifact_type"])
      |> Map.put("schema_contract", summary["schema_contract"])
      |> compact_map()
    end)
    |> rows("#{source}.summary_recommendations")
  end

  defp resolution_summary_recommendation_rows(%{"recommendations" => rows})
       when is_list(rows) and rows != [] do
    rows
    |> Enum.map(&stringify_keys/1)
  end

  defp resolution_summary_recommendation_rows(%{} = summary) do
    summary
    |> resolution_summary_group_ids()
    |> Enum.map(fn group_id ->
      selected_contact_ids =
        resolution_summary_group_ids(summary, group_id, "selected_contact_ids")

      deferred_contact_ids =
        resolution_summary_group_ids(summary, group_id, "deferred_contact_ids")

      review_contact_ids = resolution_summary_group_ids(summary, group_id, "review_contact_ids")

      %{
        "group_id" => group_id,
        "ground_station_id" =>
          resolution_summary_group_value(summary, group_id, "ground_station_ids") ||
            resolution_summary_single_map_key(
              summary,
              "capacity_pack_required_capacity_fraction_by_ground_station_id"
            ),
        "resource_scope" =>
          resolution_summary_group_value(summary, group_id, "resource_scopes") ||
            resolution_summary_single_count_key(summary, "resource_scope_counts"),
        "selected_contact_id" => List.first(selected_contact_ids),
        "selected_contact_ids" => selected_contact_ids,
        "deferred_contact_ids" => deferred_contact_ids,
        "review_contact_ids" => review_contact_ids,
        "candidate_count" =>
          Enum.count(
            Enum.uniq(selected_contact_ids ++ deferred_contact_ids ++ review_contact_ids)
          ),
        "selection_reason" =>
          resolution_summary_group_value(summary, group_id, "selection_reasons") ||
            resolution_summary_single_count_key(summary, "selection_reason_counts"),
        "action" =>
          resolution_summary_group_value(summary, group_id, "actions") ||
            resolution_summary_single_count_key(summary, "action_counts") ||
            "recommend_preferred_contact_for_operator_review",
        "review_status" => "operator_review_required",
        "capacity_pack_required_capacity_fraction" =>
          resolution_summary_group_number(
            summary,
            group_id,
            "capacity_pack_required_capacity_fraction"
          ),
        "capacity_pack_selected_required_capacity_fraction" =>
          resolution_summary_group_number(
            summary,
            group_id,
            "capacity_pack_selected_required_capacity_fraction"
          ),
        "capacity_pack_deferred_required_capacity_fraction" =>
          resolution_summary_group_number(
            summary,
            group_id,
            "capacity_pack_deferred_required_capacity_fraction"
          ),
        "capacity_pack_required_capacity_fraction_by_status" =>
          summary["capacity_pack_required_capacity_fraction_by_status"],
        "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
          summary["capacity_pack_required_capacity_fraction_by_ground_station_id"],
        "required_capacity_fraction_source_counts" =>
          summary["required_capacity_fraction_source_counts"]
      }
      |> compact_map()
    end)
  end

  defp resolution_summary_group_ids(%{} = summary) do
    keyed_group_ids =
      [
        "selected_contact_ids_by_group_id",
        "deferred_contact_ids_by_group_id",
        "review_contact_ids_by_group_id"
      ]
      |> Enum.flat_map(fn field ->
        case summary[field] do
          %{} = by_group -> Map.keys(by_group)
          _value -> []
        end
      end)

    [
      summary["recommendation_group_ids"],
      summary["review_group_ids"],
      keyed_group_ids
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp resolution_summary_group_ids(summary, group_id, field) do
    by_group_field = "#{field}_by_group_id"

    value =
      case summary[by_group_field] do
        %{} = by_group -> by_group[group_id]
        _value -> nil
      end

    (value || summary[field] || [])
    |> List.wrap()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp resolution_summary_group_value(summary, group_id, field) do
    by_group_field = "#{field}_by_group_id"

    case summary[by_group_field] do
      %{} = by_group ->
        by_group[group_id]
        |> List.wrap()
        |> Enum.reject(&(&1 in [nil, ""]))
        |> List.first()

      _value ->
        nil
    end
  end

  defp resolution_summary_group_number(summary, _group_id, field) do
    numeric_or_nil(summary[field])
  end

  defp resolution_summary_single_map_key(summary, field) do
    case summary[field] do
      %{} = values when map_size(values) == 1 ->
        values
        |> Map.keys()
        |> List.first()

      _value ->
        nil
    end
  end

  defp resolution_summary_single_count_key(summary, field) do
    case summary[field] do
      %{} = counts when map_size(counts) == 1 ->
        counts
        |> Map.keys()
        |> List.first()

      _value ->
        nil
    end
  end

  defp resolution_summary_context(%{} = summary) do
    %{
      "model" => summary["model"],
      "schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source" => summary["source"],
      "conflict_group_count" => summary["conflict_group_count"],
      "recommendation_count" => summary["recommendation_count"],
      "review_recommendation_count" => summary["review_recommendation_count"],
      "recommendation_group_ids" => summary["recommendation_group_ids"],
      "review_group_ids" => summary["review_group_ids"],
      "selected_contact_ids" => summary["selected_contact_ids"],
      "deferred_contact_ids" => summary["deferred_contact_ids"],
      "review_contact_ids" => summary["review_contact_ids"],
      "capacity_pack_required_capacity_fraction" =>
        summary["capacity_pack_required_capacity_fraction"],
      "capacity_pack_selected_required_capacity_fraction" =>
        summary["capacity_pack_selected_required_capacity_fraction"],
      "capacity_pack_deferred_required_capacity_fraction" =>
        summary["capacity_pack_deferred_required_capacity_fraction"],
      "capacity_pack_required_capacity_fraction_by_status" =>
        summary["capacity_pack_required_capacity_fraction_by_status"],
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        summary["capacity_pack_required_capacity_fraction_by_ground_station_id"],
      "required_capacity_fraction_source_counts" =>
        summary["required_capacity_fraction_source_counts"],
      "action_counts" => summary["action_counts"],
      "assumptions" => summary["assumptions"]
    }
    |> compact_map()
  end

  defp resolution_summary?(%{
         "schema_contract" => "contact_contention_resolution_summary.v1"
       }),
       do: true

  defp resolution_summary?(%{
         "model" => "artifact_only_contact_contention_resolution_summary"
       }),
       do: true

  defp resolution_summary?(_summary), do: false

  defp candidate_refresh_result_artifact_resolution_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_resolution_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_resolution_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_resolution_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_resolution_rows(
         %{"schema_contract" => "contact_contention_resolution_report.v1"} = report,
         source
       ) do
    source_resolution_report_rows(report, source)
  end

  defp result_artifact_resolution_rows(
         %{"schema_contract" => "contact_contention_resolution_summary.v1"} = summary,
         source
       ) do
    source_resolution_report_rows(summary, source)
  end

  defp result_artifact_resolution_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_contact_contention_resolution_report",
       artifact["source_contact_contention_resolution_report"]},
      {"#{source}.contact_contention_resolution_report",
       artifact["contact_contention_resolution_report"]},
      {"#{source}.source_contact_contention_resolution_summary",
       artifact["source_contact_contention_resolution_summary"]},
      {"#{source}.contact_contention_resolution_summary",
       artifact["contact_contention_resolution_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_resolution_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_resolution_rows(_artifact, _source), do: []

  defp group_reason(%{"ground_station_id" => station, "contact_count" => contact_count}) do
    "review #{contact_count} overlapping contacts at #{station}"
  end

  defp group_reason(_group), do: "review contact contention group"

  defp invalid_input_reason(%{"invalid_contact_input_reason" => reason}) do
    "review invalid contact contention input: #{reason}"
  end

  defp invalid_input_reason(_row), do: "review invalid contact contention input"

  defp matched_policy_escalation(row) do
    preferred_rule_id =
      row
      |> preferred_approval_rule_match()
      |> Map.get("rule_id")

    rule_ids =
      row
      |> Map.get("approval_rule_matches", [])
      |> List.wrap()
      |> Enum.map(&Map.get(&1, "rule_id"))
      |> Enum.reject(&is_nil/1)

    escalations =
      row
      |> get_in(["policy_decision", "escalations"])
      |> List.wrap()
      |> Enum.filter(&is_map/1)

    escalation =
      Enum.find(escalations, &(Map.get(&1, "rule_id") == preferred_rule_id)) ||
        Enum.find(escalations, &(Map.get(&1, "rule_id") in rule_ids)) ||
        List.first(escalations) ||
        row
        |> Map.get("approval_rule_matches", [])
        |> List.wrap()
        |> Enum.find(&policy_escalation_context?/1)

    escalation || %{}
  end

  defp preferred_approval_rule_match(%{} = row) do
    preferred_classification =
      row["approval_status"] || get_in(row, ["policy_decision", "classification"])

    preferred_approval_rule_match(row["approval_rule_matches"], preferred_classification)
  end

  defp preferred_approval_rule_match(rule_matches, preferred_classification)
       when is_list(rule_matches) do
    rule_matches =
      rule_matches
      |> Enum.filter(&is_map/1)
      |> Enum.map(&stringify_keys/1)

    Enum.find(rule_matches, &(&1["classification"] == preferred_classification)) ||
      List.first(rule_matches) ||
      %{}
  end

  defp preferred_approval_rule_match(_rule_matches, _preferred_classification), do: %{}

  defp policy_escalation_context?(%{} = row) do
    Enum.any?(
      ["escalation_level", "escalation_queue", "escalation_role", "required_authority", "sla_s"],
      &Map.has_key?(row, &1)
    )
  end

  defp policy_escalation_context?(_row), do: false

  defp provider_result_values(result) when is_binary(result) do
    result
    |> String.trim()
    |> case do
      "" -> []
      value -> [value]
    end
  end

  defp provider_result_values(values) when is_list(values) do
    values
    |> Enum.flat_map(&provider_result_values/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp provider_result_values(%{} = result) do
    Enum.flat_map(provider_result_map_value_keys(), fn key ->
      result
      |> Map.get(key)
      |> provider_result_values()
    end)
  end

  defp provider_result_values(nil), do: []

  defp provider_result_values(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_values()
  end

  defp provider_result_values(result)
       when is_integer(result) or is_float(result) or is_boolean(result),
       do: [encode_value(result)]

  defp provider_result_values(_result), do: []

  defp provider_result_artifact_value(nil), do: nil

  defp provider_result_artifact_value(result) when is_binary(result) do
    case String.trim(result) do
      "" -> nil
      _value -> result
    end
  end

  defp provider_result_artifact_value(results) when is_list(results) do
    case provider_result_values(results) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(%{} = result) do
    case provider_result_values(result) do
      [] -> nil
      values -> Enum.join(values, ",")
    end
  end

  defp provider_result_artifact_value(result) when is_integer(result),
    do: Integer.to_string(result)

  defp provider_result_artifact_value(result) when is_float(result), do: Float.to_string(result)
  defp provider_result_artifact_value(result) when is_boolean(result), do: Atom.to_string(result)

  defp provider_result_artifact_value(result) when is_atom(result) do
    result
    |> Atom.to_string()
    |> provider_result_artifact_value()
  end

  defp provider_result_artifact_value(_result), do: nil

  defp provider_result_map_value_keys do
    ~w(result results outcome outcomes status state disposition provider_result provider_results provider_outcome provider_outcomes provider_status provider_state provider_code code reason reasons message messages error errors details metadata provider diagnostics)
  end

  defp station_calendar_context_fields do
    [
      "station_availability",
      "station_calendar_status",
      "capacity_fraction",
      "capacity_fraction_min",
      "capacity_fraction_max",
      "station_calendar_entry_ids",
      "station_calendar_provider_ids",
      "station_calendar_provider_entry_ids",
      "station_calendar_overlap_entry_ids",
      "station_calendar_directions",
      "station_calendar_reservation_ids",
      "station_calendar_reserved_by",
      "station_calendar_reservation_statuses",
      "station_calendar_reservation_expires_at_s",
      "station_calendar_trust_boundary_statuses",
      "station_reservation_ids",
      "station_reservation_expires_at_s",
      "station_reserved_bys",
      "station_reservation_statuses",
      "station_reservation_match_statuses"
    ]
  end

  defp first_map(values) when is_list(values), do: Enum.find(values, %{}, &is_map/1)
  defp first_map(_values), do: %{}

  defp non_empty_map(%{} = map) when map_size(map) > 0, do: map
  defp non_empty_map(_map), do: nil

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

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

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
