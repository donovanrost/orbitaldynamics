defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.AllocationReportSummary.ReportCountMaps.FieldSpecs do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.Allocation.Report,
    as: AllocationReport

  @count_map_fields [
    {"allocation_status_counts", &AllocationReport.status_counts/1},
    {"effective_allocation_status_counts", &AllocationReport.effective_status_counts/1},
    {"allocation_reason_counts", &AllocationReport.reason_counts/1},
    {"direction_counts", &AllocationReport.direction_counts/1},
    {
      "resource_blocking_dimension_counts",
      &AllocationReport.resource_blocking_dimension_counts/1
    }
  ]

  def count_map_fields, do: @count_map_fields
end
