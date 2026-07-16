defmodule OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReviewRowReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.SchemaValidationReviewReportFields

  def from_rows(rows) do
    SchemaValidationReviewReportFields.from_rows(rows)
  end

  def embedded_report(%{} = row) do
    cond do
      is_map(get_in(row, ["source_review_row", "source_schema_validation_report"])) ->
        get_in(row, ["source_review_row", "source_schema_validation_report"])

      is_map(row["source_schema_validation_report"]) ->
        row["source_schema_validation_report"]

      true ->
        nil
    end
  end
end
