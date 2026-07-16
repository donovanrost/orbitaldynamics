defmodule OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.RowValues.ContactSources.Pairs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.RowValues.ContactSources

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.RowValues.ContactSources.StationEntries

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.RowValues.Normalization

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactFilter.SourceReportFields.Report.Rows.RowValues

  def suppressed_reason_contact_pairs(report) do
    report
    |> RowValues.suppressed_candidate_rows()
    |> Enum.flat_map(&row_suppressed_reason_contact_pairs/1)
  end

  def direction_contact_pairs(report) do
    report
    |> RowValues.suppressed_candidate_rows()
    |> Enum.flat_map(&row_direction_contact_pairs/1)
  end

  defp row_suppressed_reason_contact_pairs(row) do
    row_reason = normalized_token(row["suppressed_reason"])
    row_contact_id = row_contact_id(row)

    row
    |> StationEntries.source_contact_values()
    |> Kernel.++([row])
    |> Enum.map(fn contact ->
      {normalized_token(contact["suppressed_reason"]) || row_reason,
       row_contact_id(contact) || row_contact_id}
    end)
    |> Enum.reject(fn {reason, contact_id} ->
      reason in [nil, ""] or contact_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  defp row_direction_contact_pairs(row) do
    row_direction = row_summary_direction(row)
    row_contact_id = row_contact_id(row)

    row
    |> StationEntries.source_contact_values()
    |> Kernel.++([row])
    |> Enum.map(fn contact ->
      {row_summary_direction(contact) || row_direction, row_contact_id(contact) || row_contact_id}
    end)
    |> Enum.reject(fn {direction, contact_id} ->
      direction in [nil, ""] or contact_id in [nil, ""]
    end)
    |> Enum.uniq()
  end

  defp row_summary_direction(row) do
    [
      row["direction"],
      row["type"],
      get_in(row, ["activity_context", "direction"]),
      get_in(row, ["source_activity_context", "direction"]),
      get_in(row, ["source_contact_candidate", "direction"]),
      get_in(row, ["source_contact_candidate", "activity_context", "direction"]),
      get_in(row, ["contact_candidate", "direction"]),
      get_in(row, ["contact_candidate", "activity_context", "direction"])
    ]
    |> Enum.map(&normalize_direction/1)
    |> Enum.find(&(&1 not in [nil, ""]))
  end

  defp row_contact_id(row), do: ContactSources.row_contact_id(row)
  defp normalize_direction(direction), do: Normalization.normalize_direction(direction)
  defp normalized_token(value), do: Normalization.normalized_token(value)
end
