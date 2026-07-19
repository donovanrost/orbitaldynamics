defmodule OrbitalDynamics.Communications.LinkCapacity.DownlinkRequirement do
  @moduledoc false

  alias OrbitalDynamics.Communications.LinkCapacity.{ContactIdentity, ContactNormalization}

  @contact_paths [
    ["required_downlink_mb"],
    ["metadata", "required_downlink_mb"],
    ["throughput_model", "required_downlink_mb"]
  ]
  @source_paths [
    ["downlink_completion_source"],
    ["metadata", "downlink_completion_source"],
    ["throughput_model", "downlink_completion_source"],
    ["activity_context", "downlink_completion_source"]
  ]
  @sources_paths [
    ["downlink_completion_sources"],
    ["metadata", "downlink_completion_sources"],
    ["throughput_model", "downlink_completion_sources"],
    ["activity_context", "downlink_completion_sources"]
  ]

  def contact_paths, do: @contact_paths
  def source_paths, do: @source_paths
  def sources_paths, do: @sources_paths

  def report_required_mb(policy, contacts) do
    numeric_value(Map.get(policy, "required_downlink_mb")) ||
      policy
      |> Map.get("required_downlink_mb_by_ground_station", %{})
      |> station_values()
      |> Map.values()
      |> Enum.sum()
      |> positive_or_nil() ||
      total_contact_required_mb(contacts)
  end

  def station_required_mb(ground_station_id, policy, contacts) do
    policy
    |> policy_station_values()
    |> Map.get(ground_station_id) ||
      total_contact_required_mb(contacts)
  end

  def invalid_policy_station_ids(policy) do
    policy
    |> Map.get("required_downlink_mb_by_ground_station", %{})
    |> invalid_station_ids()
  end

  def required_contact_ids(contacts) do
    contacts
    |> Enum.filter(fn contact ->
      case contact_required_mb(contact) do
        value when is_number(value) and value > 0.0 -> true
        _value -> false
      end
    end)
    |> Enum.map(&ContactIdentity.contact_id!/1)
    |> Enum.sort()
  end

  def completion_source(policy, contacts) do
    cond do
      positive_number?(numeric_value(Map.get(policy, "required_downlink_mb"))) ->
        "link_capacity.policy.required_downlink_mb"

      map_size(policy_station_values(policy)) > 0 ->
        "link_capacity.policy.required_downlink_mb_by_ground_station"

      total_contact_required_mb(contacts) ->
        "link_capacity.contact.required_downlink_mb"

      true ->
        nil
    end
  end

  def completion_source(ground_station_id, policy, contacts) do
    cond do
      Map.has_key?(policy_station_values(policy), ground_station_id) ->
        "link_capacity.policy.required_downlink_mb_by_ground_station"

      total_contact_required_mb(contacts) ->
        "link_capacity.contact.required_downlink_mb"

      true ->
        nil
    end
  end

  def completion_sources(policy, contacts) do
    cond do
      positive_number?(numeric_value(Map.get(policy, "required_downlink_mb"))) ->
        ["link_capacity.policy.required_downlink_mb"]

      policy_station_values(policy) != %{} ->
        policy
        |> policy_station_values()
        |> Map.keys()
        |> Enum.sort()
        |> Enum.map(&"link_capacity.policy.required_downlink_mb_by_ground_station:#{&1}")

      true ->
        contact_completion_sources(contacts)
    end
  end

  def completion_sources(ground_station_id, policy, contacts) do
    if Map.has_key?(policy_station_values(policy), ground_station_id) do
      ["link_capacity.policy.required_downlink_mb_by_ground_station:#{ground_station_id}"]
    else
      contact_completion_sources(contacts)
    end
  end

  def selected_shortfall_mb(nil, _selected_capacity_adjusted), do: nil

  def selected_shortfall_mb(required_downlink_mb, selected_capacity_adjusted)
      when is_number(required_downlink_mb) and is_number(selected_capacity_adjusted) do
    max(required_downlink_mb - selected_capacity_adjusted, 0.0)
  end

  def selected_shortfall_mb(_required_downlink_mb, _selected_capacity_adjusted), do: nil

  def status(nil, _selected_capacity_adjusted), do: nil

  def status(required_downlink_mb, selected_capacity_adjusted)
      when is_number(required_downlink_mb) and is_number(selected_capacity_adjusted) and
             selected_capacity_adjusted >= required_downlink_mb,
      do: "satisfied"

  def status(required_downlink_mb, selected_capacity_adjusted)
      when is_number(required_downlink_mb) and is_number(selected_capacity_adjusted) and
             selected_capacity_adjusted < required_downlink_mb,
      do: "shortfall"

  def status(_required_downlink_mb, _selected_capacity_adjusted), do: nil

  def actual_shortfall_mb(_required_downlink_mb, nil), do: nil

  def actual_shortfall_mb(required_downlink_mb, actual_throughput_mb),
    do: selected_shortfall_mb(required_downlink_mb, actual_throughput_mb)

  def actual_completion_ratio(required_downlink_mb, actual_throughput_mb)
      when is_number(required_downlink_mb) and required_downlink_mb > 0.0 and
             is_number(actual_throughput_mb) do
    actual_throughput_mb
    |> Kernel./(required_downlink_mb)
    |> clamp_unit_interval()
  end

  def actual_completion_ratio(_required_downlink_mb, _actual_throughput_mb), do: nil

  def actual_status(_required_downlink_mb, nil), do: nil

  def actual_status(required_downlink_mb, actual_throughput_mb),
    do: status(required_downlink_mb, actual_throughput_mb)

  def policy_station_values(policy) do
    policy
    |> Map.get("required_downlink_mb_by_ground_station", %{})
    |> station_values()
  end

  defp station_values(%{} = values) do
    values
    |> Enum.map(fn {station_id, value} ->
      {ContactIdentity.stable_id_or_nil(station_id), numeric_value(value)}
    end)
    |> Enum.reject(fn {station_id, value} -> is_nil(station_id) or is_nil(value) end)
    |> Map.new()
  end

  defp station_values(_values), do: %{}

  defp invalid_station_ids(%{} = values) do
    values
    |> Enum.filter(fn {station_id, value} ->
      is_nil(ContactIdentity.stable_id_or_nil(station_id)) and
        positive_number?(numeric_value(value))
    end)
    |> Enum.map(fn {station_id, _value} -> station_id_to_string(station_id) end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp invalid_station_ids(_values), do: []

  defp station_id_to_string(station_id) when is_binary(station_id), do: station_id

  defp station_id_to_string(station_id) when is_atom(station_id) and not is_nil(station_id),
    do: Atom.to_string(station_id)

  defp station_id_to_string(station_id) when is_integer(station_id),
    do: Integer.to_string(station_id)

  defp station_id_to_string(station_id) when is_float(station_id),
    do: Float.to_string(station_id)

  defp station_id_to_string(station_id), do: inspect(station_id)

  defp total_contact_required_mb(contacts) do
    contacts
    |> Enum.map(&contact_required_mb/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.sum()
    |> positive_or_nil()
  end

  defp contact_completion_sources(contacts) when is_list(contacts) do
    contacts
    |> Enum.filter(fn contact ->
      case contact_required_mb(contact) do
        value when is_number(value) and value > 0.0 -> true
        _value -> false
      end
    end)
    |> Enum.flat_map(&contact_completion_sources/1)
    |> Enum.uniq()
    |> Enum.sort()
    |> empty_list_to_nil()
  end

  defp contact_completion_sources(contact) when is_map(contact) do
    first_string_list(path_values(contact, @sources_paths)) ||
      first_string_list(Enum.map(path_values(contact, @source_paths), &[&1])) ||
      ["link_capacity.contact.required_downlink_mb:#{ContactIdentity.contact_id!(contact)}"]
  end

  defp first_string_list(values) do
    Enum.find_value(values, fn
      values when is_list(values) ->
        values =
          values
          |> Enum.map(fn
            value when is_binary(value) -> value
            value when is_atom(value) and not is_nil(value) -> Atom.to_string(value)
            value when is_integer(value) -> Integer.to_string(value)
            _value -> nil
          end)
          |> Enum.reject(&(&1 == ""))
          |> Enum.reject(&is_nil/1)

        if values == [], do: nil, else: values

      _value ->
        nil
    end)
  end

  defp contact_required_mb(contact) do
    contact
    |> path_values(@contact_paths)
    |> Enum.find_value(&numeric_value/1)
  end

  defp path_values(value, paths), do: Enum.map(paths, &path_value(value, &1))
  defp path_value(value, [field]), do: Map.get(value, field)
  defp path_value(value, path), do: get_in(value, path)

  defp positive_number?(value), do: is_number(value) and value > 0
  defp positive_or_nil(value) when is_number(value) and value > 0.0, do: value
  defp positive_or_nil(_value), do: nil
  defp empty_list_to_nil([]), do: nil
  defp empty_list_to_nil(values), do: values
  defp clamp_unit_interval(value), do: value |> max(0.0) |> min(1.0)
  defp numeric_value(value), do: ContactNormalization.numeric_value(value)
end
