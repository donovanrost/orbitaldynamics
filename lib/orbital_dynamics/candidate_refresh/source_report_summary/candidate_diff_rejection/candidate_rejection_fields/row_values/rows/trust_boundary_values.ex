defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.CandidateDiffRejection.CandidateRejectionFields.RowValues.Rows.TrustBoundaryValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.EncodedValue

  def from_row(row) do
    row = EncodedValue.stringify_keys(row)

    [
      row["trust_boundary"],
      row["source_trust_boundary"],
      get_in(row, ["provenance", "trust_boundary"]),
      get_in(row, ["activity_context", "provenance", "trust_boundary"])
    ]
  end
end
