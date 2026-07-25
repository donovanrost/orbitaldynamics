defmodule OrbitalDynamics.OperatorReview.ContactIntent do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def package(intent) do
    {rows, source_artifact_id, provenance} = package_input(intent)

    build_package(rows, "contact_intent.v1", source_artifact_id, provenance)
  end

  def package_input(intent) do
    intent = stringify_keys(intent || %{})

    {
      rows([intent], "contact_intent"),
      Map.get(intent, "id") || Map.get(intent, "activity_id") || "contact_intent",
      Map.get(intent, "provenance", %{})
    }
  end

  def rows(intents, source) do
    intents
    |> Enum.map(&stringify_keys/1)
    |> Enum.with_index(1)
    |> Enum.filter(fn {intent, _index} -> contact_intent_requires_review?(intent) end)
    |> Enum.map(fn {intent, index} ->
      requirement =
        intent["approval_requirements"]
        |> first_map()
        |> stringify_keys()

      rule_match =
        intent["approval_rule_matches"]
        |> first_map()
        |> stringify_keys()

      policy_decision = stringify_keys(intent["policy_decision"] || %{})
      policy_escalation = intent |> matched_policy_escalation() |> stringify_keys()
      cadence_import = intent["cadence_import"] || %{}
      action = requirement["action"] || "review_contact_intent"
      subject_id = intent["id"] || intent["activity_id"] || intent["contact_id"] || index

      %{
        "id" => review_id(["contact_intent_review", subject_id, index]),
        "review_type" => "contact_intent_review",
        "source" => source,
        "subject_id" => subject_id,
        "activity_id" => intent["activity_id"],
        "contact_id" => intent["contact_id"] || intent["id"],
        "activity_type" => intent["activity_type"],
        "timeline_id" => intent["timeline_id"],
        "timeline_identity" => intent["timeline_identity"],
        "activity_context" => intent["activity_context"],
        "scenario_id" => intent["scenario_id"],
        "spacecraft_id" => intent["spacecraft_id"],
        "ground_station_id" => intent["ground_station_id"],
        "direction" => intent["direction"],
        "starts_at_s" => intent["starts_at_s"],
        "ends_at_s" => intent["ends_at_s"],
        "estimated_throughput_mb" => intent["estimated_throughput_mb"],
        "station_availability" => intent["station_availability"],
        "capacity_fraction" => intent["capacity_fraction"],
        "capacity_fraction_min" => intent["capacity_fraction_min"],
        "capacity_fraction_max" => intent["capacity_fraction_max"],
        "required_capacity_fraction" => intent["required_capacity_fraction"],
        "required_capacity_fraction_source" => intent["required_capacity_fraction_source"],
        "capacity_pack_required_capacity_fraction" =>
          intent["capacity_pack_required_capacity_fraction"],
        "capacity_pack_contact_ids" => intent["capacity_pack_contact_ids"],
        "contact_ids" => intent["contact_ids"],
        "source_summary_model" => intent["source_summary_model"],
        "source_summary_schema_contract" => intent["source_summary_schema_contract"],
        "source_summary_source" => intent["source_summary_source"],
        "source_artifact_type" => intent["source_artifact_type"],
        "schema_contract" => intent["schema_contract"],
        "station_contention_status" => intent["station_contention_status"],
        "station_calendar_entry_id" => intent["station_calendar_entry_id"],
        "station_calendar_directions" => intent["station_calendar_directions"],
        "station_calendar_status" => intent["station_calendar_status"],
        "station_calendar_overlap_count" => intent["station_calendar_overlap_count"],
        "station_calendar_overlap_entry_ids" => intent["station_calendar_overlap_entry_ids"],
        "station_calendar_overlap_availabilities" =>
          intent["station_calendar_overlap_availabilities"],
        "station_calendar_entry_ambiguous" => intent["station_calendar_entry_ambiguous"],
        "station_calendar_ambiguous_entry_count" =>
          intent["station_calendar_ambiguous_entry_count"],
        "station_calendar_ambiguous_entry_ids" => intent["station_calendar_ambiguous_entry_ids"],
        "station_calendar_reservation_overlap_count" =>
          intent["station_calendar_reservation_overlap_count"],
        "station_calendar_reservation_ids" => intent["station_calendar_reservation_ids"],
        "station_calendar_reserved_by" => intent["station_calendar_reserved_by"],
        "station_calendar_reservation_statuses" =>
          intent["station_calendar_reservation_statuses"],
        "station_calendar_reservation_expires_at_s" =>
          intent["station_calendar_reservation_expires_at_s"],
        "station_calendar_trust_boundary_status" =>
          intent["station_calendar_trust_boundary_status"],
        "trust_boundary" => intent["trust_boundary"],
        "provenance" => intent["provenance"],
        "source_station_calendar_entry" => intent["source_station_calendar_entry"],
        "source_station_calendar_overlaps" => intent["source_station_calendar_overlaps"],
        "station_reservation_id" => intent["station_reservation_id"],
        "station_reservation_expires_at_s" => intent["station_reservation_expires_at_s"],
        "station_reserved_by" => intent["station_reserved_by"],
        "station_reservation_status" => intent["station_reservation_status"],
        "station_reservation_match_status" => intent["station_reservation_match_status"],
        "schedule_conflict_status" => intent["schedule_conflict_status"],
        "contact_success" => intent["contact_success"],
        "contact_result" => provider_result_artifact_value(intent["contact_result"]),
        "contact_success_factor" => intent["contact_success_factor"],
        "contact_success_factor_source" => intent["contact_success_factor_source"],
        "command_success" => intent["command_success"],
        "command_result" => provider_result_artifact_value(intent["command_result"]),
        "command_success_factor" => intent["command_success_factor"],
        "command_success_factor_source" => intent["command_success_factor_source"],
        "dependency_activity_ids" => intent["dependency_activity_ids"],
        "dependency_timeline_ids" => intent["dependency_timeline_ids"],
        "exclusive_with_activity_ids" => intent["exclusive_with_activity_ids"],
        "exclusive_with_timeline_ids" => intent["exclusive_with_timeline_ids"],
        "source_window_id" => intent["source_window_id"],
        "invalid_activity_input" => intent["invalid_activity_input"],
        "invalid_activity_input_reason" => intent["invalid_activity_input_reason"],
        "source_activity" => intent["source_activity"],
        "cadence_import_status" => cadence_import["status"] || "present",
        "cadence_import_type" => cadence_import["type"] || cadence_import["activity_type"],
        "cadence_import_id" => cadence_import["id"] || cadence_import["external_id"],
        "cadence_import_contract" =>
          cadence_import["contract"] || cadence_import["schema_contract"],
        "has_cadence_import" => intent["cadence_import"] != nil,
        "action" => action,
        "required_operator_action" => action,
        "approval_status" => intent["approval_status"] || "operator_review_required",
        "approval_requirements" => intent["approval_requirements"],
        "approval_rule_matches" => intent["approval_rule_matches"],
        "policy_bundle_id" =>
          requirement["policy_bundle_id"] || policy_decision["policy_bundle_id"],
        "rule_id" =>
          requirement["rule_id"] || rule_match["rule_id"] || policy_escalation["rule_id"],
        "required_authority" =>
          requirement["required_authority"] || rule_match["required_authority"] ||
            policy_escalation["required_authority"],
        "escalation_level" =>
          rule_match["escalation_level"] || policy_escalation["escalation_level"],
        "escalation_queue" =>
          rule_match["escalation_queue"] || policy_escalation["escalation_queue"],
        "escalation_role" =>
          rule_match["escalation_role"] || policy_escalation["escalation_role"],
        "sla_s" => rule_match["sla_s"] || policy_escalation["sla_s"],
        "requirement_type" => requirement["requirement_type"],
        "reason" =>
          requirement["reason"] || "contact intent requires policy review before import",
        "source_policy_decision" => intent["policy_decision"],
        "source_policy_escalation" => non_empty_map(policy_escalation),
        "source_contact_intent_summary" => intent["source_contact_intent_summary"],
        "source_contact_intent" => intent
      }
      |> compact_map()
    end)
  end

  defp contact_intent_requires_review?(intent) do
    intent["approval_status"] in ["operator_review_required", "blocked_by_policy"] or
      not Enum.empty?(List.wrap(intent["approval_requirements"])) or
      not Enum.empty?(List.wrap(intent["approval_rule_matches"])) or
      is_map(intent["policy_decision"])
  end

  def candidate_refresh_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.accepted_planning_state.source_contact_intent",
         get_in(artifact, ["accepted_planning_state", "source_contact_intent"])},
        {"candidate_refresh.accepted_planning_state.source_contact_intents",
         get_in(artifact, ["accepted_planning_state", "source_contact_intents"])},
        {"candidate_refresh.accepted_planning_state.source_contact_intent_summary",
         get_in(artifact, ["accepted_planning_state", "source_contact_intent_summary"])},
        {"candidate_refresh.accepted_planning_state.contact_intent_summary",
         get_in(artifact, ["accepted_planning_state", "contact_intent_summary"])},
        {"candidate_refresh.accepted_planning_state.contact_intent",
         get_in(artifact, ["accepted_planning_state", "contact_intent"])},
        {"candidate_refresh.accepted_planning_state.contact_intents",
         get_in(artifact, ["accepted_planning_state", "contact_intents"])},
        {"candidate_refresh.mission_state.source_contact_intent",
         get_in(artifact, ["mission_state", "source_contact_intent"])},
        {"candidate_refresh.mission_state.source_contact_intents",
         get_in(artifact, ["mission_state", "source_contact_intents"])},
        {"candidate_refresh.mission_state.source_contact_intent_summary",
         get_in(artifact, ["mission_state", "source_contact_intent_summary"])},
        {"candidate_refresh.mission_state.contact_intent_summary",
         get_in(artifact, ["mission_state", "contact_intent_summary"])},
        {"candidate_refresh.mission_state.contact_intent",
         get_in(artifact, ["mission_state", "contact_intent"])},
        {"candidate_refresh.mission_state.contact_intents",
         get_in(artifact, ["mission_state", "contact_intents"])},
        {"candidate_refresh.source_contact_intent", artifact["source_contact_intent"]},
        {"candidate_refresh.source_contact_intents", artifact["source_contact_intents"]},
        {"candidate_refresh.source_contact_intent_summary",
         artifact["source_contact_intent_summary"]},
        {"candidate_refresh.contact_intent_summary", artifact["contact_intent_summary"]},
        {"candidate_refresh.contact_intent", artifact["contact_intent"]}
      ]
      |> Enum.flat_map(fn {source, intent_or_intents} ->
        source_rows(intent_or_intents, source)
      end)

    direct_rows ++ candidate_refresh_contact_intent_container_rows(artifact)
  end

  def source_summary_rows(summary_or_summaries, source),
    do: source_rows(summary_or_summaries, source)

  defp source_rows(intents, source) when is_list(intents) do
    intents
    |> Enum.with_index()
    |> Enum.flat_map(fn {intent, index} ->
      source_rows(intent, "#{source}[#{index}]")
    end)
  end

  defp source_rows(%{} = intent, source) do
    intent = stringify_keys(intent)

    if contact_intent_summary?(intent) do
      source_contact_intent_summary_rows(intent, source)
    else
      rows([intent], source)
    end
  end

  defp source_rows(_intent, _source), do: []

  defp source_contact_intent_summary_rows(%{} = summary, source) do
    summary = stringify_keys(summary)
    summary_context = contact_intent_summary_context(summary)

    summary
    |> contact_intent_summary_review_rows(source)
    |> Enum.map(fn row ->
      row
      |> Map.put("source_contact_intent_summary", summary_context)
      |> Map.put("source_summary_model", summary["model"])
      |> Map.put("source_summary_schema_contract", summary["schema_contract"])
      |> Map.put("source_summary_source", summary["source"])
      |> Map.put("source_artifact_type", summary["source_artifact_type"])
      |> Map.put("schema_contract", summary["schema_contract"])
      |> compact_map()
    end)
    |> rows("#{source}.summary_contacts")
  end

  defp contact_intent_summary_review_rows(%{"rows" => rows}, _source)
       when is_list(rows) and rows != [] do
    rows
    |> Enum.map(&stringify_keys/1)
  end

  defp contact_intent_summary_review_rows(%{} = summary, source) do
    direction_routing = contact_intent_summary_direction_routing(summary)

    direction_routing
    |> Map.keys()
    |> Enum.sort()
    |> Enum.map(fn direction ->
      route = stringify_keys(direction_routing[direction] || %{})
      contact_ids = List.wrap(route["contact_ids"] || [])
      capacity_contact_ids = List.wrap(route["capacity_pack_contact_ids"] || [])
      source_fragment = stable_id_fragment(source)
      summary_intent_id = "contact_intent_summary:#{source_fragment}:#{direction}"

      %{
        "id" => summary_intent_id,
        "activity_id" => summary_intent_id,
        "contact_id" => List.first(contact_ids ++ capacity_contact_ids),
        "contact_ids" => contact_ids,
        "capacity_pack_contact_ids" => capacity_contact_ids,
        "activity_type" => "contact_intent_summary",
        "direction" => direction,
        "ground_station_id" => contact_intent_summary_single_station(summary, contact_ids),
        "required_capacity_fraction" => route["capacity_pack_required_capacity_fraction"],
        "capacity_pack_required_capacity_fraction" =>
          route["capacity_pack_required_capacity_fraction"],
        "required_capacity_fraction_source" => "contact_intent_summary.direction_routing",
        "approval_status" => "operator_review_required",
        "approval_requirements" => [
          %{
            "schema_contract" => "approval_requirement.v1",
            "action" => "review_contact_intent",
            "requirement_type" => "contact_schedule_change",
            "required_authority" => "contact_schedule_authority",
            "reason" => "review contact intent summary direction routing"
          }
        ],
        "reason" => "review #{direction} contact intent summary routing"
      }
      |> compact_map()
    end)
  end

  defp contact_intent_summary_direction_routing(%{"direction_routing" => %{} = routing}) do
    stringify_keys(routing)
  end

  defp contact_intent_summary_direction_routing(%{} = summary) do
    contact_ids_by_direction = stringify_keys(summary["contact_ids_by_direction"] || %{})

    capacity_contact_ids_by_direction =
      stringify_keys(summary["capacity_pack_contact_ids_by_direction"] || %{})

    required_capacity_by_direction =
      stringify_keys(summary["capacity_pack_required_capacity_fraction_by_direction"] || %{})

    [
      Map.keys(contact_ids_by_direction),
      Map.keys(capacity_contact_ids_by_direction),
      Map.keys(required_capacity_by_direction),
      List.wrap(summary["directions"])
    ]
    |> List.flatten()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&to_string/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> Map.new(fn direction ->
      route =
        %{
          "contact_count" => length(List.wrap(contact_ids_by_direction[direction] || [])),
          "contact_ids" => List.wrap(contact_ids_by_direction[direction] || []),
          "capacity_pack_required_capacity_fraction" => required_capacity_by_direction[direction],
          "capacity_pack_contact_ids" =>
            List.wrap(capacity_contact_ids_by_direction[direction] || [])
        }
        |> compact_map()

      {direction, route}
    end)
  end

  defp contact_intent_summary_single_station(%{} = summary, contact_ids) do
    by_station = stringify_keys(summary["contact_ids_by_ground_station_id"] || %{})
    contact_ids = MapSet.new(List.wrap(contact_ids))

    by_station
    |> Enum.find_value(fn {station_id, station_contact_ids} ->
      station_contact_ids = MapSet.new(List.wrap(station_contact_ids))

      if MapSet.size(MapSet.intersection(contact_ids, station_contact_ids)) > 0 do
        station_id
      end
    end)
  end

  defp contact_intent_summary_context(%{} = summary) do
    %{
      "model" => summary["model"],
      "schema_contract" => summary["schema_contract"],
      "source_artifact_type" => summary["source_artifact_type"],
      "source" => summary["source"],
      "contact_intent_count" => summary["contact_intent_count"],
      "capacity_pack_required_contact_count" => summary["capacity_pack_required_contact_count"],
      "capacity_pack_required_capacity_fraction" =>
        summary["capacity_pack_required_capacity_fraction"],
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        summary["capacity_pack_required_capacity_fraction_by_ground_station_id"],
      "capacity_pack_required_capacity_fraction_by_direction" =>
        summary["capacity_pack_required_capacity_fraction_by_direction"],
      "contact_ids_by_ground_station_id" => summary["contact_ids_by_ground_station_id"],
      "contact_ids_by_direction" => summary["contact_ids_by_direction"],
      "capacity_pack_contact_ids_by_ground_station_id" =>
        summary["capacity_pack_contact_ids_by_ground_station_id"],
      "capacity_pack_contact_ids_by_direction" =>
        summary["capacity_pack_contact_ids_by_direction"],
      "direction_routing" => contact_intent_summary_direction_routing(summary),
      "directions" => summary["directions"],
      "assumptions" => summary["assumptions"]
    }
    |> compact_map()
  end

  defp contact_intent_summary?(%{"schema_contract" => "contact_intent_summary.v1"}), do: true
  defp contact_intent_summary?(_summary), do: false

  defp candidate_refresh_contact_intent_container_rows(artifact) do
    [
      {:operator_review_package, "candidate_refresh.source_operator_review_package",
       artifact["source_operator_review_package"]},
      {:operator_review_package, "candidate_refresh.operator_review_package",
       artifact["operator_review_package"]},
      {:cadence_import_manifest, "candidate_refresh.source_cadence_import_manifest",
       artifact["source_cadence_import_manifest"]},
      {:cadence_import_manifest, "candidate_refresh.cadence_import_manifest",
       artifact["cadence_import_manifest"]}
    ]
    |> Enum.flat_map(fn {kind, source, package_or_manifest} ->
      contact_intent_container_rows(kind, package_or_manifest, source)
    end)
    |> Kernel.++(candidate_refresh_result_artifact_rows(artifact))
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
         %{"schema_contract" => "contact_intent_summary.v1"} = summary,
         source
       ) do
    source_rows(summary, source)
  end

  defp result_artifact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_contact_intent", artifact["source_contact_intent"]},
      {"#{source}.source_contact_intents", artifact["source_contact_intents"]},
      {"#{source}.source_contact_intent_summary", artifact["source_contact_intent_summary"]},
      {"#{source}.contact_intent_summary", artifact["contact_intent_summary"]},
      {"#{source}.contact_intent", artifact["contact_intent"]},
      {"#{source}.contact_intents", artifact["contact_intents"]}
    ]
    |> Enum.flat_map(fn {intent_source, intent_or_intents} ->
      source_rows(intent_or_intents, intent_source)
    end)
    |> Kernel.++(
      contact_intent_container_rows(
        :operator_review_package,
        artifact["operator_review_package"],
        "#{source}.operator_review_package"
      )
    )
    |> Kernel.++(
      contact_intent_container_rows(
        :cadence_import_manifest,
        artifact["cadence_import_manifest"],
        "#{source}.cadence_import_manifest"
      )
    )
  end

  defp result_artifact_rows(_artifact, _source), do: []

  defp contact_intent_container_rows(kind, containers, source) when is_list(containers) do
    containers
    |> Enum.with_index()
    |> Enum.flat_map(fn {container, index} ->
      contact_intent_container_rows(kind, container, "#{source}[#{index}]")
    end)
  end

  defp contact_intent_container_rows(:operator_review_package, %{} = package, source) do
    package
    |> stringify_keys()
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(&(&1["review_type"] == "contact_intent_review"))
    |> rows_to_rows(source)
  end

  defp contact_intent_container_rows(:cadence_import_manifest, %{} = manifest, source) do
    manifest
    |> stringify_keys()
    |> Map.get("rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.filter(fn row ->
      row["source_review_type"] == "contact_intent_review" or
        row["import_action"] == "review_contact_intent"
    end)
    |> rows_to_rows(source)
  end

  defp contact_intent_container_rows(_kind, _container, _source), do: []

  defp rows_to_rows(rows, source) do
    rows
    |> Enum.map(&contact_intent_from_review_or_import_row/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.with_index()
    |> Enum.flat_map(fn {intent, index} ->
      rows([intent], "#{source}.rows.source_contact_intent[#{index}]")
    end)
  end

  defp contact_intent_from_review_or_import_row(%{} = row) do
    embedded =
      cond do
        is_map(row["source_contact_intent"]) ->
          row["source_contact_intent"]

        is_map(get_in(row, ["source_review_row", "source_contact_intent"])) ->
          get_in(row, ["source_review_row", "source_contact_intent"])

        true ->
          %{}
      end

    embedded =
      case embedded do
        %{} = intent -> stringify_keys(intent)
        _intent -> %{}
      end

    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new("schema_contract", "contact_intent.v1")
    |> Map.put_new("id", row["activity_id"] || row["subject_id"] || row["id"])
    |> Map.put_new("activity_id", row["activity_id"] || row["subject_id"])
    |> Map.put_new("activity_type", row["activity_type"])
    |> Map.put_new("direction", row["direction"])
    |> compact_map()
  end

  defp contact_intent_from_review_or_import_row(_row), do: nil

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
