defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.ProviderReservation.RequestSummary.Rows.RowValues do
  @moduledoc false

  alias __MODULE__.ContactMaps
  alias __MODULE__.Normalization

  def candidate_rows(report) do
    report
    |> rows_for_summary()
    |> Enum.filter(&candidate_row?/1)
  end

  def request_rows(report) do
    report
    |> candidate_rows()
    |> Enum.filter(&request_row?/1)
  end

  def review_rows(report) do
    report
    |> candidate_rows()
    |> Enum.reject(&request_ready_row?/1)
  end

  def candidate_row?(row) do
    row["allocation_status"] == "allocated" and
      effective_allocation_status(row) == "allocated" and
      station_reservation?(row)
  end

  def request_row?(row), do: candidate_row?(row) and request_ready_row?(row)

  def request_ready_row?(row) do
    normalized_token(row["station_reservation_match_status"]) in [
      "matched",
      "owner_matched"
    ] and station_reservation_ids(row) != []
  end

  def request_summary_rows?(report) do
    Map.get(report, "source_summary_full_rows_present") == true and
      Map.get(report, "source_summary_schema_contract") ==
        "contact_allocation_provider_reservation_request_summary.v1"
  end

  def no_request_rows(rows), do: Enum.reject(rows, &candidate_row?/1)

  def rows_for_summary(report) do
    report
    |> Map.get("rows", [])
    |> Enum.map(&normalize_row(stringify_keys(&1)))
  end

  defdelegate contact_ids_by_direction_and_station(rows), to: ContactMaps
  defdelegate group_key(row, field), to: ContactMaps

  def station_reservation_ids(row) do
    [
      row["station_reservation_id"],
      row["station_calendar_reservation_ids"]
    ]
    |> List.flatten()
    |> Enum.map(&stable_id_or_nil/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defdelegate summary_contact_id(row), to: ContactMaps
  defdelegate summary_direction(row), to: ContactMaps
  defdelegate grouped_contact_ids(pairs), to: ContactMaps
  defdelegate map_value_lists(value), to: ContactMaps
  defdelegate nested_map_value_lists(value), to: ContactMaps
  defdelegate sorted_non_empty_values(values), to: ContactMaps

  defp effective_allocation_status(%{"effective_allocation_status" => status})
       when is_binary(status) and status != "",
       do: normalized_token(status)

  defp effective_allocation_status(%{"allocation_status" => "allocated"} = row) do
    if normalized_token(row["approval_status"]) == "blocked_by_policy",
      do: "policy_blocked",
      else: "allocated"
  end

  defp effective_allocation_status(row), do: normalized_token(row["allocation_status"])

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

  defp stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
  defp normalized_token(value), do: Normalization.normalized_token(value)
  defp stringify_keys(value), do: Normalization.stringify_keys(value)
end
