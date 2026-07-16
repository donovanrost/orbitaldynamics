defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ResourceCollectionResultArtifactFields do
  @moduledoc false

  @resource_projection_fields [
    "source_resource_projection_report",
    "resource_projection_report",
    "source_resource_projection_flow_summary",
    "resource_projection_flow_summary"
  ]

  @resource_filter_fields [
    "source_resource_filter_summary",
    "resource_filter_summary",
    "source_resource_filter_report",
    "resource_filter_report"
  ]

  def resource_projection_fields, do: @resource_projection_fields
  def resource_filter_fields, do: @resource_filter_fields
end
