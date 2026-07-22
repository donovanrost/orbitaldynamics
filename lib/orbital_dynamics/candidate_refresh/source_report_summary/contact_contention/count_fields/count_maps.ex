defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.CountMaps do
  @moduledoc false

  alias __MODULE__.RequiredOperatorActions
  alias __MODULE__.ResourceScopes

  alias OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContention.CountFields.ConflictGroups

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
    |> Enum.map(&ConflictGroups.ground_station_counts/1)
    |> merge_count_maps()
  end

  defp contact_id_counts(reports) do
    reports
    |> Enum.map(&ConflictGroups.contact_id_counts/1)
    |> merge_count_maps()
  end
end
