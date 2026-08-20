defmodule OrbitalDynamics.Communications.LinkCapacity.ThroughputEvidence do
  @moduledoc false

  alias OrbitalDynamics.Communications.LinkCapacity.{
    ContactIdentity,
    ContactNormalization,
    StationAvailability,
    StationCapacity
  }

  alias OrbitalDynamics.Communications.DownlinkLinkBudget

  def contact_capacity_fraction(contact) do
    if contact_station_availability(contact) == "unavailable" do
      0.0
    else
      contact
      |> capacity_fraction_value()
      |> clamp_unit_interval()
    end
  end

  def capacity_fraction_value(contact), do: StationCapacity.value(contact)

  def total_estimated_throughput(contacts) do
    contacts
    |> Enum.map(&(estimated_throughput_value(&1) || 0.0))
    |> Enum.sum()
  end

  def total_capacity_adjusted_throughput(contacts) do
    contacts
    |> Enum.map(fn contact ->
      (estimated_throughput_value(contact) || 0.0) * contact_capacity_fraction(contact)
    end)
    |> Enum.sum()
  end

  def actual_throughput_resolution(selected_downlinks, contact_id_counts) do
    selected_downlinks
    |> Enum.filter(
      &(is_number(actual_throughput_value(&1)) or is_number(actual_throughput_model_value(&1)))
    )
    |> Enum.group_by(&contact_id/1)
    |> Enum.reduce(
      %{matched_contacts: [], unmatched_contact_ids: [], ambiguous_contact_ids: []},
      fn {contact_id, contacts}, acc ->
        case {Map.get(contact_id_counts, contact_id, 0), contacts} do
          {0, _contacts} ->
            Map.update!(acc, :unmatched_contact_ids, &[contact_id | &1])

          {1, [contact]} ->
            Map.update!(acc, :matched_contacts, &[contact | &1])

          {_candidate_count, _contacts} ->
            Map.update!(acc, :ambiguous_contact_ids, &[contact_id | &1])
        end
      end
    )
    |> Map.new(fn
      {:matched_contacts, contacts} -> {:matched_contacts, Enum.sort_by(contacts, &contact_id/1)}
      {key, ids} -> {key, ids |> Enum.uniq() |> Enum.sort()}
    end)
  end

  def actual_completion_resolution(selected_downlinks, contact_id_counts) do
    selected_downlinks
    |> Enum.filter(&is_number(completed_fraction_value(&1)))
    |> Enum.group_by(&contact_id/1)
    |> Enum.reduce(
      %{matched_contacts: [], unmatched_contact_ids: [], ambiguous_contact_ids: []},
      fn {contact_id, contacts}, acc ->
        case {Map.get(contact_id_counts, contact_id, 0), contacts} do
          {0, _contacts} ->
            Map.update!(acc, :unmatched_contact_ids, &[contact_id | &1])

          {1, [contact]} ->
            Map.update!(acc, :matched_contacts, &[contact | &1])

          {_candidate_count, _contacts} ->
            Map.update!(acc, :ambiguous_contact_ids, &[contact_id | &1])
        end
      end
    )
    |> Map.new(fn
      {:matched_contacts, contacts} -> {:matched_contacts, Enum.sort_by(contacts, &contact_id/1)}
      {key, ids} -> {key, ids |> Enum.uniq() |> Enum.sort()}
    end)
  end

  def unresolved_selected_contact_ids(selected_downlinks, unresolved_ids, ground_station_id, fun) do
    unresolved_id_set = MapSet.new(unresolved_ids)

    selected_downlinks
    |> Enum.filter(&(contact_ground_station_id(&1) == ground_station_id))
    |> Enum.filter(fun)
    |> Enum.map(&contact_id/1)
    |> Enum.filter(&MapSet.member?(unresolved_id_set, &1))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def actual_throughput_evidence?(contact) do
    is_number(actual_throughput_value(contact)) or
      is_number(actual_throughput_model_value(contact))
  end

  def actual_completion_evidence?(contact), do: is_number(completed_fraction_value(contact))

  def optional_contact_count([]), do: nil
  def optional_contact_count(ids), do: length(ids)

  def optional_contact_ids([]), do: nil
  def optional_contact_ids(ids), do: ids

  def actual_throughput_mb([]), do: nil

  def actual_throughput_mb(contacts) do
    contacts
    |> Enum.map(&(actual_throughput_value(&1) || actual_throughput_model_value(&1)))
    |> Enum.sum()
  end

  def actual_data_rate_throughput_derivations(contacts) do
    contacts
    |> Enum.map(fn contact ->
      case actual_data_rate_throughput_derivation(contact) do
        %{} = derivation -> Map.put(derivation, "contact_id", contact_id(contact))
        _derivation -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.sort_by(& &1["contact_id"])
    |> case do
      [] -> nil
      derivations -> derivations
    end
  end

  def actual_completion_fraction([]), do: nil

  def actual_completion_fraction(contacts) do
    values =
      contacts
      |> Enum.map(&completed_fraction_value/1)
      |> Enum.reject(&is_nil/1)

    case values do
      [] -> nil
      values -> Enum.sum(values) / length(values)
    end
  end

  def estimated_throughput_value(contact) do
    DownlinkLinkBudget.supported_volume_mb(contact) ||
      first_number(contact, [
        "estimated_throughput_mb",
        "estimated_downlink_mb",
        "planned_throughput_mb",
        "planned_data_volume_mb",
        "estimated_data_volume_mb",
        "data_volume_mb"
      ]) ||
      first_number(get_in(contact, ["throughput_model"]) || %{}, [
        "estimated_throughput_mb",
        "estimated_downlink_mb",
        "planned_throughput_mb",
        "planned_data_volume_mb",
        "estimated_data_volume_mb",
        "data_volume_mb"
      ]) ||
      data_rate_derived_throughput_mb(contact)
  end

  def actual_throughput_value(contact) do
    explicit_actual_throughput_value(contact) ||
      actual_data_rate_derived_throughput_mb(contact)
  end

  def explicit_actual_throughput_value(contact) do
    first_number(contact, [
      "actual_throughput_mb",
      "actual_downlink_mb",
      "actual_data_volume_mb",
      "delivered_data_mb",
      "received_data_mb"
    ])
  end

  def actual_throughput_model_value(contact) do
    explicit_actual_throughput_model_value(contact) ||
      actual_data_rate_derived_throughput_mb(get_in(contact, ["throughput_model"]) || %{})
  end

  def explicit_actual_throughput_model_value(contact) do
    first_number(get_in(contact, ["throughput_model"]) || %{}, [
      "actual_throughput_mb",
      "actual_downlink_mb",
      "actual_data_volume_mb",
      "delivered_data_mb",
      "received_data_mb"
    ])
  end

  def data_rate_derived_throughput_mb(contact) do
    duration_s = contact_duration_s(contact)

    cond do
      not is_number(duration_s) or duration_s <= 0.0 ->
        nil

      rate_mb_s = data_rate_mb_s(contact) ->
        max(rate_mb_s, 0.0) * duration_s

      rate_mbps = data_rate_mbps(contact) ->
        max(rate_mbps, 0.0) * duration_s / 8.0

      true ->
        nil
    end
  end

  def actual_data_rate_derived_throughput_mb(contact) do
    case actual_data_rate_throughput_derivation_from_contact(contact) do
      %{"actual_throughput_mb" => actual_throughput_mb} when is_number(actual_throughput_mb) ->
        actual_throughput_mb

      _derivation ->
        nil
    end
  end

  def actual_data_rate_throughput_derivation(contact) do
    cond do
      is_number(explicit_actual_throughput_value(contact)) ->
        nil

      derivation = actual_data_rate_throughput_derivation_from_contact(contact) ->
        derivation

      is_number(explicit_actual_throughput_model_value(contact)) ->
        nil

      true ->
        actual_data_rate_throughput_derivation_from_contact(
          get_in(contact, ["throughput_model"]) || %{}
        )
    end
  end

  def actual_data_rate_throughput_derivation_from_contact(contact) do
    duration_s = actual_duration_s(contact)

    cond do
      not is_number(duration_s) or duration_s <= 0.0 ->
        nil

      rate_mb_s = actual_data_rate_mb_s(contact) ->
        normalized_rate_mb_s = max(rate_mb_s, 0.0)

        %{
          "derivation" => "actual_data_rate_mb_s * duration_s",
          "rate_unit" => "MB/s",
          "actual_data_rate_mb_s" => normalized_rate_mb_s,
          "duration_s" => duration_s,
          "actual_throughput_mb" => normalized_rate_mb_s * duration_s
        }

      rate_mbps = actual_data_rate_mbps(contact) ->
        normalized_rate_mbps = max(rate_mbps, 0.0)

        %{
          "derivation" => "actual_data_rate_mbps * duration_s / 8",
          "rate_unit" => "Mbps",
          "actual_data_rate_mbps" => normalized_rate_mbps,
          "duration_s" => duration_s,
          "actual_throughput_mb" => normalized_rate_mbps * duration_s / 8.0
        }

      true ->
        nil
    end
  end

  def data_rate_mb_s(contact) do
    first_number(contact, [
      "data_rate_mb_s",
      "downlink_rate_mb_s",
      "throughput_mb_s",
      "estimated_throughput_mb_s"
    ]) ||
      first_number(get_in(contact, ["throughput_model"]) || %{}, [
        "data_rate_mb_s",
        "downlink_rate_mb_s",
        "throughput_mb_s",
        "estimated_throughput_mb_s"
      ])
  end

  def data_rate_mbps(contact) do
    case DownlinkLinkBudget.supported_data_rate_bps(contact) do
      value when is_number(value) ->
        value / 1_000_000.0

      _value ->
        first_number(contact, [
          "data_rate_mbps",
          "downlink_rate_mbps",
          "bitrate_mbps",
          "estimated_bitrate_mbps"
        ]) ||
          first_number(get_in(contact, ["throughput_model"]) || %{}, [
            "data_rate_mbps",
            "downlink_rate_mbps",
            "bitrate_mbps",
            "estimated_bitrate_mbps"
          ])
    end
  end

  def actual_data_rate_mb_s(contact) do
    first_number(contact, [
      "actual_data_rate_mb_s",
      "actual_downlink_rate_mb_s",
      "delivered_rate_mb_s",
      "received_rate_mb_s"
    ])
  end

  def actual_data_rate_mbps(contact) do
    first_number(contact, [
      "actual_data_rate_mbps",
      "actual_downlink_rate_mbps",
      "delivered_rate_mbps",
      "received_rate_mbps"
    ])
  end

  def contact_duration_s(contact) do
    first_number(contact, ["duration_s", "contact_duration_s", "scheduled_duration_s"]) ||
      first_number(get_in(contact, ["throughput_model"]) || %{}, [
        "duration_s",
        "contact_duration_s",
        "scheduled_duration_s"
      ]) ||
      interval_duration_s(contact)
  end

  def actual_duration_s(contact) do
    first_number(contact, ["actual_duration_s", "actual_contact_duration_s"]) ||
      contact_duration_s(contact)
  end

  def interval_duration_s(contact) do
    starts_at_s = numeric_value(Map.get(contact, "starts_at_s"))
    ends_at_s = numeric_value(Map.get(contact, "ends_at_s"))

    if is_number(starts_at_s) and is_number(ends_at_s) do
      ends_at_s - starts_at_s
    end
  end

  def completed_fraction_value(contact) do
    case completed_fraction_values(contact) do
      [] ->
        nil

      values ->
        values
        |> Enum.find_value(fn {_field, value} ->
          case numeric_value(value) do
            number when is_number(number) and number >= 0.0 and number <= 1.0 -> number
            _value -> nil
          end
        end)
    end
  end

  def completed_fraction_values(contact) do
    top_level =
      declared_values(contact, [
        "completed_fraction",
        "completion_fraction",
        "contact_completion_fraction"
      ])

    throughput_model =
      contact
      |> get_in(["throughput_model"])
      |> case do
        %{} = throughput_model ->
          declared_values(throughput_model, [
            "completed_fraction",
            "completion_fraction",
            "contact_completion_fraction"
          ])

        _value ->
          []
      end

    top_level ++ throughput_model
  end

  def declared_values(map, keys) when is_map(map) do
    Enum.flat_map(keys, fn key ->
      case Map.fetch(map, key) do
        {:ok, nil} -> []
        {:ok, value} -> [{key, value}]
        :error -> []
      end
    end)
  end

  def first_number(map, keys) do
    Enum.find_value(keys, fn key ->
      value = Map.get(map, key)
      numeric_value(value)
    end)
  end

  def actual_throughput_contact_ids(contacts) do
    contacts
    |> Enum.map(&contact_id/1)
    |> Enum.sort()
  end

  def actual_completion_contact_ids(contacts), do: actual_throughput_contact_ids(contacts)

  defp contact_station_availability(contact), do: StationAvailability.contact_value(contact)
  defp contact_id(contact), do: ContactIdentity.contact_id!(contact)
  defp contact_ground_station_id(contact), do: ContactIdentity.ground_station_id(contact)
  defp numeric_value(value), do: ContactNormalization.numeric_value(value)
  defp clamp_unit_interval(value), do: value |> max(0.0) |> min(1.0)
end
