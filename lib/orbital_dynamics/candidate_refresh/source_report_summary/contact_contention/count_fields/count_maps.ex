defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.CountMaps do
  @moduledoc false

  alias __MODULE__.GroundStations
  alias __MODULE__.RequiredOperatorActions
  alias __MODULE__.ResourceScopes

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.ConflictGroups

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.ConflictGroupDirections

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.DirectionRouting.Correlation

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_count_maps: 1
    ]

  def fields(reports) do
    %{
      "resource_scope_counts" => resource_scope_counts(reports),
      "contact_contention_ground_station_counts" => ground_station_counts(reports),
      "contact_contention_contact_id_counts" => contact_id_counts(reports),
      "required_operator_action_counts" => RequiredOperatorActions.counts(reports)
    }
  end

  defp resource_scope_counts(reports) do
    reports
    |> Enum.map(fn report ->
      ResourceScopes.correlated_counts(
        ConflictGroups.count(report),
        ConflictGroups.resource_scope_counts(report)
      )
    end)
    |> merge_count_maps()
  end

  defp ground_station_counts(reports) do
    reports
    |> Enum.map(fn report ->
      resource_scope_counts =
        ResourceScopes.correlated_counts(
          ConflictGroups.count(report),
          ConflictGroups.resource_scope_counts(report)
        )

      GroundStations.correlated_counts(
        resource_scope_counts,
        ConflictGroups.ground_station_counts(report)
      )
    end)
    |> merge_count_maps()
  end

  defp contact_id_counts(reports) do
    reports
    |> Enum.map(fn report ->
      direction_counts = ConflictGroupDirections.direction_counts(report)
      contact_ids_by_direction = ConflictGroupDirections.contact_ids_by_direction(report)

      Correlation.contact_id_counts(
        direction_counts,
        contact_ids_by_direction,
        ConflictGroups.contact_id_counts(report)
      )
    end)
    |> merge_count_maps()
  end
end
