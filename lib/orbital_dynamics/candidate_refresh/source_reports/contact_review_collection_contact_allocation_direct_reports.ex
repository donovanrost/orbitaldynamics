defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactAllocationDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactAllocation

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactAllocationDirectReportSources

  def contact_allocation_reports(refresh) do
    refresh
    |> ContactReviewCollectionContactAllocationDirectReportSources.sources()
    |> Enum.flat_map(fn {path, report_or_reports} ->
      ContactAllocation.entries(path, report_or_reports)
    end)
  end
end
