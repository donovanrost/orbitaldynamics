defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.PreservedSummary.CapacityPackFields do
  @moduledoc false

  alias __MODULE__.ContactIds
  alias __MODULE__.ReducedCapacity
  alias __MODULE__.RequiredCapacity
  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common.NumericValue

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      numeric_report_count: 2
    ]

  def fields(summary) do
    %{
      "capacity_pack_status_counts" => Map.get(summary, "capacity_pack_status_counts"),
      "capacity_pack_contact_count" =>
        numeric_report_count(summary, "capacity_pack_contact_count"),
      "capacity_pack_required_capacity_fraction" =>
        NumericValue.value(Map.get(summary, "capacity_pack_required_capacity_fraction"))
    }
    |> Map.merge(ContactIds.fields(summary))
    |> Map.merge(RequiredCapacity.fields(summary))
    |> Map.merge(ReducedCapacity.fields(summary))
  end
end
