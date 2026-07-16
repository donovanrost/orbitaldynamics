defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionDirectReports do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionResourceFilterDirectReports

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionResourceProjectionDirectReports

  def resource_projection_reports(refresh) do
    ResourceCollectionResourceProjectionDirectReports.reports(refresh)
  end

  def resource_filter_reports(refresh) do
    ResourceCollectionResourceFilterDirectReports.reports(refresh)
  end
end
