defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.SourceFields do
  @moduledoc false

  alias __MODULE__.BaseFields
  alias __MODULE__.InvalidContactInputs
  alias __MODULE__.SuppressedReasons

  def fields(sources, reports) do
    sources
    |> BaseFields.fields(reports)
    |> Map.merge(InvalidContactInputs.fields(reports))
    |> Map.merge(SuppressedReasons.fields(reports))
  end
end
