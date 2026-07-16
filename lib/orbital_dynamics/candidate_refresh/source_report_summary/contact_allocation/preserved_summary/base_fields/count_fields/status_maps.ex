defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.BaseFields.CountFields.StatusMaps do
  @moduledoc false

  def fields(summary) do
    %{
      "allocation_status_counts" => Map.get(summary, "allocation_status_counts"),
      "effective_allocation_status_counts" =>
        Map.get(summary, "effective_allocation_status_counts"),
      "allocation_reason_counts" => Map.get(summary, "allocation_reason_counts")
    }
  end
end
