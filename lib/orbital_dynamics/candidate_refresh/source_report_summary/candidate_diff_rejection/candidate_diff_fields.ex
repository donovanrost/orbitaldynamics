defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateDiffFields do
  @moduledoc false

  alias __MODULE__.CountFields
  alias __MODULE__.ReasonFields
  alias __MODULE__.RowIdentities
  alias __MODULE__.Rows

  def fields(reports) do
    CountFields.fields(reports)
    |> Map.merge(reason_fields(reports))
    |> Map.merge(identity_fields(reports))
  end

  def row_trust_boundaries(reports) do
    Rows.trust_boundaries(reports)
  end

  defp reason_fields(reports) do
    ReasonFields.merge(reports, &Rows.from_report/1)
  end

  defp identity_fields(reports) do
    reports
    |> Rows.from_reports()
    |> RowIdentities.fields()
  end
end
