defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.IdFields.IdValues do
  @moduledoc false

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.OperationalReadiness.GateStatus.GateIds

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_list_maps: 1,
      sorted_string_values: 1
    ]

  def ids_by_status(reports) do
    reports
    |> Enum.map(&GateIds.non_passed_ids_by_status/1)
    |> merge_string_list_maps()
  end

  def ids_by_classification(reports) do
    reports
    |> Enum.map(&GateIds.non_passed_ids_by_classification/1)
    |> merge_string_list_maps()
  end

  def passed_ids(reports) do
    reports
    |> Enum.flat_map(&GateIds.passed_ids/1)
    |> sorted_string_values()
  end

  def ids_for_status(reports, status, fallback_field) do
    GateIds.ids_for_status(reports, status, fallback_field)
  end

  def non_passed_ids(reports) do
    reports
    |> Enum.flat_map(&GateIds.non_passed_ids/1)
    |> sorted_string_values()
  end
end
