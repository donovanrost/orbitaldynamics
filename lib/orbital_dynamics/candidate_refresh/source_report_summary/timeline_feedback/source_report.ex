defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.TimelineFeedback.SourceReport do
  @moduledoc false

  alias __MODULE__.Metadata
  alias __MODULE__.RowSource

  def source(
        %{
          "operational_feedback_provenance" => %{"sources" => sources}
        } = report
      )
      when is_list(sources) do
    trust_boundaries = Metadata.trust_boundaries(report)

    sources
    |> Metadata.existing_rows_source()
    |> Map.put("trust_boundary_status", Metadata.status_from_boundaries(trust_boundaries))
    |> Metadata.maybe_put("trust_boundaries", trust_boundaries)
  end

  def source(%{} = report) do
    RowSource.source(report)
  end
end
