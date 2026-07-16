defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.StationCalendar.PrecedenceFields do
  @moduledoc false

  alias __MODULE__.ReservedUnderHigherPrecedence

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      count_report_field_values: 2,
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def fields(reports) do
    %{
      "precedence_review_status_counts" =>
        reports
        |> count_report_field_values("precedence_review_status"),
      "applied_availability_counts" =>
        reports
        |> Enum.map(&Map.get(&1, "applied_availability_counts", %{}))
        |> merge_count_maps(),
      "overlap_availability_counts" =>
        reports
        |> Enum.map(&Map.get(&1, "overlap_availability_counts", %{}))
        |> merge_count_maps(),
      "affected_contact_ids_by_applied_availability" =>
        reports
        |> Enum.map(&Map.get(&1, "affected_contact_ids_by_applied_availability", %{}))
        |> merge_string_list_maps(),
      "affected_contact_ids_by_overlap_availability" =>
        reports
        |> Enum.map(&Map.get(&1, "affected_contact_ids_by_overlap_availability", %{}))
        |> merge_string_list_maps()
    }
    |> Map.merge(ReservedUnderHigherPrecedence.fields(reports))
  end
end
