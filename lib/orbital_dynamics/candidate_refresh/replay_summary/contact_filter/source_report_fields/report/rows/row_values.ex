defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.RowValues do
  @moduledoc false

  alias __MODULE__.ContactSources
  alias __MODULE__.Normalization

  def invalid_input_row?(row) do
    row = stringify_keys(row)

    row["invalid_contact_input"] == true or
      row["suppressed_reason"] == "invalid_contact_input" or
      row["required_operator_action"] == "review_invalid_contact_filter_input" or
      row["action"] == "review_invalid_contact_filter_input"
  end

  defdelegate suppressed_reason_contact_pairs(report), to: ContactSources
  defdelegate direction_contact_pairs(report), to: ContactSources
  defdelegate row_contact_id(row), to: ContactSources
  defdelegate row_station_calendar_entry_id(row), to: ContactSources
  defdelegate row_station_calendar_provider_entry_id(row), to: ContactSources
  defdelegate row_station_reservation_id(row), to: ContactSources

  def suppressed_candidate_rows(report) do
    report
    |> Map.get("suppressed_candidates", [])
    |> Enum.map(&stringify_keys/1)
  end

  def station_suppression_rows(report) do
    report
    |> suppressed_candidate_rows()
    |> Enum.filter(&(row_station_state(&1) != nil))
  end

  def row_availability(row) do
    case row_station_state(row) do
      %{"availability" => availability} -> availability
      _state -> nil
    end
  end

  def row_status(row) do
    case row_station_state(row) do
      %{"status" => status} -> status
      _state -> nil
    end
  end

  def stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)
  def stringify_keys(value), do: Normalization.stringify_keys(value)

  defp row_station_state(row) do
    row
    |> Map.get("suppressed_reason")
    |> normalized_token()
    |> station_state_for_reason()
  end

  defp station_state_for_reason("ground_station_unavailable"),
    do: %{"availability" => "unavailable", "status" => "unavailable"}

  defp station_state_for_reason("ground_station_reserved"),
    do: %{"availability" => "reserved", "status" => "reserved"}

  defp station_state_for_reason("ground_station_capacity_zero"),
    do: %{"availability" => "reduced_capacity", "capacity_fraction" => 0.0}

  defp station_state_for_reason(_reason), do: nil

  def normalize_direction(direction), do: Normalization.normalize_direction(direction)
  defp normalized_token(value), do: Normalization.normalized_token(value)
end
