defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.Evidence.Values.FieldSets.MapFields do
  @moduledoc false

  @fields [
    "freshness_status_counts",
    "schema_validation_status_counts",
    "import_status_counts",
    "cadence_import_status_counts",
    "adapter_boundary_status_counts",
    "resource_availability_reason_counts",
    "resource_blocking_dimension_counts",
    "review_type_counts",
    "import_action_counts",
    "source_review_type_counts"
  ]

  def fields, do: @fields
end
