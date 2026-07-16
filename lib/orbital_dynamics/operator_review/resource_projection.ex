defmodule OrbitalDynamics.OperatorReview.ResourceProjection do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def projected_resource_rows(%{} = report),
    do: Map.get(report, "projected_resources", [])

  def projected_resource_rows(_report), do: []

  def report_package(report) do
    {rows, source_artifact_id, provenance} = report_package_input(report)

    build_package(rows, "resource_projection_report.v1", source_artifact_id, provenance)
  end

  def flow_summary_package(summary) do
    {rows, source_artifact_id, provenance} = flow_summary_package_input(summary)

    build_package(rows, "resource_projection_flow_summary.v1", source_artifact_id, provenance)
  end

  def report_package_input(report) do
    report = stringify_keys(report || %{})

    {
      report_rows(report),
      report_id(report),
      Map.get(report, "provenance", %{})
    }
  end

  def flow_summary_package_input(summary) do
    summary = stringify_keys(summary || %{})

    {
      flow_summary_rows(summary),
      flow_summary_id(summary),
      Map.get(summary, "provenance", %{})
    }
  end

  def report_rows(report, source \\ "resource_projection_report") do
    report = stringify_keys(report)

    invalid_activity_rows(
      Map.get(report, "invalid_activity_inputs", []),
      "#{source}.invalid_activity_inputs"
    ) ++
      invalid_summary_rows(
        Map.get(report, "invalid_resource_summary_inputs", []),
        "#{source}.invalid_resource_summary_inputs"
      ) ++
      rows(Map.get(report, "projected_resources", []), "#{source}.projected_resources")
  end

  def rows(rows, source \\ "resource_projection_report.projected_resources") do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      spacecraft_id = Map.get(row, "spacecraft_id")
      flow_rows = resource_flow_rows(Map.get(row, "activity_resource_flow", []))
      first_pressure = first_resource_pressure(row, flow_rows)
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["resource_projection", spacecraft_id, index]),
        "review_type" => "resource_projection_review",
        "source" => source,
        "subject_id" => spacecraft_id,
        "spacecraft_id" => spacecraft_id,
        "action" => "review_resource_projection",
        "required_operator_action" => "review_resource_projection",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "reason" => resource_projection_reason(row),
        "activity_count" => row["activity_count"],
        "effective_activity_count" => row["effective_activity_count"],
        "ignored_activity_count" => row["ignored_activity_count"],
        "ignored_activity_ids" => row["ignored_activity_ids"],
        "observation_count" => row["observation_count"],
        "downlink_count" => row["downlink_count"],
        "estimated_storage_produced_mb" => row["estimated_storage_produced_mb"],
        "estimated_downlink_mb" => row["estimated_downlink_mb"],
        "storage_limited_downlinked_mb" => row["storage_limited_downlinked_mb"],
        "unused_downlink_capacity_mb" => row["unused_downlink_capacity_mb"],
        "starting_storage_used_mb" => row["starting_storage_used_mb"],
        "projected_storage_used_mb" => row["projected_storage_used_mb"],
        "storage_capacity_mb" => row["storage_capacity_mb"],
        "starting_storage_margin" => row["starting_storage_margin"],
        "projected_storage_margin" => row["projected_storage_margin"],
        "projected_storage_remaining_mb" => row["projected_storage_remaining_mb"],
        "projected_storage_overflow_mb" => row["projected_storage_overflow_mb"],
        "downlink_capacity_mb" => row["downlink_capacity_mb"],
        "starting_downlink_margin" => row["starting_downlink_margin"],
        "projected_downlink_margin" => row["projected_downlink_margin"],
        "projected_downlink_remaining_mb" => row["projected_downlink_remaining_mb"],
        "projected_downlink_shortfall_mb" => row["projected_downlink_shortfall_mb"],
        "projected_power_margin" => row["projected_power_margin"],
        "projected_battery_energy_used_wh" => row["projected_battery_energy_used_wh"],
        "projected_battery_state_of_charge" => row["projected_battery_state_of_charge"],
        "projected_battery_overuse_wh" => row["projected_battery_overuse_wh"],
        "resource_pressure_status" => row["resource_pressure_status"],
        "resource_pressure_types" => row["resource_pressure_types"],
        "resource_flow_count" => length(flow_rows),
        "total_battery_energy_consumed_wh" =>
          sum_resource_flow_number(flow_rows, "battery_energy_consumed_wh"),
        "total_battery_energy_generated_wh" =>
          sum_resource_flow_number(flow_rows, "battery_energy_generated_wh"),
        "net_battery_energy_delta_wh" =>
          sum_resource_flow_number(flow_rows, "battery_energy_delta_wh"),
        "peak_storage_overflow_mb" => peak_resource_flow_number(flow_rows, "storage_overflow_mb"),
        "peak_downlink_shortfall_mb" =>
          peak_resource_flow_number(flow_rows, "downlink_shortfall_mb"),
        "peak_battery_overuse_wh" => peak_resource_flow_number(flow_rows, "battery_overuse_wh"),
        "peak_unused_downlink_capacity_mb" =>
          peak_resource_flow_number(flow_rows, "unused_downlink_capacity_mb"),
        "first_resource_pressure_activity_id" => first_pressure["activity_id"],
        "first_resource_pressure_activity_type" => first_pressure["activity_type"],
        "first_resource_pressure_kind" => first_pressure["kind"],
        "first_resource_pressure_starts_at_s" => first_pressure["starts_at_s"],
        "first_resource_pressure_direction" => first_pressure["direction"],
        "first_resource_pressure_ground_station_id" => first_pressure["ground_station_id"],
        "first_resource_pressure_station_calendar_entry_id" =>
          first_pressure["station_calendar_entry_id"],
        "first_resource_pressure_station_calendar_provider_id" =>
          first_pressure["station_calendar_provider_id"],
        "first_resource_pressure_station_calendar_provider_entry_id" =>
          first_pressure["station_calendar_provider_entry_id"],
        "first_resource_pressure_station_calendar_directions" =>
          first_pressure["station_calendar_directions"],
        "first_resource_pressure_capacity_fraction" => first_pressure["capacity_fraction"],
        "first_resource_pressure_source_window_id" => first_pressure["source_window_id"],
        "first_resource_pressure_source_window_type" => first_pressure["source_window_type"],
        "first_resource_pressure_source_window" => first_pressure["source_window"],
        "source_window_id" => first_pressure["source_window_id"],
        "source_window_type" => first_pressure["source_window_type"],
        "source_window" => first_pressure["source_window"],
        "resource_source_quality" => row["resource_source_quality"],
        "resource_trust_boundary" => row["resource_trust_boundary"],
        "resource_trust_boundary_status" => row["resource_trust_boundary_status"],
        "resource_provenance" => row["resource_provenance"],
        "fuel_margin" => row["fuel_margin"],
        "power_margin" => row["power_margin"],
        "thermal_margin_c" => row["thermal_margin_c"],
        "spacecraft_available" => row["spacecraft_available"],
        "payload_available" => row["payload_available"],
        "antenna_available" => row["antenna_available"],
        "mode" => row["mode"],
        "incompatible_activity_types" => row["incompatible_activity_types"],
        "suppressed_activity_types" => row["suppressed_activity_types"],
        "warnings" => Map.get(row, "warnings", []),
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
        "source_resource_projection_flow_summary" =>
          row["source_resource_projection_flow_summary"],
        "source_resource_projection" => row
      }
      |> compact_map()
    end)
  end

  def flow_summary_rows(
        summary,
        source \\ "resource_projection_flow_summary.projected_resources"
      ) do
    flow_rows_by_spacecraft =
      summary
      |> Map.get("activity_resource_flow", [])
      |> List.wrap()
      |> Enum.map(&stringify_keys/1)
      |> Enum.group_by(&Map.get(&1, "spacecraft_id"))

    summary
    |> Map.get("projected_resources", [])
    |> List.wrap()
    |> Enum.map(fn row ->
      row = stringify_keys(row)
      spacecraft_id = row["spacecraft_id"]

      row
      |> Map.put("activity_resource_flow", Map.get(flow_rows_by_spacecraft, spacecraft_id, []))
      |> Map.put(
        "source_resource_projection_flow_summary",
        resource_projection_flow_summary_context(summary)
      )
    end)
    |> rows(source)
  end

  defp resource_projection_flow_summary_context(summary) do
    Map.take(summary, [
      "schema_contract",
      "schema_version",
      "model",
      "source",
      "resource_flow_status",
      "resource_pressure_status",
      "resource_pressure_count",
      "resource_pressure_types",
      "resource_pressure_spacecraft_ids",
      "resource_pressure_spacecraft_ids_by_type",
      "resource_pressure_activity_ids_by_type",
      "total_storage_produced_mb",
      "total_planned_downlink_mb",
      "total_storage_limited_downlinked_mb",
      "total_unused_downlink_capacity_mb",
      "total_projected_storage_remaining_mb",
      "minimum_projected_storage_remaining_mb",
      "total_projected_downlink_remaining_mb",
      "minimum_projected_downlink_remaining_mb",
      "total_storage_overflow_mb",
      "total_downlink_shortfall_mb",
      "latency_status",
      "latency_evidence_count",
      "latency_review_count",
      "latency_review_activity_ids",
      "total_battery_energy_consumed_wh",
      "total_battery_energy_generated_wh",
      "net_battery_energy_delta_wh",
      "peak_battery_overuse_wh",
      "assumptions",
      "model_limits"
    ])
  end

  def invalid_activity_rows(
        rows,
        source \\ "resource_projection_report.invalid_activity_inputs"
      ) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      activity_id = row["activity_id"] || "invalid_activity_input:#{index}"
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" => review_id(["resource_projection", "invalid_activity_input", activity_id]),
        "review_type" => "resource_projection_review",
        "source" => source,
        "subject_id" => activity_id,
        "activity_id" => activity_id,
        "activity_ids" => row["activity_ids"],
        "activity_type" => row["type"],
        "scenario_id" => row["scenario_id"],
        "spacecraft_id" => row["spacecraft_id"],
        "starts_at_s" => row["starts_at_s"],
        "ends_at_s" => row["ends_at_s"],
        "action" => "review_invalid_resource_projection_input",
        "required_operator_action" => "review_invalid_resource_projection_input",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "review_status" => row["review_status"] || "operator_review_required",
        "reason" =>
          "review invalid resource projection input #{activity_id}: #{row["invalid_activity_input_reason"]}",
        "invalid_activity_input" => true,
        "invalid_activity_input_reason" => row["invalid_activity_input_reason"],
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
        "source_activity" => row["source_activity"],
        "source_resource_projection" => row
      }
      |> compact_map()
    end)
  end

  def invalid_summary_rows(
        rows,
        source \\ "resource_projection_report.invalid_resource_summary_inputs"
      ) do
    rows
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      resource_summary_id = row["resource_summary_id"] || "invalid_resource_summary:#{index}"
      requirement = row["approval_requirements"] |> first_map() |> stringify_keys()
      rule_match = row["approval_rule_matches"] |> first_map() |> stringify_keys()
      policy_decision = stringify_keys(row["policy_decision"] || %{})
      policy_escalation = row |> matched_policy_escalation() |> stringify_keys()

      %{
        "id" =>
          review_id(["resource_projection", "invalid_resource_summary", resource_summary_id]),
        "review_type" => "resource_projection_review",
        "source" => source,
        "subject_id" => resource_summary_id,
        "spacecraft_id" => row["spacecraft_id"],
        "action" => "review_invalid_resource_projection_summary",
        "required_operator_action" => "review_invalid_resource_projection_summary",
        "approval_status" => row["approval_status"] || "operator_review_required",
        "review_status" => row["review_status"] || "operator_review_required",
        "reason" =>
          "review invalid resource projection summary #{resource_summary_id}: #{row["invalid_resource_summary_input_reason"]}",
        "invalid_resource_summary_input" => true,
        "invalid_resource_summary_input_reason" => row["invalid_resource_summary_input_reason"],
        "duplicate_resource_summary_scope" => row["duplicate_resource_summary_scope"],
        "mixed_wildcard_resource_summary_scope" => row["mixed_wildcard_resource_summary_scope"],
        "resource_summary_key" => row["resource_summary_key"],
        "duplicate_resource_summary_index" => row["duplicate_resource_summary_index"],
        "duplicate_resource_summary_count" => row["duplicate_resource_summary_count"],
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
        "source_resource_summary" => row["source_resource_summary"],
        "source_resource_projection" => row
      }
      |> compact_map()
    end)
  end

  defp peak_resource_flow_number(rows, field) when is_list(rows) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.max(values)
    end
  end

  defp sum_resource_flow_number(rows, field) when is_list(rows) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.filter(&is_number/1)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp resource_flow_rows(rows) when is_list(rows), do: rows
  defp resource_flow_rows(_rows), do: []

  defp first_resource_pressure(row, flow_rows) do
    direct =
      %{
        "activity_id" => row["first_resource_pressure_activity_id"],
        "activity_type" => row["first_resource_pressure_activity_type"],
        "kind" => row["first_resource_pressure_kind"],
        "starts_at_s" => row["first_resource_pressure_starts_at_s"],
        "direction" => row["first_resource_pressure_direction"],
        "ground_station_id" => row["first_resource_pressure_ground_station_id"],
        "station_calendar_entry_id" => row["first_resource_pressure_station_calendar_entry_id"],
        "station_calendar_provider_id" =>
          row["first_resource_pressure_station_calendar_provider_id"],
        "station_calendar_provider_entry_id" =>
          row["first_resource_pressure_station_calendar_provider_entry_id"],
        "station_calendar_directions" =>
          row["first_resource_pressure_station_calendar_directions"],
        "capacity_fraction" => row["first_resource_pressure_capacity_fraction"],
        "source_window_id" => row["first_resource_pressure_source_window_id"],
        "source_window_type" => row["first_resource_pressure_source_window_type"],
        "source_window" => row["first_resource_pressure_source_window"]
      }
      |> compact_map()

    if Map.has_key?(direct, "activity_id") or Map.has_key?(direct, "kind") do
      direct
    else
      flow_row = first_resource_pressure_flow_row(flow_rows)

      %{
        "activity_id" => flow_row["activity_id"],
        "activity_type" => flow_row["activity_type"],
        "kind" => resource_pressure_kind(flow_row),
        "starts_at_s" => flow_row["starts_at_s"],
        "direction" => flow_row["direction"],
        "ground_station_id" => flow_row["ground_station_id"],
        "station_calendar_entry_id" => flow_row["station_calendar_entry_id"],
        "station_calendar_provider_id" => flow_row["station_calendar_provider_id"],
        "station_calendar_provider_entry_id" => flow_row["station_calendar_provider_entry_id"],
        "station_calendar_directions" => flow_row["station_calendar_directions"],
        "capacity_fraction" => flow_row["capacity_fraction"],
        "source_window_id" => flow_row["source_window_id"],
        "source_window_type" => flow_row["source_window_type"],
        "source_window" => flow_row["source_window"]
      }
      |> compact_map()
    end
  end

  defp first_resource_pressure_flow_row(rows) when is_list(rows) do
    Enum.find(rows, %{}, fn row ->
      positive_number?(row["storage_overflow_mb"]) or
        positive_number?(row["downlink_shortfall_mb"]) or
        positive_number?(row["battery_overuse_wh"])
    end)
  end

  defp resource_pressure_kind(%{"storage_overflow_mb" => overflow})
       when is_number(overflow) and overflow > 0.0,
       do: "storage_overflow"

  defp resource_pressure_kind(%{"downlink_shortfall_mb" => shortfall})
       when is_number(shortfall) and shortfall > 0.0,
       do: "downlink_shortfall"

  defp resource_pressure_kind(%{"battery_overuse_wh" => overuse})
       when is_number(overuse) and overuse > 0.0,
       do: "battery_depletion"

  defp resource_pressure_kind(_row), do: nil

  defp resource_projection_reason(%{"spacecraft_id" => spacecraft_id} = row) do
    flow_rows = resource_flow_rows(Map.get(row, "activity_resource_flow", []))

    case first_resource_pressure(row, flow_rows) do
      %{"activity_id" => activity_id, "kind" => kind} when is_binary(activity_id) ->
        "review #{spacecraft_id} resource pressure at #{activity_id}: #{kind}"

      _row ->
        resource_projection_margin_reason(spacecraft_id, row)
    end
  end

  defp resource_projection_reason(_row), do: "review resource projection"

  defp positive_number?(value), do: is_number(value) and value > 0.0

  defp resource_projection_margin_reason(spacecraft_id, %{"projected_storage_margin" => margin}) do
    "review #{spacecraft_id} projected storage margin #{encode_value(margin)}"
  end

  defp resource_projection_margin_reason(spacecraft_id, _row) do
    "review #{spacecraft_id} resource projection"
  end

  def report_id(%{"id" => id}) when is_binary(id), do: id

  def report_id(%{"assumptions" => %{"source" => source}})
      when is_binary(source),
      do: source

  def report_id(_report), do: "resource_projection_report"

  def flow_summary_id(%{"id" => id}) when is_binary(id), do: id

  def flow_summary_id(%{"source" => source}) when is_binary(source),
    do: source

  def flow_summary_id(%{"assumptions" => %{"source" => source}})
      when is_binary(source),
      do: source

  def flow_summary_id(_summary), do: "resource_projection_flow_summary"

  def candidate_refresh_rows(artifact) do
    artifact = stringify_keys(artifact)

    report_rows =
      [
        {"candidate_refresh.source_resource_projection_report",
         artifact["source_resource_projection_report"]},
        {"candidate_refresh.resource_projection_report", artifact["resource_projection_report"]}
      ]
      |> Enum.flat_map(fn {source, report_or_reports} ->
        source_report_rows(report_or_reports, source)
      end)

    flow_summary_rows =
      [
        {"candidate_refresh.source_resource_projection_flow_summary",
         artifact["source_resource_projection_flow_summary"]},
        {"candidate_refresh.resource_projection_flow_summary",
         artifact["resource_projection_flow_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_flow_summary_rows(summary_or_summaries, source)
      end)

    report_rows ++ flow_summary_rows ++ candidate_refresh_result_artifact_rows(artifact)
  end

  defp source_report_rows(reports, source) when is_list(reports) do
    reports
    |> Enum.with_index()
    |> Enum.flat_map(fn {report, index} ->
      source_report_rows(report, "#{source}[#{index}]")
    end)
  end

  defp source_report_rows(%{} = report, source), do: report_rows(report, source)
  defp source_report_rows(_report, _source), do: []

  defp source_flow_summary_rows(summaries, source) when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_flow_summary_rows(summary, "#{source}[#{index}]")
    end)
  end

  defp source_flow_summary_rows(%{} = summary, source) do
    summary
    |> stringify_keys()
    |> flow_summary_rows("#{source}.projected_resources")
  end

  defp source_flow_summary_rows(_summary, _source), do: []

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
         %{"schema_contract" => "resource_projection_report.v1"} = report,
         source
       ) do
    source_report_rows(report, source)
  end

  defp result_artifact_rows(
         %{"schema_contract" => "resource_projection_flow_summary.v1"} = summary,
         source
       ) do
    source_flow_summary_rows(summary, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {:report, "#{source}.source_resource_projection_report",
       artifact["source_resource_projection_report"]},
      {:report, "#{source}.resource_projection_report", artifact["resource_projection_report"]},
      {:flow_summary, "#{source}.source_resource_projection_flow_summary",
       artifact["source_resource_projection_flow_summary"]},
      {:flow_summary, "#{source}.resource_projection_flow_summary",
       artifact["resource_projection_flow_summary"]}
    ]
    |> Enum.flat_map(fn
      {:report, report_source, report_or_reports} ->
        source_report_rows(report_or_reports, report_source)

      {:flow_summary, summary_source, summary_or_summaries} ->
        source_flow_summary_rows(summary_or_summaries, summary_source)
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
