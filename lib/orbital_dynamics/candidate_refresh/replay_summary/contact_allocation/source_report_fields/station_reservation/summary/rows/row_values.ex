defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.StationReservation.Summary.Rows.RowValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common

  import Common, only: [sorted_string_values: 1]

  alias __MODULE__.Expiration
  alias __MODULE__.Normalization

  def expiration_now_s(report),
    do: Expiration.expiration_now_s(report)

  def expiration_rows(report) do
    now_s = expiration_now_s(report)

    report
    |> rows()
    |> Enum.map(fn row ->
      expires_at_s = station_reservation_expires_at_s(row)

      row
      |> Map.put("station_reservation_summary_expires_at_s", expires_at_s)
      |> Map.put(
        "station_reservation_expiration_status",
        Expiration.expiration_status(expires_at_s, now_s)
      )
    end)
  end

  def station_reservation_expires_at_s(station) do
    Expiration.station_reservation_expires_at_s(station)
  end

  def rows(report) do
    report
    |> Map.get("rows", [])
    |> Enum.filter(&is_map/1)
    |> Enum.map(&normalize_row(stringify_keys(&1)))
    |> Enum.filter(&station_reservation?/1)
  end

  def group_key(row, "direction"), do: summary_direction(row)
  def group_key(row, field), do: stable_id_or_nil(row[field]) || normalized_token(row[field])

  def summary_contact_id(row) do
    stable_id_or_nil(row["contact_id"]) ||
      stable_id_or_nil(row["id"]) ||
      stable_id_or_nil(get_in(row, ["activity_context", "activity_id"]))
  end

  def grouped_contact_ids(pairs) do
    pairs
    |> Enum.reject(fn {key, contact_id} -> key in [nil, ""] or contact_id in [nil, ""] end)
    |> Enum.group_by(fn {key, _contact_id} -> key end, fn {_key, contact_id} -> contact_id end)
    |> Map.new(fn {key, contact_ids} -> {key, sorted_non_empty_values(contact_ids)} end)
    |> non_empty_map()
  end

  def map_value_lists(%{} = value_map) do
    value_map
    |> Enum.reduce(%{}, fn {key, values}, acc ->
      case sorted_string_values(List.wrap(values)) do
        [] -> acc
        values -> Map.put(acc, to_string(key), values)
      end
    end)
    |> non_empty_map()
  end

  def map_value_lists(_value), do: nil

  def sorted_non_empty_values(values) do
    case sorted_string_values(values) do
      [] -> nil
      values -> values
    end
  end

  def normalize_number_list(value), do: Normalization.normalize_number_list(value)

  def numeric_value(value), do: Normalization.numeric_value(value)

  def stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)

  defp station_reservation?(row) do
    Enum.any?(
      [
        row["station_reservation_match_status"],
        row["station_reservation_status"],
        row["station_reserved_by"],
        row["station_reservation_id"],
        row["station_reservation_expires_at_s"],
        row["station_calendar_reservation_expires_at_s"],
        row["reservation_expires_at_s"]
      ],
      &(group_key(%{"value" => &1}, "value") not in [nil, ""])
    )
  end

  defp normalize_row(row) do
    row
    |> normalize_status_field("allocation_status")
    |> normalize_status_field("effective_allocation_status")
    |> normalize_status_field("review_status")
    |> normalize_status_field("approval_status")
    |> normalize_policy_decision()
  end

  defp normalize_status_field(row, field) do
    case Map.get(row, field) do
      value when value in [nil, ""] -> row
      value -> Map.put(row, field, normalized_token(value))
    end
  end

  defp normalize_policy_decision(%{"policy_decision" => %{} = decision} = row) do
    decision =
      decision
      |> stringify_keys()
      |> normalize_status_field("classification")

    Map.put(row, "policy_decision", decision)
  end

  defp normalize_policy_decision(row), do: row

  defp summary_direction(row) do
    [
      row["direction"],
      get_in(row, ["activity_context", "direction"]),
      get_in(row, ["source_contact_candidate", "direction"]),
      get_in(row, ["source_contact_candidate", "activity_context", "direction"]),
      get_in(row, ["source_contention_recommendation", "direction"]),
      row["type"],
      get_in(row, ["source_contact_candidate", "type"])
    ]
    |> Enum.map(&normalize_direction/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  defp normalize_direction(direction), do: Normalization.normalize_direction(direction)
  defp normalized_token(value), do: Normalization.normalized_token(value)
  defp stringify_keys(value), do: Normalization.stringify_keys(value)
  defp non_empty_map(map), do: Normalization.non_empty_map(map)
end
