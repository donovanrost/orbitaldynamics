defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ValidationSafetyCase.SummaryFields.CountFields.StatusCounts do
  @moduledoc false

  alias __MODULE__.CountValues

  def fields(reports) do
    %{
      "accepted_evidence_count" =>
        CountValues.sum(
          reports,
          "accepted_for_use",
          "accepted_evidence_count"
        ),
      "review_required_evidence_count" =>
        CountValues.sum(
          reports,
          "review_required",
          "review_required_evidence_count"
        ),
      "blocked_evidence_count" => CountValues.sum(reports, "blocked", "blocked_evidence_count")
    }
  end
end
