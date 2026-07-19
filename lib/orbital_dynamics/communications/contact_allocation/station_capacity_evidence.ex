defmodule OrbitalDynamics.Communications.ContactAllocation.StationCapacityEvidence do
  @moduledoc false

  def invalid_station_capacity_declared?(contact, policy) do
    invalid_unit_interval_declared?(station_capacity_fraction_candidates(contact, policy)) or
      invalid_percent_declared?(station_capacity_percent_candidates(contact, policy))
  end

  def invalid_required_capacity_declared?(contact, policy) do
    invalid_unit_interval_declared?(required_capacity_fraction_candidates(contact, policy)) or
      invalid_percent_declared?(required_capacity_percent_candidates(contact, policy))
  end

  def station_allocation_blocked?(contact, policy) do
    availability = station_availability(contact, policy)
    capacity_fraction = station_capacity_fraction(contact, policy)
    required_capacity_fraction = required_capacity_fraction_value(contact, policy) || 0.0

    cond do
      availability in policy.station_blocking_availability -> true
      is_number(capacity_fraction) and capacity_fraction <= 0.0 -> true
      is_number(capacity_fraction) and required_capacity_fraction > capacity_fraction -> true
      true -> false
    end
  end

  def station_allocation_blocked_reason(contact, policy) do
    availability = station_availability(contact, policy)
    capacity_fraction = station_capacity_fraction(contact, policy)
    required_capacity_fraction = required_capacity_fraction_value(contact, policy) || 0.0

    cond do
      availability in policy.station_blocking_availability ->
        "ground_station_unavailable"

      is_number(capacity_fraction) and capacity_fraction <= 0.0 ->
        "ground_station_capacity_zero"

      is_number(capacity_fraction) and required_capacity_fraction > capacity_fraction ->
        "ground_station_reduced_capacity_insufficient"

      true ->
        "ground_station_capacity_zero"
    end
  end

  def station_capacity_fraction(contact, policy),
    do: first_unit_interval(station_capacity_fraction_candidates(contact, policy))

  def station_availability(contact, policy) do
    case Enum.filter(station_availability_candidates(contact), &station_availability_value?/1) do
      [] -> nil
      values -> Enum.max_by(values, &station_availability_severity(&1, policy))
    end
  end

  defp station_availability_candidates(contact) do
    [
      contact["station_availability"],
      contact["availability"],
      contact["station_calendar_status"]
    ] ++
      source_station_calendar_availability_candidates(contact["source_station_calendar_entry"]) ++
      source_station_calendar_availability_candidates(contact["source_station_calendar_overlaps"])
  end

  defp station_availability_value?(value)
       when value in ["available", "unavailable", "maintenance", "reserved", "reduced_capacity"],
       do: true

  defp station_availability_value?(_value), do: false

  defp station_availability_severity(value, policy),
    do: Map.get(policy.station_availability_severity, value, 0)

  defp source_station_calendar_availability_candidates(sources) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_calendar_availability_candidates/1)

  defp source_station_calendar_availability_candidates(%{} = source) do
    [
      source["station_availability"],
      source["availability"],
      source["station_calendar_status"],
      source["status"]
    ]
  end

  defp source_station_calendar_availability_candidates(_source), do: []

  def required_capacity_fraction_value(contact, policy) do
    first_unit_interval(required_capacity_fraction_candidates(contact, policy))
  end

  def required_capacity_fraction_source(contact) do
    cond do
      valid_capacity_value_declared?(contact["required_capacity_fraction"]) or
        valid_capacity_value_declared?(contact["required_station_capacity_fraction"]) or
        valid_capacity_value_declared?(contact["station_capacity_requirement"]) or
        valid_capacity_percent_declared?(contact["required_capacity_percent"]) or
        valid_capacity_percent_declared?(contact["required_station_capacity_percent"]) or
          valid_capacity_percent_declared?(contact["station_capacity_requirement_percent"]) ->
        nil

      valid_capacity_value_declared?(
        get_in(contact, ["throughput_model", "required_capacity_fraction"])
      ) or
        valid_capacity_value_declared?(
          get_in(contact, ["throughput_model", "required_station_capacity_fraction"])
        ) or
        valid_capacity_value_declared?(
          get_in(contact, ["throughput_model", "station_capacity_requirement"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["throughput_model", "required_capacity_percent"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["throughput_model", "required_station_capacity_percent"])
        ) or
          valid_capacity_percent_declared?(
            get_in(contact, ["throughput_model", "station_capacity_requirement_percent"])
          ) ->
        "throughput_model"

      valid_capacity_value_declared?(
        get_in(contact, ["capacity_model", "required_capacity_fraction"])
      ) or
        valid_capacity_value_declared?(
          get_in(contact, ["capacity_model", "required_station_capacity_fraction"])
        ) or
        valid_capacity_value_declared?(
          get_in(contact, ["capacity_model", "station_capacity_requirement"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["capacity_model", "required_capacity_percent"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["capacity_model", "required_station_capacity_percent"])
        ) or
          valid_capacity_percent_declared?(
            get_in(contact, ["capacity_model", "station_capacity_requirement_percent"])
          ) ->
        "capacity_model"

      valid_capacity_value_declared?(
        get_in(contact, ["activity_context", "required_capacity_fraction"])
      ) or
        valid_capacity_value_declared?(
          get_in(contact, ["activity_context", "required_station_capacity_fraction"])
        ) or
        valid_capacity_value_declared?(
          get_in(contact, ["activity_context", "station_capacity_requirement"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["activity_context", "required_capacity_percent"])
        ) or
        valid_capacity_percent_declared?(
          get_in(contact, ["activity_context", "required_station_capacity_percent"])
        ) or
          valid_capacity_percent_declared?(
            get_in(contact, ["activity_context", "station_capacity_requirement_percent"])
          ) ->
        "activity_context"

      true ->
        nil
    end
  end

  defp valid_capacity_value_declared?(value) do
    case numeric_or_nil(value) do
      value when is_number(value) -> unit_interval?(value)
      _value -> false
    end
  end

  defp valid_capacity_percent_declared?(value) do
    case numeric_or_nil(value) do
      value when is_number(value) -> value >= 0.0 and value <= 100.0
      _value -> false
    end
  end

  def first_unit_interval(values) do
    Enum.find_value(values, fn value ->
      case numeric_or_nil(value) do
        value when is_number(value) -> if(unit_interval?(value), do: value)
        _value -> nil
      end
    end)
  end

  def numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  def numeric_or_nil(value) when is_binary(value) do
    value = String.trim(value)

    case Float.parse(value) do
      {number, ""} -> number
      _result -> nil
    end
  end

  def numeric_or_nil(_value), do: nil

  defp station_capacity_fraction_candidates(contact, policy) do
    capacity_value_candidates(contact, policy.station_capacity_value_paths) ++
      source_station_capacity_fraction_candidates(
        contact["source_station_calendar_entry"],
        policy
      ) ++
      source_station_capacity_overlap_fraction_candidates(contact, policy)
  end

  defp required_capacity_fraction_candidates(contact, policy) do
    capacity_value_candidates(contact, policy.required_capacity_value_paths)
  end

  defp station_capacity_percent_candidates(contact, policy) do
    path_values(contact, policy.station_capacity_percent_paths) ++
      source_station_capacity_percent_candidates(contact["source_station_calendar_entry"], policy) ++
      source_station_capacity_overlap_percent_candidates(contact, policy)
  end

  defp source_station_capacity_overlap_fraction_candidates(contact, policy) do
    if station_calendar_entry_ambiguous?(contact) do
      []
    else
      source_station_capacity_fraction_candidates(
        contact["source_station_calendar_overlaps"],
        policy
      )
    end
  end

  defp source_station_capacity_overlap_percent_candidates(contact, policy) do
    if station_calendar_entry_ambiguous?(contact) do
      []
    else
      source_station_capacity_percent_candidates(
        contact["source_station_calendar_overlaps"],
        policy
      )
    end
  end

  defp station_calendar_entry_ambiguous?(contact) do
    contact["station_calendar_entry_ambiguous"] == true ||
      get_in(contact, ["source_station_calendar_entry", "station_calendar_entry_ambiguous"]) ==
        true
  end

  defp source_station_capacity_fraction_candidates(sources, policy) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_capacity_fraction_candidates(&1, policy))

  defp source_station_capacity_fraction_candidates(%{} = source, policy) do
    capacity_value_candidates(source, policy.station_capacity_value_paths)
  end

  defp source_station_capacity_fraction_candidates(_source, _policy), do: []

  defp source_station_capacity_percent_candidates(sources, policy) when is_list(sources),
    do: Enum.flat_map(sources, &source_station_capacity_percent_candidates(&1, policy))

  defp source_station_capacity_percent_candidates(%{} = source, policy) do
    path_values(source, policy.station_capacity_percent_paths)
  end

  defp source_station_capacity_percent_candidates(_source, _policy), do: []

  defp required_capacity_percent_candidates(contact, policy) do
    path_values(contact, policy.required_capacity_percent_paths)
  end

  defp capacity_value_candidates(value, paths) do
    Enum.map(paths, fn
      {:fraction, path} ->
        path_value(value, path)

      {:percent, path} ->
        capacity_percent_fraction(path_value(value, path))
    end)
  end

  defp path_values(value, paths), do: Enum.map(paths, &path_value(value, &1))

  defp path_value(value, [field]), do: Map.get(value, field)
  defp path_value(value, path), do: get_in(value, path)

  defp capacity_percent_fraction(value) do
    case numeric_or_nil(value) do
      value when is_number(value) and value >= 0.0 and value <= 100.0 -> value / 100.0
      _value -> nil
    end
  end

  def invalid_unit_interval_declared?(values) do
    Enum.any?(values, fn value ->
      case numeric_or_nil(value) do
        value when is_number(value) -> not unit_interval?(value)
        _value -> false
      end
    end)
  end

  defp invalid_percent_declared?(values) do
    Enum.any?(values, fn value ->
      case numeric_or_nil(value) do
        value when is_number(value) -> value < 0.0 or value > 100.0
        _value -> false
      end
    end)
  end

  defp unit_interval?(value) when is_number(value), do: value >= 0.0 and value <= 1.0
end
