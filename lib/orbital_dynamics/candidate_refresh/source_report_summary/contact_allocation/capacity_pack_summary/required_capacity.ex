defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactAllocation.CapacityPackSummary.RequiredCapacity do
  @moduledoc false

  alias __MODULE__.AggregateValues
  alias __MODULE__.FractionFields

  alias OrbitalDynamics.CandidateRefresh.ReplaySummary.ContactAllocation.SourceReportFields.CapacityPack.Report,
    as: CapacityPackReport

  def fields(reports) do
    %{
      "required_capacity_fraction_source_counts" =>
        AggregateValues.count_map_merge(
          reports,
          &CapacityPackReport.required_capacity_source_counts/1
        ),
      "required_capacity_fraction_contact_ids_by_source" =>
        AggregateValues.string_list_map_merge(
          reports,
          &CapacityPackReport.required_capacity_contact_ids_by_source/1
        )
    }
    |> Map.merge(FractionFields.fields(reports))
  end
end
