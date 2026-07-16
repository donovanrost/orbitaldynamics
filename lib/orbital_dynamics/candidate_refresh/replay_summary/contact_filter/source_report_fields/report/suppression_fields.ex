defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.SuppressionFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows,
    only: [
      count_rows: 2,
      direction_contact_pairs: 1,
      grouped_id_counts: 1,
      grouped_ids: 1,
      invalid_input_row?: 1,
      map_value_lists: 1,
      normalize_direction_count_map: 1,
      numeric_report_count: 2,
      row_contact_id: 1,
      sorted_string_values: 1,
      suppressed_candidate_rows: 1,
      suppressed_reason_contact_pairs: 1
    ]

  def row_count(report), do: suppressed_candidate_count(report)

  def suppressed_candidate_count(report) do
    numeric_report_count(report, "suppressed_candidate_count")
    |> case do
      0 -> report |> suppressed_candidate_rows() |> length()
      count -> count
    end
  end

  def invalid_contact_input_count(report) do
    numeric_report_count(report, "invalid_contact_input_count")
    |> case do
      0 ->
        report
        |> suppressed_candidate_rows()
        |> Enum.count(&invalid_input_row?/1)

      count ->
        count
    end
  end

  def invalid_contact_input_ids(report) do
    explicit_ids =
      report
      |> Map.get("invalid_contact_input_ids")
      |> List.wrap()

    row_ids =
      report
      |> suppressed_candidate_rows()
      |> Enum.filter(&invalid_input_row?/1)
      |> Enum.map(&row_contact_id/1)

    (explicit_ids ++ row_ids)
    |> sorted_string_values()
    |> case do
      nil -> []
      ids -> ids
    end
  end

  def suppressed_reason_counts(report) do
    report
    |> suppressed_candidate_rows()
    |> count_rows("suppressed_reason")
    |> case do
      nil -> %{}
      counts -> counts
    end
  end

  def contact_ids_by_suppressed_reason(report) do
    report
    |> suppressed_reason_contact_pairs()
    |> case do
      [] ->
        report
        |> Map.get("contact_ids_by_suppressed_reason")
        |> map_value_lists()

      pairs ->
        grouped_ids(pairs)
    end
  end

  def direction_counts(report) do
    report
    |> direction_contact_pairs()
    |> case do
      [] ->
        report
        |> Map.get("direction_counts")
        |> normalize_direction_count_map()

      pairs ->
        grouped_id_counts(pairs)
    end
  end

  def contact_ids_by_direction(report) do
    report
    |> direction_contact_pairs()
    |> case do
      [] ->
        report
        |> Map.get("contact_ids_by_direction")
        |> map_value_lists()

      pairs ->
        grouped_ids(pairs)
    end
  end
end
