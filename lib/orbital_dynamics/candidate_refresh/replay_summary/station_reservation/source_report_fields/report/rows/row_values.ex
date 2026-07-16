defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.StationReservation.SourceReportFields.Report.Rows.RowValues do
  @moduledoc false

  alias __MODULE__.Normalization

  def single_value_count(value) do
    case normalized_token(value) do
      value when value in [nil, ""] -> nil
      value -> %{value => 1}
    end
  end

  def evidence_row?(row) do
    row
    |> stringify_keys()
    |> row_values([
      "station_reservation_id",
      "station_calendar_reservation_ids",
      "reservation_id",
      "reservation_ids"
    ])
    |> Enum.any?(&non_empty?/1)
  end

  def expiration_evidence_row?(row) do
    row
    |> stringify_keys()
    |> row_values([
      "station_reservation_expires_at_s",
      "station_calendar_reservation_expires_at_s",
      "reservation_expires_at_s",
      "reservation_expires_at"
    ])
    |> Enum.any?(&(&1 not in [nil, ""]))
  end

  def report_rows(report) do
    Map.get(report, "affected_contacts", []) ++
      Map.get(report, "provider_calendar_contention_groups", [])
  end

  def row_values(row, fields) do
    fields
    |> Enum.flat_map(fn field ->
      row
      |> Map.get(field)
      |> List.wrap()
    end)
    |> Enum.map(&encode_value/1)
    |> Enum.reject(&(&1 in [nil, ""]))
  end

  def stable_id_or_nil(value), do: Normalization.stable_id_or_nil(value)

  def non_empty?(value) when value in [nil, ""], do: false
  def non_empty?([]), do: false
  def non_empty?(_value), do: true

  def stringify_keys(value), do: Normalization.stringify_keys(value)

  def normalize_direction(direction), do: Normalization.normalize_direction(direction)

  defp normalized_token(value), do: Normalization.normalized_token(value)

  defp encode_value(value), do: Normalization.encode_value(value)
end
