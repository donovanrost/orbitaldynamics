defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.StationPressure.Summary do
  @moduledoc false

  alias __MODULE__.GroupingFields
  alias __MODULE__.Precedence
  alias __MODULE__.Rows

  import Rows,
    only: [
      contact_id_count: 1,
      fallback_contact_count: 1,
      fallback_review_contact_count: 1,
      review_row?: 1,
      rows: 1,
      sorted_non_empty_values: 1,
      summary_contact_id: 1
    ]

  def contact_count(report) do
    case rows(report) do
      [] -> fallback_contact_count(report)
      rows -> contact_id_count(rows)
    end
  end

  def contact_ids(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("station_pressure_contact_ids", [])
        |> List.wrap()
        |> sorted_non_empty_values()

      rows ->
        rows
        |> Enum.map(&summary_contact_id/1)
        |> sorted_non_empty_values()
    end
  end

  def review_contact_count(report) do
    case rows(report) do
      [] -> fallback_review_contact_count(report)
      rows -> rows |> Enum.filter(&review_row?/1) |> contact_id_count()
    end
  end

  def review_contact_ids(report) do
    case rows(report) do
      [] ->
        report
        |> Map.get("station_pressure_review_contact_ids", [])
        |> List.wrap()
        |> sorted_non_empty_values()

      rows ->
        rows
        |> Enum.filter(&review_row?/1)
        |> Enum.map(&summary_contact_id/1)
        |> sorted_non_empty_values()
    end
  end

  defdelegate ground_station_counts(report), to: GroupingFields
  defdelegate contact_ids_by_ground_station(report), to: GroupingFields
  defdelegate availability_counts(report), to: GroupingFields
  defdelegate contact_ids_by_availability(report), to: GroupingFields

  def precedence_availability_counts(report) do
    Precedence.precedence_availability_counts(report)
  end

  def contact_ids_by_precedence_availability(report) do
    Precedence.contact_ids_by_precedence_availability(report)
  end

  def precedence_rank_counts(report) do
    Precedence.precedence_rank_counts(report)
  end

  def contact_ids_by_precedence_rank(report) do
    Precedence.contact_ids_by_precedence_rank(report)
  end

  defdelegate status_counts(report), to: GroupingFields
  defdelegate contact_ids_by_status(report), to: GroupingFields
  defdelegate direction_counts(report), to: GroupingFields
  defdelegate contact_ids_by_direction(report), to: GroupingFields
  defdelegate contact_ids_by_direction_and_station(report), to: GroupingFields
end
