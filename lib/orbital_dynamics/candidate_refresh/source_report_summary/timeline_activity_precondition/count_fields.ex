defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineActivityPrecondition.CountFields do
  @moduledoc false

  alias __MODULE__.IdentityFields
  alias __MODULE__.InputIssueFields

  def fields(summaries) do
    InputIssueFields.fields(summaries)
    |> Map.merge(IdentityFields.fields(summaries))
  end
end
