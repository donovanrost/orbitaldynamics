defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.ReservationConflict.Rows.RowValues do
  @moduledoc false

  alias __MODULE__.ContactMaps
  alias __MODULE__.Normalization

  def rows(report) do
    report
    |> Map.get("rows", [])
    |> Enum.filter(&is_map/1)
    |> Enum.map(&normalize_row(stringify_keys(&1)))
    |> Enum.filter(&reservation_conflict?/1)
  end

  defdelegate fallback_contact_count(report), to: ContactMaps
  defdelegate contact_ids_by_direction_and_station_from_rows(rows), to: ContactMaps
  defdelegate summary_direction(row), to: ContactMaps
  defdelegate group_key(row, field), to: ContactMaps
  defdelegate summary_contact_id(row), to: ContactMaps
  defdelegate id_map_counts(contact_ids_by_key), to: ContactMaps
  defdelegate grouped_contact_counts(pairs), to: ContactMaps
  defdelegate grouped_contact_ids(pairs), to: ContactMaps
  defdelegate map_value_lists(value), to: ContactMaps
  defdelegate sorted_non_empty_values(values), to: ContactMaps

  def stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)

  defp reservation_conflict?(row) do
    match_status = normalized_token(row["station_reservation_match_status"])
    match_status not in [nil, "", "matched", "owner_matched"]
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

  defp normalized_token(value), do: Normalization.normalized_token(value)
  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
