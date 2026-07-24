defmodule OrbitalDynamics.CampaignPlanner.ResourceProjectionPressureBranches do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ResourceProjectionRisk,
    ScalarValues,
    ScoreTermIdentifiers,
    ValueEncoding
  }

  def from_reports(reports, policy, callbacks \\ default_callbacks()) do
    stringify_keys = Keyword.fetch!(callbacks, :stringify_keys)

    Enum.flat_map(reports, fn {report, source_path} ->
      trust_boundary =
        Map.get(report, "trust_boundary") || get_in(report, ["provenance", "trust_boundary"])

      report
      |> Map.get("projected_resources", [])
      |> Enum.map(&stringify_keys.(&1))
      |> Enum.map(&Map.put(&1, "_source_report_trust_boundary", trust_boundary))
      |> Enum.flat_map(&build(&1, source_path, policy, callbacks))
    end)
  end

  def build(row, source_path, policy, callbacks \\ default_callbacks()) do
    branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
    compact_map = Keyword.fetch!(callbacks, :compact_map)

    spacecraft_id = Map.get(row, "spacecraft_id") || Map.get(row, "scenario_id")
    events = pressure_events(row, source_path, policy, callbacks)

    if spacecraft_id in [nil, ""] or events == [] do
      []
    else
      [
        %{
          "id" => "derived_projected_resource_pressure_#{branch_id_fragment.(spacecraft_id)}",
          "label" => "Derived projected resource pressure #{spacecraft_id}",
          "events" => events,
          "metadata" =>
            %{
              "derived_source" => source_path,
              "resource_projection_source_quality" => row["resource_source_quality"],
              "resource_projection_trust_boundary_status" => row["resource_trust_boundary_status"]
            }
            |> compact_map.()
        }
      ]
    end
  end

  def disambiguate(branches, callbacks \\ default_callbacks()) do
    branch_id_fragment = Keyword.fetch!(callbacks, :branch_id_fragment)
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      branch_id = branch["id"]

      if branch_id?(branch_id) and Map.get(id_counts, branch_id, 0) > 1 do
        suffix =
          branch
          |> branch_identity(index, callbacks)
          |> branch_id_fragment.()

        branch
        |> Map.put("id", "#{branch_id}_#{suffix}")
        |> Map.update("metadata", %{}, fn metadata ->
          metadata
          |> Map.put("resource_projection_branch_base_id", branch_id)
          |> Map.put("resource_projection_branch_identity", suffix)
        end)
      else
        branch
      end
    end)
    |> disambiguate_duplicate_suffixes()
  end

  defp branch_id?(id) when is_binary(id),
    do: String.starts_with?(id, "derived_projected_resource_pressure_")

  defp branch_id?(_id), do: false

  defp disambiguate_duplicate_suffixes(branches) do
    id_counts = Enum.frequencies_by(branches, & &1["id"])

    branches
    |> Enum.with_index(1)
    |> Enum.map(fn {branch, index} ->
      metadata = Map.get(branch, "metadata", %{})

      if Map.has_key?(metadata, "resource_projection_branch_base_id") and
           Map.get(id_counts, branch["id"], 0) > 1 do
        suffix = "#{metadata["resource_projection_branch_identity"]}_#{index}"

        branch
        |> Map.put("id", "#{metadata["resource_projection_branch_base_id"]}_#{suffix}")
        |> Map.update(
          "metadata",
          %{},
          &Map.put(&1, "resource_projection_branch_identity", suffix)
        )
      else
        branch
      end
    end)
  end

  defp branch_identity(branch, index, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    branch
    |> Map.get("events", [])
    |> List.wrap()
    |> Enum.flat_map(fn event ->
      [
        event["source_window_id"],
        event["source_window_ids"],
        event["source_activity_id"],
        event["source_activity_ids"],
        event["downlink_completion_source"],
        event["downlink_completion_sources"],
        event["downlink_demand_source"],
        event["downlink_demand_sources"]
      ]
    end)
    |> List.flatten()
    |> Enum.map(fn value -> encode_value.(value) end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> case do
      [] -> index
      identifiers -> Enum.join(identifiers, "_")
    end
  end

  defp pressure_events(row, source_path, policy, callbacks) do
    []
    |> Kernel.++(storage_pressure_events(row, source_path, policy, callbacks))
    |> Kernel.++(downlink_pressure_events(row, source_path, policy, callbacks))
    |> Kernel.++(battery_pressure_events(row, source_path, policy, callbacks))
    |> Kernel.++(thermal_pressure_events(row, source_path, callbacks))
    |> Kernel.++(availability_pressure_events(row, source_path, callbacks))
    |> Kernel.++(activity_type_constraint_events(row, source_path, callbacks))
  end

  defp trust_boundary(row) do
    row["resource_trust_boundary"] ||
      row["trust_boundary"] ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end

  defp storage_pressure_events(row, source_path, policy, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    case numeric_or_nil.(row["projected_storage_overflow_mb"]) do
      value when is_number(value) and value > 0.0 ->
        [
          downlink_gap_event(row, source_path, "projected_storage_overflow", value, callbacks),
          margin_pressure_event(
            row,
            source_path,
            "storage_margin",
            policy["storage_margin_threshold"],
            "projected_storage_overflow",
            %{"projected_storage_overflow_mb" => value},
            callbacks
          )
        ]

      _value ->
        []
    end
  end

  defp downlink_pressure_events(row, source_path, policy, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    case numeric_or_nil.(row["projected_downlink_shortfall_mb"]) do
      value when is_number(value) and value > 0.0 ->
        [
          downlink_gap_event(row, source_path, "projected_downlink_shortfall", value, callbacks),
          margin_pressure_event(
            row,
            source_path,
            "downlink_margin",
            policy["downlink_margin_threshold"],
            "projected_downlink_shortfall",
            %{"projected_downlink_shortfall_mb" => value},
            callbacks
          )
        ]

      _value ->
        []
    end
  end

  defp battery_pressure_events(row, source_path, policy, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)

    case numeric_or_nil.(row["projected_battery_overuse_wh"]) do
      value when is_number(value) and value > 0.0 ->
        [
          margin_pressure_event(
            row,
            source_path,
            "power_margin",
            policy["power_margin_threshold"],
            "projected_battery_depletion",
            %{"projected_battery_overuse_wh" => value},
            callbacks
          )
        ]

      _value ->
        []
    end
  end

  defp thermal_pressure_events(row, source_path, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    pressure_types = row |> Map.get("resource_pressure_types", []) |> List.wrap()
    thermal_margin = numeric_or_nil.(row["thermal_margin_c"])

    cond do
      is_number(thermal_margin) and thermal_margin < 0.0 ->
        [
          margin_pressure_event(
            row,
            source_path,
            "thermal_margin_c",
            0.0,
            "projected_thermal_margin_below_limit",
            %{"thermal_margin_c" => thermal_margin},
            callbacks
          )
        ]

      "thermal_margin_below_limit" in pressure_types ->
        [
          margin_pressure_event(
            row,
            source_path,
            "thermal_margin_c",
            0.0,
            "projected_thermal_margin_below_limit",
            %{},
            callbacks
          )
        ]

      true ->
        []
    end
  end

  defp availability_pressure_events(row, source_path, callbacks) do
    row
    |> Map.get("resource_pressure_types", [])
    |> List.wrap()
    |> Enum.filter(&(&1 in ResourceProjectionRisk.boolean_availability_pressure_types()))
    |> Enum.map(&availability_pressure_event(row, source_path, &1, callbacks))
  end

  defp availability_pressure_event(row, source_path, type, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    pressure = pressure(row, type)
    resource_field = availability_resource_field(type)

    %{
      "type" => "resource_availability_constraint",
      "spacecraft_id" => scenario_id(row),
      "resource_field" => resource_field,
      "available" => false,
      resource_field => false,
      "degraded" => if(type == "spacecraft_degraded_payload_unavailable", do: true),
      "source_quality" => row["resource_source_quality"],
      "source_activity_id" => source_activity_id(row, pressure, callbacks),
      "source_activity_ids" => source_activity_ids(row, type, callbacks),
      "derivation_reasons" => ["projected_#{type}"],
      "feedback_source" => source_path,
      "feedback_scope" => "resource_projection",
      "trust_boundary" => trust_boundary(row)
    }
    |> compact_map.()
  end

  defp availability_resource_field("spacecraft_unavailable"), do: "spacecraft_available"
  defp availability_resource_field("antenna_unavailable"), do: "antenna_available"
  defp availability_resource_field(_type), do: "payload_available"

  defp activity_type_constraint_events(row, source_path, callbacks) do
    row
    |> Map.get("resource_pressure_types", [])
    |> List.wrap()
    |> Enum.filter(&(&1 in ResourceProjectionRisk.activity_type_constraint_pressure_types()))
    |> Enum.map(&activity_type_constraint_event(row, source_path, &1, callbacks))
  end

  defp activity_type_constraint_event(row, source_path, type, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    pressure = pressure(row, type)
    incompatible_types = ResourceProjectionRisk.activity_constraint_types(row, pressure)

    %{
      "type" => "degraded_spacecraft",
      "scenario_id" => scenario_id(row),
      "spacecraft_id" => scenario_id(row),
      "mode" => "resource_activity_type_constraint",
      "incompatible_activity_types" => incompatible_types,
      "source_quality" => row["resource_source_quality"],
      "source_activity_id" => source_activity_id(row, pressure, callbacks),
      "source_activity_ids" => source_activity_ids(row, type, callbacks),
      "derivation_reasons" => ["projected_#{type}"],
      "feedback_source" => source_path,
      "feedback_scope" => "resource_projection",
      "trust_boundary" => trust_boundary(row)
    }
    |> compact_map.()
  end

  defp downlink_gap_event(row, source_path, reason, required_downlink_mb, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    pressure = pressure(row, reason)

    %{
      "type" => "downlink_completion_gap",
      "scenario_id" => scenario_id(row),
      "ground_station_id" => ground_station_id(row, reason, callbacks),
      "required_contacts" => 1,
      "planned_contacts" => 0,
      "required_downlink_mb" =>
        required_downlink_mb(row, reason, required_downlink_mb, callbacks),
      "planned_downlink_mb" => planned_downlink_mb(row, reason, callbacks),
      "starts_at_s" => 0.0,
      "ends_at_s" => pressure_end_s(row, pressure),
      "source_activity_id" => stable_source_activity_id(pressure, callbacks),
      "source_activity_ids" => pressure_activity_ids(row, reason, callbacks),
      "downlink_demand_sources" => downlink_sources(row, reason, callbacks),
      "downlink_completion_sources" => downlink_sources(row, reason, callbacks),
      "derivation_reasons" => [reason],
      "feedback_source" => source_path,
      "feedback_scope" => "resource_projection",
      "trust_boundary" => trust_boundary(row)
    }
    |> compact_map.()
  end

  defp ground_station_id(row, reason, callbacks) do
    score_term_entity_id = Keyword.fetch!(callbacks, :score_term_entity_id)
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)
    pressure = pressure(row, reason)

    [
      pressure["ground_station_id"],
      pressure["station_id"],
      score_term_entity_id.(pressure["ground_station"], ["ground_station_id", "station_id", "id"]),
      score_term_entity_id.(pressure["station"], ["ground_station_id", "station_id", "id"]),
      row["ground_station_id"],
      row["station_id"],
      score_term_entity_id.(row["ground_station"], ["ground_station_id", "station_id", "id"]),
      score_term_entity_id.(row["station"], ["ground_station_id", "station_id", "id"])
    ]
    |> Enum.find(&stable_id_string?.(&1))
  end

  defp planned_downlink_mb(row, reason, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    pressure = pressure(row, reason)

    [
      pressure["planned_downlink_mb"],
      pressure["selected_downlink_mb"],
      pressure["actual_downlink_mb"],
      get_in(pressure, ["throughput_model", "planned_downlink_mb"]),
      get_in(pressure, ["throughput_model", "selected_downlink_mb"]),
      get_in(pressure, ["throughput_model", "actual_downlink_mb"]),
      get_in(pressure, ["activity_context", "planned_downlink_mb"]),
      get_in(pressure, ["activity_context", "selected_downlink_mb"]),
      get_in(pressure, ["activity_context", "actual_downlink_mb"]),
      row["planned_downlink_mb"],
      row["selected_downlink_mb"],
      row["actual_downlink_mb"],
      get_in(row, ["throughput_model", "planned_downlink_mb"]),
      get_in(row, ["throughput_model", "selected_downlink_mb"]),
      get_in(row, ["throughput_model", "actual_downlink_mb"]),
      get_in(row, ["activity_context", "planned_downlink_mb"]),
      get_in(row, ["activity_context", "selected_downlink_mb"]),
      get_in(row, ["activity_context", "actual_downlink_mb"])
    ]
    |> Enum.map(fn value -> numeric_or_nil.(value) end)
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) -> max(value, 0.0)
      _value -> 0.0
    end
  end

  defp required_downlink_mb(row, reason, fallback_gap_mb, callbacks) do
    numeric_or_nil = Keyword.fetch!(callbacks, :numeric_or_nil)
    pressure = pressure(row, reason)

    [
      pressure["required_downlink_mb"],
      pressure["target_downlink_mb"],
      pressure["downlink_requirement_mb"],
      get_in(pressure, ["throughput_model", "required_downlink_mb"]),
      get_in(pressure, ["throughput_model", "target_downlink_mb"]),
      get_in(pressure, ["throughput_model", "downlink_requirement_mb"]),
      get_in(pressure, ["activity_context", "required_downlink_mb"]),
      get_in(pressure, ["activity_context", "target_downlink_mb"]),
      get_in(pressure, ["activity_context", "downlink_requirement_mb"]),
      row["required_downlink_mb"],
      row["target_downlink_mb"],
      row["downlink_requirement_mb"],
      get_in(row, ["throughput_model", "required_downlink_mb"]),
      get_in(row, ["throughput_model", "target_downlink_mb"]),
      get_in(row, ["throughput_model", "downlink_requirement_mb"]),
      get_in(row, ["activity_context", "required_downlink_mb"]),
      get_in(row, ["activity_context", "target_downlink_mb"]),
      get_in(row, ["activity_context", "downlink_requirement_mb"])
    ]
    |> Enum.map(fn value -> numeric_or_nil.(value) end)
    |> Enum.find(&is_number/1)
    |> case do
      value when is_number(value) ->
        max(value, 0.0)

      _value ->
        planned_downlink_mb = planned_downlink_mb(row, reason, callbacks)
        max(planned_downlink_mb + fallback_gap_mb, fallback_gap_mb)
    end
  end

  defp downlink_sources(row, reason, callbacks) do
    encode_value = Keyword.fetch!(callbacks, :encode_value)

    explicit =
      [
        row["downlink_demand_source"],
        row["downlink_demand_sources"],
        row["downlink_completion_source"],
        row["downlink_completion_sources"]
      ]
      |> Kernel.++(
        row
        |> pressure_flow_rows(reason, callbacks)
        |> Enum.flat_map(fn flow ->
          [
            flow["downlink_demand_source"],
            flow["downlink_demand_sources"],
            flow["downlink_completion_source"],
            flow["downlink_completion_sources"],
            get_in(flow, ["throughput_model", "downlink_demand_source"]),
            get_in(flow, ["throughput_model", "downlink_demand_sources"]),
            get_in(flow, ["throughput_model", "downlink_completion_source"]),
            get_in(flow, ["throughput_model", "downlink_completion_sources"]),
            get_in(flow, ["activity_context", "downlink_demand_source"]),
            get_in(flow, ["activity_context", "downlink_demand_sources"]),
            get_in(flow, ["activity_context", "downlink_completion_source"]),
            get_in(flow, ["activity_context", "downlink_completion_sources"])
          ]
        end)
      )
      |> List.flatten()
      |> Enum.map(fn value -> encode_value.(value) end)
      |> Enum.reject(&(&1 in [nil, ""]))

    sources =
      case explicit do
        [] ->
          row
          |> pressure_activity_ids(reason, callbacks)
          |> List.wrap()
          |> Enum.map(&"resource_projection.#{reason}:#{&1}")

        sources ->
          sources
      end

    sources
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp margin_pressure_event(row, source_path, field, threshold, reason, extra, callbacks) do
    compact_map = Keyword.fetch!(callbacks, :compact_map)
    pressure = pressure(row, reason)

    %{
      "type" => "resource_margin_pressure",
      "spacecraft_id" => Map.get(row, "spacecraft_id") || Map.get(row, "scenario_id"),
      "scenario_id" => scenario_id(row),
      "resource_field" => field,
      field => 0.0,
      "#{field}_threshold" => threshold,
      "starts_at_s" => 0.0,
      "ends_at_s" => pressure_end_s(row, pressure),
      "source_activity_id" => stable_source_activity_id(pressure, callbacks),
      "source_activity_ids" => pressure_activity_ids(row, reason, callbacks),
      "derivation_reasons" => [reason],
      "feedback_source" => source_path,
      "feedback_scope" => "resource_projection",
      "trust_boundary" => trust_boundary(row),
      "source_quality" => row["resource_source_quality"]
    }
    |> Map.merge(extra)
    |> compact_map.()
  end

  defp pressure(row, "projected_storage_overflow"),
    do: ResourceProjectionRisk.first_pressure([row], "storage_overflow")

  defp pressure(row, "projected_downlink_shortfall"),
    do: ResourceProjectionRisk.first_pressure([row], "downlink_shortfall")

  defp pressure(row, "projected_battery_depletion"),
    do: ResourceProjectionRisk.first_pressure([row], "battery_depletion")

  defp pressure(row, type)
       when type in [
              "spacecraft_unavailable",
              "payload_unavailable",
              "spacecraft_degraded_payload_unavailable",
              "activity_type_suppressed_by_resource_summary",
              "activity_type_incompatible_with_resource_summary",
              "antenna_unavailable"
            ],
       do: ResourceProjectionRisk.first_pressure([row], type)

  defp pressure(_row, _reason), do: %{}

  defp pressure_activity_ids(row, reason, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    row
    |> pressure_flow_rows(reason, callbacks)
    |> Enum.map(&Map.get(&1, "activity_id"))
    |> Enum.filter(&stable_id_string?.(&1))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      ids -> ids
    end
  end

  defp source_activity_id(row, pressure, callbacks) do
    stable_source_activity_id(pressure, callbacks) ||
      List.first(row_activity_ids(row, callbacks))
  end

  defp source_activity_ids(row, reason, callbacks) do
    pressure_activity_ids(row, reason, callbacks) ||
      case row_activity_ids(row, callbacks) do
        [] -> nil
        ids -> ids
      end
  end

  defp row_activity_ids(row, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    [
      row["source_activity_ids"],
      row["source_activity_id"],
      row["activity_ids"],
      row["activity_id"],
      row["source_activity"],
      row["source_activities"]
    ]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.map(&activity_id_value/1)
    |> Enum.filter(&stable_id_string?.(&1))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp activity_id_value(%{} = activity) do
    Map.get(activity, "activity_id") || Map.get(activity, "id")
  end

  defp activity_id_value(value), do: value

  defp pressure_flow_rows(row, "projected_storage_overflow", callbacks) do
    positive_number? = Keyword.fetch!(callbacks, :positive_number?)

    row
    |> ResourceProjectionRisk.flow_rows()
    |> Enum.filter(&positive_number?.(&1["storage_overflow_mb"]))
  end

  defp pressure_flow_rows(row, "projected_downlink_shortfall", callbacks) do
    positive_number? = Keyword.fetch!(callbacks, :positive_number?)

    row
    |> ResourceProjectionRisk.flow_rows()
    |> Enum.filter(&positive_number?.(&1["downlink_shortfall_mb"]))
  end

  defp pressure_flow_rows(row, "projected_battery_depletion", callbacks) do
    positive_number? = Keyword.fetch!(callbacks, :positive_number?)

    row
    |> ResourceProjectionRisk.flow_rows()
    |> Enum.filter(&positive_number?.(&1["battery_overuse_wh"]))
  end

  defp pressure_flow_rows(row, reason, _callbacks)
       when reason in [
              "spacecraft_unavailable",
              "payload_unavailable",
              "spacecraft_degraded_payload_unavailable",
              "activity_type_suppressed_by_resource_summary",
              "activity_type_incompatible_with_resource_summary",
              "antenna_unavailable"
            ] do
    row
    |> ResourceProjectionRisk.flow_rows()
    |> Enum.filter(&(Map.get(&1, "resource_effect_reason") == reason))
  end

  defp pressure_flow_rows(_row, _reason, _callbacks), do: []

  defp pressure_end_s(row, pressure) do
    [Map.get(pressure, "ends_at_s"), Map.get(pressure, "starts_at_s"), Map.get(row, "ends_at_s")]
    |> Enum.find(&is_number/1)
  end

  defp scenario_id(row) do
    Map.get(row, "scenario_id") || Map.get(row, "spacecraft_id")
  end

  defp stable_source_activity_id(%{"activity_id" => activity_id}, callbacks) do
    stable_id_string? = Keyword.fetch!(callbacks, :stable_id_string?)

    if stable_id_string?.(activity_id), do: activity_id
  end

  defp stable_source_activity_id(_pressure, _callbacks), do: nil

  defp default_callbacks do
    [
      branch_id_fragment: &ValueEncoding.branch_id_fragment/1,
      compact_map: &ValueEncoding.compact_map/1,
      encode_value: &ValueEncoding.encode_value/1,
      numeric_or_nil: &ScalarValues.numeric_or_nil/1,
      positive_number?: &ScalarValues.positive_number?/1,
      score_term_entity_id: &ScoreTermIdentifiers.entity_id/2,
      stable_id_string?: &ScalarValues.stable_id_string?/1,
      stringify_keys: &ValueEncoding.stringify_keys/1
    ]
  end
end
