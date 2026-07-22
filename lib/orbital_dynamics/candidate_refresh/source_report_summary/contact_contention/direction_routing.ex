defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting do
  @moduledoc false

  alias __MODULE__.{ConflictGroupDirections, Correlation, RouteMap}

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.ConflictGroups

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1,
      merge_string_list_maps: 1
    ]

  def fields(reports) do
    report_fields = Enum.map(reports, &report_fields/1)

    direction_counts =
      report_fields
      |> Enum.map(&elem(&1, 0))
      |> merge_count_maps()

    contact_ids_by_direction =
      report_fields
      |> Enum.map(&elem(&1, 1))
      |> merge_string_list_maps()

    %{
      "direction_counts" => direction_counts,
      "contact_ids_by_direction" => contact_ids_by_direction,
      "direction_routing" =>
        RouteMap.field(Correlation.positive_counts(direction_counts), contact_ids_by_direction)
    }
  end

  defp report_fields(report) do
    direction_counts = ConflictGroupDirections.direction_counts(report)

    raw_contact_id_counts =
      ConflictGroups.contact_id_counts(report) ||
        Map.get(report, "contact_contention_contact_id_counts")

    raw_contact_ids_by_direction = ConflictGroupDirections.contact_ids_by_direction(report)

    contact_id_counts =
      Correlation.contact_id_counts(
        direction_counts,
        raw_contact_ids_by_direction,
        raw_contact_id_counts
      )

    contact_ids_by_direction =
      Correlation.contact_ids_by_direction(
        direction_counts,
        raw_contact_ids_by_direction,
        contact_id_counts
      )

    {direction_counts, contact_ids_by_direction}
  end
end
