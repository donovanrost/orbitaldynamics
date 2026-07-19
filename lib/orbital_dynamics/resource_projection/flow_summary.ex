defmodule OrbitalDynamics.ResourceProjection.FlowSummary do
  @moduledoc false

  alias OrbitalDynamics.ResourceProjection.PressureClassification

  @flow_summary_schema_contract "resource_projection_flow_summary.v1"

  def build(report, model_limits, subsystem_model_capability_assumptions) do
    report = stringify_keys(report)
    projected_resources = Map.get(report, "projected_resources", [])
    flow_rows = resource_flow_rows(projected_resources)
    ignored_flow_rows = ignored_activity_flow_rows(flow_rows)
    pressure_resources = Enum.filter(projected_resources, &resource_pressure_row?/1)
    pressure_types = resource_pressure_types(projected_resources)
    invalid_activity_inputs = invalid_input_rows(report, "invalid_activity_inputs")

    invalid_resource_summary_inputs =
      invalid_input_rows(report, "invalid_resource_summary_inputs")

    invalid_activity_input_count = length(invalid_activity_inputs)
    invalid_resource_summary_input_count = length(invalid_resource_summary_inputs)

    valid_activity_count =
      flow_summary_valid_activity_count(
        projected_resources,
        flow_rows,
        report["valid_activity_count"]
      )

    invalid_input_count =
      invalid_activity_input_count + invalid_resource_summary_input_count

    %{
      "schema_contract" => @flow_summary_schema_contract,
      "schema_version" => 1,
      "model" => "artifact_only_selected_activity_resource_flow_summary",
      "source" => get_in(report, ["assumptions", "source"]),
      "activity_count" =>
        derived_activity_count(valid_activity_count, invalid_activity_input_count),
      "valid_activity_count" => valid_activity_count,
      "invalid_activity_input_count" => invalid_activity_input_count,
      "invalid_activity_input_ids" => invalid_row_ids(invalid_activity_inputs, "activity_id"),
      "invalid_activity_inputs" => invalid_activity_inputs,
      "input_resource_summary_count" =>
        length(projected_resources) + invalid_resource_summary_input_count,
      "valid_resource_summary_count" => length(projected_resources),
      "invalid_resource_summary_input_count" => invalid_resource_summary_input_count,
      "invalid_resource_summary_input_ids" =>
        invalid_row_ids(invalid_resource_summary_inputs, "resource_summary_id"),
      "invalid_resource_summary_inputs" => invalid_resource_summary_inputs,
      "projected_resource_count" => length(projected_resources),
      "flow_row_count" => length(flow_rows),
      "ignored_activity_count" => length(ignored_flow_rows),
      "ignored_activity_reason_counts" => flow_row_reason_counts(ignored_flow_rows),
      "ignored_activity_ids" => flow_row_activity_ids(ignored_flow_rows),
      "ignored_activity_ids_by_reason" => flow_row_activity_ids_by_reason(ignored_flow_rows),
      "resource_flow_status" =>
        if(
          pressure_resources == [] and invalid_input_count == 0 and
            latency_review_count(flow_rows) == 0,
          do: "clear",
          else: "review_required"
        ),
      "resource_pressure_status" =>
        if(pressure_resources == [], do: "clear", else: "review_required"),
      "resource_pressure_count" => length(pressure_resources),
      "resource_pressure_types" => pressure_types,
      "resource_pressure_spacecraft_ids" => resource_pressure_spacecraft_ids(pressure_resources),
      "resource_pressure_spacecraft_ids_by_type" =>
        resource_pressure_spacecraft_ids_by_type(projected_resources, flow_rows),
      "resource_pressure_activity_ids_by_type" =>
        resource_pressure_activity_ids_by_type(flow_rows),
      "resource_pressure_ground_station_ids_by_type" =>
        resource_pressure_ground_station_ids_by_type(flow_rows),
      "resource_pressure_source_window_ids_by_type" =>
        resource_pressure_source_window_ids_by_type(flow_rows),
      "resource_pressure_station_calendar_entry_ids_by_type" =>
        resource_pressure_station_calendar_entry_ids_by_type(flow_rows),
      "resource_pressure_station_calendar_provider_ids_by_type" =>
        resource_pressure_station_calendar_provider_ids_by_type(flow_rows),
      "resource_pressure_station_calendar_provider_entry_ids_by_type" =>
        resource_pressure_station_calendar_provider_entry_ids_by_type(flow_rows),
      "resource_pressure_station_calendar_directions_by_type" =>
        resource_pressure_station_calendar_directions_by_type(flow_rows),
      "resource_pressure_capacity_fractions_by_type" =>
        resource_pressure_capacity_fractions_by_type(flow_rows),
      "total_storage_produced_mb" => sum_flow_field(flow_rows, "storage_produced_mb"),
      "total_planned_downlink_mb" => sum_flow_field(flow_rows, "planned_downlink_mb"),
      "total_storage_limited_downlinked_mb" => sum_flow_field(flow_rows, "downlinked_mb"),
      "total_unused_downlink_capacity_mb" =>
        sum_flow_field(flow_rows, "unused_downlink_capacity_mb"),
      "total_storage_overflow_mb" => sum_flow_field(flow_rows, "storage_overflow_mb"),
      "total_downlink_shortfall_mb" => sum_flow_field(flow_rows, "downlink_shortfall_mb"),
      "actual_data_volume_evidence_count" => actual_data_volume_evidence_count(flow_rows),
      "total_actual_data_volume_mb" => sum_flow_field(flow_rows, "actual_data_volume_mb"),
      "total_data_volume_delta_mb" => sum_flow_field(flow_rows, "data_volume_delta_mb"),
      "actual_data_volume_under_delivered_activity_ids" =>
        actual_data_volume_variance_activity_ids(flow_rows, :under_delivered),
      "actual_data_volume_over_delivered_activity_ids" =>
        actual_data_volume_variance_activity_ids(flow_rows, :over_delivered),
      "actual_data_volume_exact_activity_ids" =>
        actual_data_volume_variance_activity_ids(flow_rows, :exact),
      "total_projected_storage_remaining_mb" =>
        sum_projected_remaining(
          projected_resources,
          "storage_capacity_mb",
          "projected_storage_used_mb"
        ),
      "minimum_projected_storage_remaining_mb" =>
        min_projected_remaining(
          projected_resources,
          "storage_capacity_mb",
          "projected_storage_used_mb"
        ),
      "total_projected_downlink_remaining_mb" =>
        sum_projected_remaining(
          projected_resources,
          "downlink_capacity_mb",
          "estimated_downlink_mb"
        ),
      "minimum_projected_downlink_remaining_mb" =>
        min_projected_remaining(
          projected_resources,
          "downlink_capacity_mb",
          "estimated_downlink_mb"
        ),
      "latency_status" => latency_status(flow_rows),
      "latency_evidence_count" => latency_evidence_count(flow_rows),
      "latency_review_count" => latency_review_count(flow_rows),
      "latency_review_activity_ids" => latency_review_activity_ids(flow_rows),
      "max_planned_latency_s" => max_optional_flow_field(flow_rows, "planned_latency_s"),
      "max_actual_latency_s" => max_optional_flow_field(flow_rows, "actual_latency_s"),
      "total_battery_energy_consumed_wh" =>
        sum_flow_field(flow_rows, "battery_energy_consumed_wh"),
      "total_battery_energy_generated_wh" =>
        sum_flow_field(flow_rows, "battery_energy_generated_wh"),
      "net_battery_energy_delta_wh" => sum_flow_field(flow_rows, "battery_energy_delta_wh"),
      "peak_battery_overuse_wh" => max_flow_field(flow_rows, "battery_overuse_wh"),
      "projected_resources" => Enum.map(projected_resources, &resource_flow_projection_summary/1),
      "activity_resource_flow" => flow_rows,
      "model_limits" => model_limits,
      "assumptions" =>
        %{
          "execution_boundary" => "artifact_only_no_schedule_mutation",
          "scope" => "selected_activity_resource_flow_and_pressure_evidence",
          "projection_model" => "thin_time_ordered_resource_roll_forward",
          "source" => get_in(report, ["assumptions", "source"]),
          "activity_status_model" =>
            get_in(report, ["assumptions", "activity_status_model"]) ||
              "terminal_or_approval_rejected_activities_are_audited_with_zero_projected_resource_effect",
          "subsystem_simulation" => "not_performed",
          "realized_state_reconciliation" => "not_performed",
          "latency_model" => "declared_activity_timestamps_only"
        }
        |> Map.merge(subsystem_model_capability_assumptions)
    }
    |> compact_map()
  end

  defp resource_flow_projection_summary(row) do
    Map.take(row, [
      "spacecraft_id",
      "activity_count",
      "effective_activity_count",
      "ignored_activity_count",
      "ignored_activity_ids",
      "estimated_storage_produced_mb",
      "estimated_downlink_mb",
      "storage_limited_downlinked_mb",
      "unused_downlink_capacity_mb",
      "starting_storage_used_mb",
      "projected_storage_used_mb",
      "storage_capacity_mb",
      "projected_storage_remaining_mb",
      "projected_storage_overflow_mb",
      "downlink_capacity_mb",
      "projected_downlink_remaining_mb",
      "projected_downlink_shortfall_mb",
      "projected_battery_energy_used_wh",
      "projected_battery_state_of_charge",
      "projected_battery_overuse_wh",
      "resource_pressure_status",
      "resource_pressure_types",
      "resource_source_quality",
      "resource_trust_boundary",
      "resource_trust_boundary_status",
      "resource_provenance",
      "first_resource_pressure_activity_id",
      "first_resource_pressure_activity_type",
      "first_resource_pressure_kind",
      "first_resource_pressure_starts_at_s",
      "first_resource_pressure_direction",
      "first_resource_pressure_ground_station_id",
      "first_resource_pressure_source_window_id",
      "first_resource_pressure_source_window_type",
      "first_resource_pressure_source_window",
      "first_resource_pressure_station_calendar_entry_id",
      "first_resource_pressure_station_calendar_provider_id",
      "first_resource_pressure_station_calendar_provider_entry_id",
      "first_resource_pressure_station_calendar_directions",
      "first_resource_pressure_capacity_fraction"
    ])
    |> put_projected_remaining(
      "projected_storage_remaining_mb",
      row["storage_capacity_mb"],
      row["projected_storage_used_mb"]
    )
    |> put_projected_remaining(
      "projected_downlink_remaining_mb",
      row["downlink_capacity_mb"],
      row["estimated_downlink_mb"]
    )
  end

  defp put_projected_remaining(row, field, capacity, used_or_demand)
       when is_number(capacity) and is_number(used_or_demand) do
    Map.put(row, field, max(capacity - used_or_demand, 0.0))
  end

  defp put_projected_remaining(row, _field, _capacity, _used_or_demand), do: row

  def resource_flow_rows(projected_resources) do
    Enum.flat_map(projected_resources, fn projected_resource ->
      spacecraft_id = projected_resource["spacecraft_id"]

      projected_resource
      |> Map.get("activity_resource_flow", [])
      |> Enum.map(&Map.put(&1, "spacecraft_id", spacecraft_id))
    end)
  end

  defp ignored_activity_flow_rows(flow_rows) do
    Enum.filter(flow_rows, &(&1["resource_effect_status"] == "ignored"))
  end

  defp flow_row_activity_ids(flow_rows) do
    flow_rows
    |> Enum.map(& &1["activity_id"])
    |> sorted_stable_ids()
  end

  defp flow_row_reason_counts(flow_rows) do
    flow_rows
    |> Enum.map(& &1["resource_effect_reason"])
    |> Enum.reject(&is_nil/1)
    |> Enum.frequencies()
  end

  defp flow_row_activity_ids_by_reason(flow_rows) do
    flow_rows
    |> Enum.map(&{&1["resource_effect_reason"], &1["activity_id"]})
    |> stable_ids_by_key()
  end

  defp invalid_input_rows(report, field) do
    report
    |> Map.get(field, [])
    |> case do
      rows when is_list(rows) -> Enum.filter(rows, &is_map/1)
      _rows -> []
    end
  end

  defp invalid_row_ids(rows, field) do
    rows
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  defp sum_projected_remaining(rows, capacity_field, used_or_demand_field) do
    rows
    |> projected_remaining_values(capacity_field, used_or_demand_field)
    |> case do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp min_projected_remaining(rows, capacity_field, used_or_demand_field) do
    rows
    |> projected_remaining_values(capacity_field, used_or_demand_field)
    |> case do
      [] -> nil
      values -> Enum.min(values)
    end
  end

  defp projected_remaining_values(rows, capacity_field, used_or_demand_field) do
    rows
    |> Enum.filter(&is_map/1)
    |> Enum.flat_map(fn row ->
      capacity = row[capacity_field]
      used_or_demand = row[used_or_demand_field]

      if is_number(capacity) and is_number(used_or_demand) do
        [max(capacity - used_or_demand, 0.0)]
      else
        []
      end
    end)
  end

  defp derived_activity_count(valid_activity_count, invalid_activity_input_count)
       when is_integer(valid_activity_count),
       do: valid_activity_count + invalid_activity_input_count

  defp derived_activity_count(valid_activity_count, _invalid_activity_input_count),
    do: valid_activity_count

  defp flow_summary_valid_activity_count(_projected_resources, flow_rows, _report_count)
       when is_list(flow_rows) and flow_rows != [],
       do: length(flow_rows)

  defp flow_summary_valid_activity_count(projected_resources, _flow_rows, report_count)
       when is_list(projected_resources) do
    row_count =
      projected_resources
      |> Enum.map(&Map.get(&1, "activity_count"))
      |> Enum.filter(&is_integer/1)
      |> Enum.sum()

    if row_count > 0, do: row_count, else: report_count
  end

  def resource_pressure_row?(row), do: resource_pressure_types([row]) != []

  def resource_pressure_spacecraft_ids(projected_resources) do
    projected_resources
    |> Enum.map(& &1["spacecraft_id"])
    |> sorted_stable_ids()
  end

  def resource_pressure_spacecraft_ids_by_type(projected_resources, flow_rows) do
    projected_resource_pairs =
      Enum.flat_map(projected_resources, fn row ->
        row
        |> Map.get("resource_pressure_types", [])
        |> Enum.map(&{&1, row["spacecraft_id"]})
      end)

    flow_row_pairs =
      Enum.flat_map(flow_rows, fn row ->
        Enum.map(resource_pressure_kinds(row), &{&1, row["spacecraft_id"]})
      end)

    (projected_resource_pairs ++ flow_row_pairs)
    |> stable_ids_by_key()
  end

  def resource_pressure_activity_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      Enum.map(resource_pressure_kinds(row), &{&1, row["activity_id"]})
    end)
    |> stable_ids_by_key()
  end

  defp resource_pressure_ground_station_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      Enum.map(resource_pressure_kinds(row), &{&1, row["ground_station_id"]})
    end)
    |> stable_ids_by_key()
  end

  defp resource_pressure_source_window_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      Enum.map(resource_pressure_kinds(row), &{&1, row["source_window_id"]})
    end)
    |> stable_ids_by_key()
  end

  defp resource_pressure_station_calendar_entry_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      Enum.map(resource_pressure_kinds(row), &{&1, row["station_calendar_entry_id"]})
    end)
    |> stable_ids_by_key()
  end

  defp resource_pressure_station_calendar_provider_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      Enum.map(resource_pressure_kinds(row), &{&1, row["station_calendar_provider_id"]})
    end)
    |> stable_ids_by_key()
  end

  defp resource_pressure_station_calendar_provider_entry_ids_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      Enum.map(resource_pressure_kinds(row), &{&1, row["station_calendar_provider_entry_id"]})
    end)
    |> stable_ids_by_key()
  end

  defp resource_pressure_station_calendar_directions_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      directions =
        row
        |> Map.get("station_calendar_directions", [])
        |> List.wrap()

      for pressure_type <- resource_pressure_kinds(row),
          direction <- directions,
          direction not in [nil, ""],
          do: {pressure_type, direction}
    end)
    |> stable_ids_by_key()
  end

  defp resource_pressure_capacity_fractions_by_type(flow_rows) do
    flow_rows
    |> Enum.flat_map(fn row ->
      case Map.get(row, "capacity_fraction") do
        value when is_number(value) ->
          Enum.map(resource_pressure_kinds(row), &{&1, value})

        _value ->
          []
      end
    end)
    |> numeric_values_by_key()
  end

  defp sum_flow_field(flow_rows, field) do
    Enum.reduce(flow_rows, 0.0, fn row, total ->
      case Map.get(row, field) do
        value when is_number(value) -> total + value
        _value -> total
      end
    end)
  end

  defp max_flow_field(flow_rows, field) do
    flow_rows
    |> Enum.reduce(0.0, fn row, maximum ->
      case Map.get(row, field) do
        value when is_number(value) -> max(maximum, value)
        _value -> maximum
      end
    end)
  end

  defp max_optional_flow_field(flow_rows, field) do
    flow_rows
    |> Enum.flat_map(fn row ->
      case Map.get(row, field) do
        value when is_number(value) -> [value]
        _value -> []
      end
    end)
    |> case do
      [] -> nil
      values -> Enum.max(values)
    end
  end

  defp actual_data_volume_evidence_count(flow_rows) do
    Enum.count(flow_rows, &is_number(Map.get(&1, "actual_data_volume_mb")))
  end

  defp actual_data_volume_variance_activity_ids(flow_rows, variance) do
    flow_rows
    |> Enum.filter(&actual_data_volume_variance?(&1, variance))
    |> Enum.map(& &1["activity_id"])
    |> sorted_stable_ids()
  end

  defp actual_data_volume_variance?(row, variance) do
    case Map.get(row, "data_volume_delta_mb") do
      delta when is_number(delta) and variance == :under_delivered -> delta < 0.0
      delta when is_number(delta) and variance == :over_delivered -> delta > 0.0
      delta when is_number(delta) and variance == :exact -> delta == 0.0
      _delta -> false
    end
  end

  defp latency_status(flow_rows) do
    cond do
      latency_review_count(flow_rows) > 0 -> "review_required"
      latency_evidence_count(flow_rows) > 0 -> "clear"
      true -> nil
    end
  end

  defp latency_evidence_count(flow_rows) do
    Enum.count(flow_rows, fn row ->
      Enum.any?(
        ~w(collection_ends_at_s planned_delivery_at_s actual_delivery_at_s max_latency_s planned_latency_s actual_latency_s),
        &Map.has_key?(row, &1)
      )
    end)
  end

  defp latency_review_count(flow_rows) do
    Enum.count(flow_rows, &(Map.get(&1, "latency_status") == "late"))
  end

  defp latency_review_activity_ids(flow_rows) do
    flow_rows
    |> Enum.filter(&(Map.get(&1, "latency_status") == "late"))
    |> Enum.map(& &1["activity_id"])
    |> sorted_stable_ids()
  end

  def resource_pressure_types(projected_resources),
    do: PressureClassification.types(projected_resources)

  def stable_ids_by_key(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or value in [nil, ""] end)
    |> Enum.group_by(fn {key, _value} -> key end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} -> {key, sorted_stable_ids(values)} end)
  end

  defp numeric_values_by_key(pairs) do
    pairs
    |> Enum.reject(fn {key, value} -> key in [nil, ""] or not is_number(value) end)
    |> Enum.group_by(fn {key, _value} -> key end, fn {_key, value} -> value end)
    |> Map.new(fn {key, values} ->
      values =
        values
        |> Enum.uniq()
        |> Enum.sort()

      {key, values}
    end)
  end

  defp sorted_stable_ids(values) do
    values
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp resource_pressure_kinds(row), do: PressureClassification.kinds(row)

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value) when is_boolean(value), do: value
  defp stringify_keys(nil), do: nil
  defp stringify_keys(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_keys(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key), do: key
end
