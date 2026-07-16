defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactAllocationDirectReportSources do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ContactReviewCollectionContactAllocationReportFields

  def sources(refresh) do
    scoped_sources(refresh, "accepted_planning_state") ++
      scoped_sources(refresh, "mission_state") ++ root_sources(refresh)
  end

  defp scoped_sources(refresh, scope) do
    Enum.map(ContactReviewCollectionContactAllocationReportFields.fields(), fn field ->
      {"#{scope}.#{field}", get_in(refresh, [scope, field])}
    end)
  end

  defp root_sources(refresh) do
    Enum.map(ContactReviewCollectionContactAllocationReportFields.fields(), fn field ->
      {field, Map.get(refresh, field)}
    end)
  end
end
