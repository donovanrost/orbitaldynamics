defmodule OrbitalDynamics.CampaignPlanner.BranchEventNormalizer do
  @moduledoc false

  def normalize_event(event) do
    event
    |> normalize_branch_event_lineage()
    |> normalize_branch_event_trust_boundary()
    |> normalize_branch_event_station_identity()
    |> normalize_branch_event_scalar_identities()
    |> normalize_branch_event_string_fields()
    |> normalize_branch_event_identity_lists()
    |> normalize_branch_event_time_fields()
    |> normalize_branch_event_unit_interval_numbers()
    |> normalize_branch_event_boolean_fields()
    |> normalize_branch_event_feedback_factor()
    |> normalize_branch_event_nonnegative_numbers()
  end

  defp normalize_branch_event_lineage(event) do
    source_branch_id =
      case encode_value(Map.get(event, "source_branch_id")) do
        value when value in [nil, ""] -> nil
        value -> value
      end

    source_branch_ids =
      event
      |> Map.get("source_branch_ids", [])
      |> List.wrap()
      |> Kernel.++(List.wrap(source_branch_id))
      |> Enum.map(&encode_value/1)
      |> Enum.filter(&(is_binary(&1) and &1 != ""))
      |> Enum.uniq()
      |> Enum.sort()

    event =
      if is_nil(source_branch_id) do
        Map.delete(event, "source_branch_id")
      else
        Map.put(event, "source_branch_id", source_branch_id)
      end

    case source_branch_ids do
      [] -> Map.delete(event, "source_branch_ids")
      ids -> Map.put(event, "source_branch_ids", ids)
    end
  end

  defp normalize_branch_event_trust_boundary(event) do
    trust_boundary =
      event
      |> branch_event_trust_boundary()
      |> encode_value()

    case trust_boundary do
      value when is_binary(value) and value != "" -> Map.put(event, "trust_boundary", value)
      _value -> Map.delete(event, "trust_boundary")
    end
  end

  defp normalize_branch_event_station_identity(event) do
    case ground_station_id(event) do
      nil ->
        event
        |> Map.delete("ground_station_id")
        |> Map.delete("station_id")

      station_id ->
        event
        |> Map.put("ground_station_id", station_id)
        |> Map.delete("station_id")
    end
  end

  defp normalize_branch_event_scalar_identities(event) do
    [
      "id",
      "objective_id",
      "branch_id",
      "scenario_id",
      "spacecraft_id",
      "activity_id",
      "target_id",
      "source_activity_id",
      "missed_downlink_activity_id",
      "source_window_id",
      "collection_id",
      "product_id",
      "payload_id",
      "instrument_id",
      "station_calendar_entry_id",
      "station_calendar_provider_id",
      "station_calendar_provider_entry_id",
      "station_reservation_id",
      "reservation_id"
    ]
    |> Enum.reduce(event, fn field, acc ->
      case encode_value(Map.get(acc, field)) do
        value when is_binary(value) and value != "" -> Map.put(acc, field, value)
        _value -> Map.delete(acc, field)
      end
    end)
  end

  defp normalize_branch_event_string_fields(event) do
    [
      "station_calendar_status",
      "station_calendar_trust_boundary_status",
      "station_availability",
      "station_contention_status",
      "reserved_by",
      "station_reserved_by",
      "reservation_status",
      "station_reservation_status",
      "station_reservation_expiration_status",
      "station_reservation_match_status",
      "feedback_source",
      "source_event_type"
    ]
    |> Enum.reduce(event, fn field, acc ->
      case encode_value(Map.get(acc, field)) do
        value when is_binary(value) and value != "" -> Map.put(acc, field, value)
        _value -> Map.delete(acc, field)
      end
    end)
  end

  defp normalize_branch_event_identity_lists(event) do
    [
      "source_activity_ids",
      "activity_ids",
      "target_ids",
      "required_target_ids",
      "allowed_scenario_ids",
      "allowed_spacecraft_ids",
      "spacecraft_constraints",
      "missed_target_ids",
      "uncovered_target_ids",
      "unsatisfied_target_ids",
      "missing_target_ids",
      "target_gap_ids",
      "missed_downlink_activity_ids",
      "source_window_ids",
      "product_ids",
      "planned_product_ids",
      "realized_product_ids",
      "station_calendar_overlap_entry_ids",
      "station_calendar_ambiguous_entry_ids",
      "station_calendar_reservation_ids",
      "station_calendar_directions",
      "station_calendar_overlap_availabilities",
      "station_calendar_reserved_by",
      "station_calendar_reservation_statuses",
      "downlink_demand_sources",
      "downlink_completion_sources",
      "derivation_reasons"
    ]
    |> Enum.reduce(event, fn field, acc ->
      case normalize_branch_event_identity_list(Map.get(acc, field)) do
        [] -> Map.delete(acc, field)
        values -> Map.put(acc, field, values)
      end
    end)
  end

  defp normalize_branch_event_identity_list(values) do
    values
    |> List.wrap()
    |> Enum.map(&encode_value/1)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
  end

  defp normalize_branch_event_time_fields(event) do
    event
    |> normalize_branch_event_time_field("starts_at_s", "start_s")
    |> normalize_branch_event_time_field("ends_at_s", "end_s")
    |> normalize_branch_event_time_field("actual_starts_at_s", "actual_start_s")
    |> normalize_branch_event_time_field("actual_ends_at_s", "actual_end_s")
    |> normalize_branch_event_time_interval("starts_at_s", "ends_at_s")
    |> normalize_branch_event_time_interval("actual_starts_at_s", "actual_ends_at_s")
  end

  defp normalize_branch_event_time_field(event, canonical_field, alias_field) do
    value =
      numeric_or_nil(Map.get(event, canonical_field)) ||
        numeric_or_nil(Map.get(event, alias_field))

    event = Map.delete(event, alias_field)

    if is_number(value) do
      Map.put(event, canonical_field, value)
    else
      Map.delete(event, canonical_field)
    end
  end

  defp normalize_branch_event_time_interval(event, start_field, end_field) do
    start_s = Map.get(event, start_field)
    end_s = Map.get(event, end_field)

    if is_number(start_s) and is_number(end_s) and end_s < start_s do
      Map.put(event, end_field, start_s)
    else
      event
    end
  end

  defp normalize_branch_event_feedback_factor(
         %{"type" => "station_throughput_feedback", "station_throughput_factor" => factor} =
           event
       )
       when is_number(factor) do
    Map.put(event, "station_throughput_factor", clamp_unit_interval(factor))
  end

  defp normalize_branch_event_feedback_factor(
         %{"type" => "contact_success_feedback", "contact_success_factor" => factor} = event
       )
       when is_number(factor) do
    Map.put(event, "contact_success_factor", clamp_unit_interval(factor))
  end

  defp normalize_branch_event_feedback_factor(
         %{"type" => "observation_success_feedback", "observation_success_factor" => factor} =
           event
       )
       when is_number(factor) do
    Map.put(event, "observation_success_factor", clamp_unit_interval(factor))
  end

  defp normalize_branch_event_feedback_factor(
         %{"type" => "maneuver_success_feedback", "maneuver_success_factor" => factor} = event
       )
       when is_number(factor) do
    Map.put(event, "maneuver_success_factor", clamp_unit_interval(factor))
  end

  defp normalize_branch_event_feedback_factor(
         %{"type" => "command_success_feedback", "command_success_factor" => factor} = event
       )
       when is_number(factor) do
    Map.put(event, "command_success_factor", clamp_unit_interval(factor))
  end

  defp normalize_branch_event_feedback_factor(event), do: event

  defp normalize_branch_event_unit_interval_numbers(event) do
    [
      "capacity_fraction",
      "station_throughput_factor",
      "contact_success_factor",
      "observation_success_factor",
      "maneuver_success_factor",
      "command_success_factor",
      "image_quality_score",
      "cloud_cover_fraction",
      "blur_score"
    ]
    |> Enum.reduce(event, fn field, acc ->
      case numeric_or_nil(Map.get(acc, field)) do
        value when is_number(value) and value >= 0.0 and value <= 1.0 ->
          Map.put(acc, field, value)

        value when is_number(value) ->
          acc
          |> put_invalid_branch_event_input(field, value)
          |> Map.delete(field)

        _value ->
          Map.delete(acc, field)
      end
    end)
  end

  defp put_invalid_branch_event_input(event, field, value) do
    reason = "invalid_#{field}"

    event
    |> Map.put("invalid_branch_event_input", true)
    |> Map.put_new("invalid_branch_event_input_reasons", [])
    |> Map.update!("invalid_branch_event_input_reasons", fn reasons ->
      reasons
      |> List.wrap()
      |> Kernel.++([reason])
      |> Enum.uniq()
      |> Enum.sort()
    end)
    |> Map.put_new("source_branch_event", event)
    |> Map.update("invalid_branch_event_fields", [field], fn fields ->
      fields
      |> List.wrap()
      |> Kernel.++([field])
      |> Enum.uniq()
      |> Enum.sort()
    end)
    |> Map.update("invalid_branch_event_values", %{field => value}, fn values ->
      values
      |> stringify_keys()
      |> Map.put(field, value)
    end)
  end

  defp normalize_branch_event_boolean_fields(event) do
    ["allow_placeholder"]
    |> Enum.reduce(event, fn field, acc ->
      case Map.fetch(acc, field) do
        {:ok, value} ->
          case json_boolean_value(value) do
            bool when is_boolean(bool) -> Map.put(acc, field, bool)
            nil -> Map.delete(acc, field)
          end

        :error ->
          acc
      end
    end)
  end

  defp normalize_branch_event_nonnegative_numbers(event) do
    event
    |> normalize_branch_event_nonnegative_number("priority")
    |> normalize_branch_event_nonnegative_number("required_downlink_mb")
    |> normalize_branch_event_nonnegative_number("feedback_weight")
    |> normalize_branch_event_nonnegative_number("feedback_sample_weight")
    |> normalize_branch_event_nonnegative_number("sample_weight")
    |> normalize_branch_event_nonnegative_number("confidence_weight")
    |> normalize_branch_event_nonnegative_number("fuel_margin")
    |> normalize_branch_event_nonnegative_number("power_margin")
    |> normalize_branch_event_nonnegative_number("storage_margin")
    |> normalize_branch_event_nonnegative_number("downlink_margin")
    |> normalize_branch_event_number("thermal_margin_c")
    |> normalize_branch_event_nonnegative_number("battery_capacity_wh")
    |> normalize_branch_event_nonnegative_number("battery_energy_used_wh")
    |> normalize_branch_event_nonnegative_number("battery_state_of_charge")
    |> normalize_branch_event_nonnegative_number("fuel_margin_threshold")
    |> normalize_branch_event_nonnegative_number("power_margin_threshold")
    |> normalize_branch_event_nonnegative_number("storage_margin_threshold")
    |> normalize_branch_event_nonnegative_number("downlink_margin_threshold")
    |> normalize_branch_event_number("thermal_margin_c_threshold")
    |> normalize_branch_event_nonnegative_number("timing_3sigma_s")
    |> normalize_branch_event_nonnegative_number("timing_3sigma_threshold_s")
    |> normalize_branch_event_nonnegative_number("delta_v_3sigma_magnitude_km_s")
    |> normalize_branch_event_nonnegative_number("delta_v_3sigma_magnitude_threshold_km_s")
  end

  defp normalize_branch_event_number(event, field) do
    case numeric_or_nil(Map.get(event, field)) do
      value when is_number(value) -> Map.put(event, field, value)
      _value -> Map.delete(event, field)
    end
  end

  defp normalize_branch_event_nonnegative_number(event, field) do
    case numeric_or_nil(Map.get(event, field)) do
      value when is_number(value) and value >= 0.0 ->
        Map.put(event, field, value)

      value when is_number(value) ->
        event
        |> put_invalid_branch_event_input(field, value)
        |> Map.delete(field)

      _value ->
        Map.delete(event, field)
    end
  end

  defp branch_event_trust_boundary(%{} = event) do
    [Map.get(event, "trust_boundary"), get_in(event, ["provenance", "trust_boundary"])]
    |> Enum.map(&encode_value/1)
    |> Enum.find(&(is_binary(&1) and &1 != ""))
  end

  defp branch_event_trust_boundary(_event), do: nil

  def ground_station_id(event) do
    case encode_value(
           Map.get(event, "ground_station_id") || Map.get(event, "station_id") ||
             nested_ground_station_id(event)
         ) do
      value when is_binary(value) and value != "" -> value
      _value -> nil
    end
  end

  defp nested_ground_station_id(activity) do
    Enum.find_value(["ground_station", "station", :ground_station, :station], fn station_key ->
      case Map.get(activity, station_key) do
        %{} = station ->
          Enum.find_value(
            ["ground_station_id", "station_id", "id", :ground_station_id, :station_id, :id],
            fn identity_key -> Map.get(station, identity_key) end
          )

        _station ->
          nil
      end
    end)
  end

  defp clamp_unit_interval(value), do: value |> max(0.0) |> min(1.0)

  defp json_boolean_value(value) when is_boolean(value), do: value

  defp json_boolean_value(value) when is_number(value) do
    cond do
      value == 1 -> true
      value == 0 -> false
      true -> nil
    end
  end

  defp json_boolean_value(value) when is_binary(value) do
    case value |> String.trim() |> String.downcase() do
      token when token in ["true", "1", "yes", "y"] -> true
      token when token in ["false", "0", "no", "n"] -> false
      _token -> nil
    end
  end

  defp json_boolean_value(_value), do: nil

  defp numeric_or_nil(nil), do: nil
  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(value) do
      {number, ""} -> number
      _error -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
