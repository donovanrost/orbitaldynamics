defmodule OrbitalDynamics.OperatorReview.LinkCapacity do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def package(report) do
    {rows, source_artifact_id, provenance} = package_input(report)

    build_package(rows, "link_capacity_report.v1", source_artifact_id, provenance)
  end

  def package_input(report) do
    report = stringify_keys(report || %{})

    {
      report_rows(report, "link_capacity_report"),
      report_id(report),
      Map.get(report, "provenance", %{})
    }
  end

  def report_rows(nil, _source_prefix), do: []

  def report_rows(%{} = report, source_prefix) do
    report = stringify_keys(report)

    rows(Map.get(report, "rows", []), "#{source_prefix}.rows") ++
      invalid_input_rows(
        Map.get(report, "invalid_contact_inputs", []),
        "#{source_prefix}.invalid_contact_inputs"
      ) ++
      invalid_input_rows(
        Map.get(report, "invalid_selected_contact_inputs", []),
        "#{source_prefix}.invalid_selected_contact_inputs"
      ) ++
      unmatched_rows(report, "#{source_prefix}.unmatched_selected_contact_ids") ++
      unresolved_actual_throughput_rows(report, source_prefix) ++
      unresolved_actual_completion_rows(report, source_prefix) ++
      invalid_policy_station_requirement_rows(report, source_prefix)
  end

  def report_rows(_report, _source_prefix), do: []

  def rows(rows, source) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      station_id = Map.get(row, "ground_station_id")
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["link_capacity", station_id, index]),
        "review_type" => "link_capacity_review",
        "source" => source,
        "subject_id" => station_id,
        "ground_station_id" => station_id,
        "action" => "review_link_capacity_summary",
        "required_operator_action" => "review_link_capacity_summary",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "reason" => reason(row),
        "contact_count" => row["contact_count"],
        "ignored_contact_count" => row["ignored_contact_count"],
        "ignored_contact_ids" => row["ignored_contact_ids"],
        "ignored_contact_reason_counts" => row["ignored_contact_reason_counts"],
        "selected_contact_count" => row["selected_contact_count"],
        "ignored_selected_contact_count" => row["ignored_selected_contact_count"],
        "ignored_selected_contact_ids" => row["ignored_selected_contact_ids"],
        "ignored_selected_contact_reason_counts" => row["ignored_selected_contact_reason_counts"],
        "estimated_throughput_mb" => row["estimated_throughput_mb"],
        "selected_estimated_throughput_mb" => row["selected_estimated_throughput_mb"],
        "capacity_adjusted_throughput_mb" => row["capacity_adjusted_throughput_mb"],
        "selected_capacity_adjusted_throughput_mb" =>
          row["selected_capacity_adjusted_throughput_mb"],
        "unused_capacity_adjusted_throughput_mb" => row["unused_capacity_adjusted_throughput_mb"],
        "selected_capacity_utilization_fraction" => row["selected_capacity_utilization_fraction"],
        "selection_utilization_status" => row["selection_utilization_status"],
        "required_downlink_mb" => row["required_downlink_mb"],
        "required_downlink_contact_count" => row["required_downlink_contact_count"],
        "required_downlink_contact_ids" => row["required_downlink_contact_ids"],
        "downlink_completion_source" => row["downlink_completion_source"],
        "downlink_completion_sources" => row["downlink_completion_sources"],
        "selected_downlink_shortfall_mb" => row["selected_downlink_shortfall_mb"],
        "downlink_requirement_status" => row["downlink_requirement_status"],
        "actual_throughput_mb" => row["actual_throughput_mb"],
        "actual_throughput_contact_count" => row["actual_throughput_contact_count"],
        "actual_throughput_contact_ids" => row["actual_throughput_contact_ids"],
        "actual_data_rate_throughput_derivations" =>
          row["actual_data_rate_throughput_derivations"],
        "actual_completion_fraction" => row["actual_completion_fraction"],
        "actual_completion_contact_count" => row["actual_completion_contact_count"],
        "actual_completion_contact_ids" => row["actual_completion_contact_ids"],
        "actual_downlink_completion_ratio" => row["actual_downlink_completion_ratio"],
        "unmatched_actual_throughput_contact_count" =>
          row["unmatched_actual_throughput_contact_count"],
        "unmatched_actual_throughput_contact_ids" =>
          row["unmatched_actual_throughput_contact_ids"],
        "unmatched_actual_completion_contact_count" =>
          row["unmatched_actual_completion_contact_count"],
        "unmatched_actual_completion_contact_ids" =>
          row["unmatched_actual_completion_contact_ids"],
        "ambiguous_actual_throughput_contact_count" =>
          row["ambiguous_actual_throughput_contact_count"],
        "ambiguous_actual_throughput_contact_ids" =>
          row["ambiguous_actual_throughput_contact_ids"],
        "ambiguous_actual_completion_contact_count" =>
          row["ambiguous_actual_completion_contact_count"],
        "ambiguous_actual_completion_contact_ids" =>
          row["ambiguous_actual_completion_contact_ids"],
        "actual_downlink_shortfall_mb" => row["actual_downlink_shortfall_mb"],
        "actual_downlink_requirement_status" => row["actual_downlink_requirement_status"],
        "contact_success" => row["contact_success"],
        "contact_success_factor" => row["contact_success_factor"],
        "contact_success_factor_source" => row["contact_success_factor_source"],
        "command_success" => row["command_success"],
        "contact_result" => provider_result_artifact_value(row["contact_result"]),
        "command_result" => provider_result_artifact_value(row["command_result"]),
        "command_success_factor" => row["command_success_factor"],
        "command_success_factor_source" => row["command_success_factor_source"],
        "station_calendar_entry_ids" => row["station_calendar_entry_ids"],
        "station_calendar_provider_ids" => row["station_calendar_provider_ids"],
        "station_calendar_provider_entry_ids" => row["station_calendar_provider_entry_ids"],
        "station_calendar_directions" => row["station_calendar_directions"],
        "station_reservation_ids" => row["station_reservation_ids"],
        "station_reservation_expires_at_s" => row["station_reservation_expires_at_s"],
        "station_reserved_bys" => row["station_reserved_bys"],
        "station_reservation_statuses" => row["station_reservation_statuses"],
        "station_reservation_match_statuses" => row["station_reservation_match_statuses"],
        "capacity_fraction_min" => row["capacity_fraction_min"],
        "capacity_fraction_max" => row["capacity_fraction_max"],
        "contact_ids" => Map.get(row, "contact_ids", []),
        "selected_contact_ids" => Map.get(row, "selected_contact_ids", []),
        "duplicate_contact_ids" => row["duplicate_contact_ids"],
        "duplicate_contact_candidate_count" => row["duplicate_contact_candidate_count"],
        "ambiguous_selected_contact_ids" => row["ambiguous_selected_contact_ids"],
        "ambiguous_selected_contact_id_count" => row["ambiguous_selected_contact_id_count"],
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
        "source_link_capacity" => row
      }
      |> compact_map()
    end)
  end

  def report_id(%{"id" => id}) when is_binary(id), do: id
  def report_id(%{"source" => source}) when is_binary(source), do: source
  def report_id(_report), do: "link_capacity_report"

  defp invalid_policy_station_requirement_rows(report, source_prefix) do
    station_ids =
      report
      |> Map.get("invalid_policy_required_downlink_station_ids", [])
      |> List.wrap()
      |> Enum.map(&to_string/1)
      |> Enum.sort()

    case station_ids do
      [] ->
        []

      ids ->
        count = Map.get(report, "invalid_policy_required_downlink_station_count", length(ids))

        [
          %{
            "id" => review_id(["link_capacity", "invalid_policy_station_requirement"]),
            "review_type" => "link_capacity_review",
            "source" => "#{source_prefix}.invalid_policy_required_downlink_station_ids",
            "subject_id" => "invalid_policy_required_downlink_station_ids",
            "action" => "review_invalid_link_capacity_policy",
            "required_operator_action" => "review_invalid_link_capacity_policy",
            "approval_status" => "operator_review_required",
            "reason" => "review #{count} malformed station-scoped downlink policy requirements",
            "invalid_policy_required_downlink_station_count" => count,
            "invalid_policy_required_downlink_station_ids" => ids,
            "source_link_capacity" => %{
              "schema_contract" => report["schema_contract"],
              "source" => report["source"],
              "invalid_policy_required_downlink_station_count" => count,
              "invalid_policy_required_downlink_station_ids" => ids
            }
          }
          |> compact_map()
        ]
    end
  end

  defp unmatched_rows(report, source) do
    unmatched_ids =
      report
      |> Map.get("unmatched_selected_contact_ids", [])
      |> List.wrap()
      |> Enum.map(&to_string/1)
      |> Enum.sort()

    case unmatched_ids do
      [] ->
        []

      ids ->
        count = Map.get(report, "unmatched_selected_contact_count", length(ids))

        [
          %{
            "id" => review_id(["link_capacity", "unmatched_selected_contacts"]),
            "review_type" => "link_capacity_review",
            "source" => source,
            "subject_id" => "unmatched_selected_contacts",
            "action" => "resolve_unmatched_selected_contacts",
            "required_operator_action" => "resolve_unmatched_selected_contacts",
            "approval_status" => "operator_review_required",
            "reason" =>
              "review #{count} selected downlink contacts missing from link capacity candidates",
            "unmatched_selected_contact_count" => count,
            "unmatched_selected_contact_ids" => ids,
            "source_link_capacity" => %{
              "schema_contract" => report["schema_contract"],
              "source" => report["source"],
              "unmatched_selected_contact_count" => count,
              "unmatched_selected_contact_ids" => ids
            }
          }
          |> compact_map()
        ]
    end
  end

  defp invalid_input_rows(rows, source) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["link_capacity", "invalid_input", row["contact_id"], index]),
        "review_type" => "link_capacity_review",
        "source" => source,
        "subject_id" => row["id"],
        "contact_id" => row["contact_id"],
        "contact_ids" => Map.get(row, "contact_ids", []),
        "input_role" => row["input_role"],
        "action" =>
          Map.get(row, "required_operator_action", "review_invalid_link_capacity_input"),
        "required_operator_action" =>
          Map.get(row, "required_operator_action", "review_invalid_link_capacity_input"),
        "approval_status" => Map.get(row, "approval_status", "operator_review_required"),
        "reason" => invalid_input_reason(row),
        "ground_station_id" => row["ground_station_id"],
        "direction" => row["direction"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
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
        "source_contact_candidate" => row["source_contact_candidate"],
        "source_link_capacity" => row
      }
      |> compact_map()
    end)
  end

  defp invalid_input_reason(%{
         "invalid_contact_input_reason" => reason,
         "input_role" => role
       }) do
    "review invalid #{role} link-capacity input: #{reason}"
  end

  defp invalid_input_reason(%{"invalid_contact_input_reason" => reason}) do
    "review invalid link-capacity input: #{reason}"
  end

  defp unresolved_actual_throughput_rows(report, source_prefix) do
    actual_throughput_resolution_row(
      report,
      "unmatched_actual_throughput_contact_ids",
      "unmatched_actual_throughput_contact_count",
      "resolve_unmatched_actual_throughput_contacts",
      "unmatched actual-throughput downlink contacts missing from link capacity candidates",
      "#{source_prefix}.unmatched_actual_throughput_contact_ids"
    ) ++
      actual_throughput_resolution_row(
        report,
        "ambiguous_actual_throughput_contact_ids",
        "ambiguous_actual_throughput_contact_count",
        "resolve_ambiguous_actual_throughput_contacts",
        "ambiguous actual-throughput downlink contacts that do not map to one candidate",
        "#{source_prefix}.ambiguous_actual_throughput_contact_ids"
      )
  end

  defp unresolved_actual_completion_rows(report, source_prefix) do
    actual_throughput_resolution_row(
      report,
      "unmatched_actual_completion_contact_ids",
      "unmatched_actual_completion_contact_count",
      "resolve_unmatched_actual_completion_contacts",
      "unmatched completion-fraction downlink contacts missing from link capacity candidates",
      "#{source_prefix}.unmatched_actual_completion_contact_ids"
    ) ++
      actual_throughput_resolution_row(
        report,
        "ambiguous_actual_completion_contact_ids",
        "ambiguous_actual_completion_contact_count",
        "resolve_ambiguous_actual_completion_contacts",
        "ambiguous completion-fraction downlink contacts that do not map to one candidate",
        "#{source_prefix}.ambiguous_actual_completion_contact_ids"
      )
  end

  defp actual_throughput_resolution_row(
         report,
         id_field,
         count_field,
         action,
         reason_suffix,
         source
       ) do
    ids =
      report
      |> Map.get(id_field, [])
      |> List.wrap()
      |> Enum.map(&to_string/1)
      |> Enum.sort()

    case ids do
      [] ->
        []

      ids ->
        count = Map.get(report, count_field, length(ids))
        subject_id = String.replace(id_field, "_ids", "s")

        [
          %{
            "id" => review_id(["link_capacity", subject_id]),
            "review_type" => "link_capacity_review",
            "source" => source,
            "subject_id" => subject_id,
            "action" => action,
            "required_operator_action" => action,
            "approval_status" => "operator_review_required",
            "reason" => "review #{count} #{reason_suffix}",
            count_field => count,
            id_field => ids,
            "source_link_capacity" => %{
              "schema_contract" => report["schema_contract"],
              "source" => report["source"],
              count_field => count,
              id_field => ids
            }
          }
          |> compact_map()
        ]
    end
  end

  defp reason(%{
         "ground_station_id" => station_id,
         "actual_downlink_requirement_status" => "shortfall",
         "actual_downlink_shortfall_mb" => shortfall
       })
       when is_number(shortfall) do
    "review #{station_id} actual downlink throughput shortfall of #{encode_value(shortfall)} MB"
  end

  defp reason(%{
         "ground_station_id" => station_id,
         "downlink_requirement_status" => "shortfall",
         "selected_downlink_shortfall_mb" => shortfall
       })
       when is_number(shortfall) do
    "review #{station_id} downlink capacity shortfall of #{encode_value(shortfall)} MB"
  end

  defp reason(%{
         "ground_station_id" => station_id,
         "selected_estimated_throughput_mb" => selected_throughput
       }) do
    "review #{station_id} selected downlink throughput #{encode_value(selected_throughput)} MB"
  end

  defp reason(%{"ground_station_id" => station_id}) do
    "review #{station_id} downlink capacity summary"
  end

  defp reason(_row), do: "review downlink capacity summary"

  def candidate_refresh_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_link_capacity_report",
         get_in(artifact, ["accepted_planning_state", "source_link_capacity_report"])},
        {"candidate_refresh.accepted_planning_state.link_capacity_report",
         get_in(artifact, ["accepted_planning_state", "link_capacity_report"])},
        {"candidate_refresh.accepted_planning_state.source_link_capacity_summary",
         get_in(artifact, ["accepted_planning_state", "source_link_capacity_summary"])},
        {"candidate_refresh.accepted_planning_state.link_capacity_summary",
         get_in(artifact, ["accepted_planning_state", "link_capacity_summary"])},
        {"candidate_refresh.accepted_planning_state.source_relay_data_path_summary",
         get_in(artifact, ["accepted_planning_state", "source_relay_data_path_summary"])},
        {"candidate_refresh.accepted_planning_state.relay_data_path_summary",
         get_in(artifact, ["accepted_planning_state", "relay_data_path_summary"])},
        {"candidate_refresh.mission_state.source_link_capacity_report",
         get_in(artifact, ["mission_state", "source_link_capacity_report"])},
        {"candidate_refresh.mission_state.link_capacity_report",
         get_in(artifact, ["mission_state", "link_capacity_report"])},
        {"candidate_refresh.mission_state.source_link_capacity_summary",
         get_in(artifact, ["mission_state", "source_link_capacity_summary"])},
        {"candidate_refresh.mission_state.link_capacity_summary",
         get_in(artifact, ["mission_state", "link_capacity_summary"])},
        {"candidate_refresh.mission_state.source_relay_data_path_summary",
         get_in(artifact, ["mission_state", "source_relay_data_path_summary"])},
        {"candidate_refresh.mission_state.relay_data_path_summary",
         get_in(artifact, ["mission_state", "relay_data_path_summary"])},
        {"candidate_refresh.source_link_capacity_report",
         artifact["source_link_capacity_report"]},
        {"candidate_refresh.link_capacity_report", artifact["link_capacity_report"]},
        {"candidate_refresh.source_link_capacity_summary",
         artifact["source_link_capacity_summary"]},
        {"candidate_refresh.link_capacity_summary", artifact["link_capacity_summary"]},
        {"candidate_refresh.source_relay_data_path_summary",
         artifact["source_relay_data_path_summary"]},
        {"candidate_refresh.relay_data_path_summary", artifact["relay_data_path_summary"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_link_capacity_report_rows(report_or_reports, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  def source_link_capacity_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_link_capacity_report_rows(report, "#{source}[#{index}]")
    end)
  end

  def source_link_capacity_report_rows(%{} = report, source) do
    report = stringify_keys(report)

    if link_capacity_summary?(report) or relay_data_path_summary?(report) do
      source_link_capacity_summary_rows(report, source)
    else
      report_rows(report, source)
    end
  end

  def source_link_capacity_report_rows(_report, _source), do: []

  defp source_link_capacity_summary_rows(%{} = summary, source) do
    summary = stringify_keys(summary)
    summary_context = link_capacity_summary_context(summary)

    summary
    |> link_capacity_summary_review_rows()
    |> Enum.map(fn row ->
      row
      |> Map.put("source_link_capacity_summary", summary_context)
      |> Map.put("source_summary_model", summary["model"])
      |> Map.put("source_summary_schema_contract", summary["schema_contract"])
      |> Map.put("source_artifact_type", summary["source_artifact_type"])
      |> Map.put("schema_contract", summary["schema_contract"])
      |> compact_map()
    end)
    |> rows("#{source}.rows")
  end

  defp link_capacity_summary_review_rows(%{"rows" => rows}) when is_list(rows) and rows != [] do
    rows
    |> List.wrap()
    |> Enum.filter(&is_map/1)
    |> Enum.map(&stringify_keys/1)
  end

  defp link_capacity_summary_review_rows(%{} = summary) do
    summary
    |> Map.get("ground_station_ids", [])
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.map(fn station_id ->
      selected_contact_ids =
        link_capacity_summary_station_ids(summary, station_id, "selected_contact_ids")

      actual_throughput_contact_ids =
        link_capacity_summary_station_ids(summary, station_id, "actual_throughput_contact_ids")

      required_downlink_contact_ids =
        link_capacity_summary_station_ids(summary, station_id, "required_downlink_contact_ids")

      contact_ids =
        [selected_contact_ids, actual_throughput_contact_ids, required_downlink_contact_ids]
        |> List.flatten()
        |> Enum.uniq()

      %{
        "ground_station_id" => station_id,
        "contact_count" => length(contact_ids),
        "contact_ids" => contact_ids,
        "selected_contact_count" => length(selected_contact_ids),
        "selected_contact_ids" => selected_contact_ids,
        "actual_throughput_contact_count" => length(actual_throughput_contact_ids),
        "actual_throughput_contact_ids" => actual_throughput_contact_ids,
        "required_downlink_contact_count" => length(required_downlink_contact_ids),
        "required_downlink_contact_ids" => required_downlink_contact_ids,
        "selected_downlink_shortfall_mb" =>
          link_capacity_summary_station_number(
            summary,
            station_id,
            "selected_downlink_shortfall_mb"
          ),
        "actual_downlink_shortfall_mb" =>
          link_capacity_summary_station_number(
            summary,
            station_id,
            "actual_downlink_shortfall_mb"
          ),
        "capacity_adjusted_throughput_mb" =>
          link_capacity_summary_station_number(
            summary,
            station_id,
            "capacity_adjusted_throughput_mb"
          ),
        "selected_capacity_adjusted_throughput_mb" =>
          link_capacity_summary_station_number(
            summary,
            station_id,
            "selected_capacity_adjusted_throughput_mb"
          ),
        "unused_capacity_adjusted_throughput_mb" =>
          link_capacity_summary_station_number(
            summary,
            station_id,
            "unused_capacity_adjusted_throughput_mb"
          ),
        "downlink_requirement_status" =>
          link_capacity_summary_shortfall_status(
            summary,
            station_id,
            "shortfall_ground_station_ids"
          ),
        "actual_downlink_requirement_status" =>
          link_capacity_summary_shortfall_status(
            summary,
            station_id,
            "actual_shortfall_ground_station_ids"
          ),
        "station_calendar_entry_ids" =>
          link_capacity_summary_station_ids(summary, station_id, "station_calendar_entry_ids"),
        "station_calendar_provider_entry_ids" =>
          link_capacity_summary_station_ids(
            summary,
            station_id,
            "station_calendar_provider_entry_ids"
          ),
        "station_reservation_ids" =>
          link_capacity_summary_station_ids(summary, station_id, "station_reservation_ids")
      }
      |> compact_map()
    end)
  end

  defp link_capacity_summary_station_ids(summary, station_id, field) do
    map_field = "#{field}_by_ground_station_id"

    summary
    |> Map.get(map_field, %{})
    |> Map.get(station_id, [])
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp link_capacity_summary_station_number(summary, station_id, field) do
    map_field = "#{field}_by_ground_station_id"

    summary
    |> Map.get(map_field, %{})
    |> Map.get(station_id)
  end

  defp link_capacity_summary_shortfall_status(summary, station_id, field) do
    if station_id in Map.get(summary, field, []) do
      "shortfall"
    end
  end

  defp link_capacity_summary_context(%{} = summary) do
    %{
      "model" => summary["model"],
      "schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source" => summary["source"],
      "route_count" => summary["route_count"],
      "relay_route_count" => summary["relay_route_count"],
      "direct_downlink_route_count" => summary["direct_downlink_route_count"],
      "route_ids" => summary["route_ids"],
      "route_ids_by_ground_station_id" => summary["route_ids_by_ground_station_id"],
      "route_ids_by_latency_status" => summary["route_ids_by_latency_status"],
      "route_ids_by_risk_status" => summary["route_ids_by_risk_status"],
      "route_ids_by_custody_status" => summary["route_ids_by_custody_status"],
      "source_spacecraft_ids" => summary["source_spacecraft_ids"],
      "relay_spacecraft_ids" => summary["relay_spacecraft_ids"],
      "ground_downlink_contact_ids" => summary["ground_downlink_contact_ids"],
      "custody_status_counts" => summary["custody_status_counts"],
      "latency_status_counts" => summary["latency_status_counts"],
      "risk_status_counts" => summary["risk_status_counts"],
      "station_count" => summary["station_count"],
      "contact_count" => summary["contact_count"],
      "selected_contact_count" => summary["selected_contact_count"],
      "selected_downlink_shortfall_mb" => summary["selected_downlink_shortfall_mb"],
      "actual_downlink_shortfall_mb" => summary["actual_downlink_shortfall_mb"],
      "capacity_adjusted_throughput_mb" => summary["capacity_adjusted_throughput_mb"],
      "selected_capacity_adjusted_throughput_mb" =>
        summary["selected_capacity_adjusted_throughput_mb"],
      "unused_capacity_adjusted_throughput_mb" =>
        summary["unused_capacity_adjusted_throughput_mb"],
      "selected_contact_ids" => summary["selected_contact_ids"],
      "actual_throughput_contact_ids" => summary["actual_throughput_contact_ids"],
      "assumptions" => summary["assumptions"]
    }
    |> compact_map()
  end

  defp link_capacity_summary?(%{"schema_contract" => "link_capacity_summary.v1"}), do: true
  defp link_capacity_summary?(_report), do: false

  defp relay_data_path_summary?(%{} = summary) do
    summary = stringify_keys(summary)

    is_number(summary["route_count"]) and
      (summary["model"] == "artifact_only_relay_data_path_summary" or
         summary["schema_contract"] == "relay_data_path_summary.v1")
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

  defp result_artifact_rows(
         %{"schema_contract" => "link_capacity_report.v1"} = report,
         source
       ) do
    source_link_capacity_report_rows(report, source)
  end

  defp result_artifact_rows(
         %{"schema_contract" => "link_capacity_summary.v1"} = summary,
         source
       ) do
    source_link_capacity_report_rows(summary, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_link_capacity_report", artifact["source_link_capacity_report"]},
      {"#{source}.link_capacity_report", artifact["link_capacity_report"]},
      {"#{source}.source_link_capacity_summary", artifact["source_link_capacity_summary"]},
      {"#{source}.link_capacity_summary", artifact["link_capacity_summary"]},
      {"#{source}.source_relay_data_path_summary", artifact["source_relay_data_path_summary"]},
      {"#{source}.relay_data_path_summary", artifact["relay_data_path_summary"]}
    ]
    |> Enum.flat_map(fn {report_source, report_or_reports} ->
      source_link_capacity_report_rows(report_or_reports, report_source)
    end)
  end

  defp result_artifact_rows(_artifact, _source), do: []

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
