defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateDiffFields.ReasonFields.ReasonCounts do
  @moduledoc false

  alias __MODULE__.RowCounts

  def fields(rows) do
    %{
      "diff_reason_counts" => RowCounts.scalar(rows, "diff_reason"),
      "invalidated_reason_counts" => RowCounts.scalar(rows, "invalidated_reason"),
      "semantic_change_reason_counts" => RowCounts.list(rows, "semantic_change_reasons"),
      "candidate_diff_changed_field_counts" =>
        RowCounts.list(rows, "candidate_diff_changed_fields")
    }
  end

  def merge(reports, rows_fun) do
    %{
      "diff_reason_counts" =>
        RowCounts.merge(reports, rows_fun, &RowCounts.scalar(&1, "diff_reason")),
      "invalidated_reason_counts" =>
        RowCounts.merge(reports, rows_fun, &RowCounts.scalar(&1, "invalidated_reason")),
      "semantic_change_reason_counts" =>
        RowCounts.merge(reports, rows_fun, &RowCounts.list(&1, "semantic_change_reasons")),
      "candidate_diff_changed_field_counts" =>
        RowCounts.merge(reports, rows_fun, &RowCounts.list(&1, "candidate_diff_changed_fields"))
    }
  end
end
