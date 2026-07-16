defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.QualityGate.ResourceAvailability do
  @moduledoc false

  alias __MODULE__.Reasons

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [
      merge_string_list_maps: 1
    ]

  def fields(reports) do
    reports
    |> Reasons.fields()
    |> Map.merge(blocked_contact_id_fields(reports))
  end

  defp blocked_contact_id_fields(reports) do
    %{
      "blocked_contact_ids_by_blocking_dimension" =>
        reports
        |> Enum.map(&resource_string_list_map(&1, "blocked_contact_ids_by_blocking_dimension"))
        |> merge_string_list_maps(),
      "blocked_contact_ids_by_spacecraft_id" =>
        reports
        |> Enum.map(&resource_string_list_map(&1, "blocked_contact_ids_by_spacecraft_id"))
        |> merge_string_list_maps(),
      "blocked_contact_ids_by_status" =>
        reports
        |> Enum.map(&resource_string_list_map(&1, "blocked_contact_ids_by_status"))
        |> merge_string_list_maps()
    }
  end

  defp resource_string_list_map(report, field) do
    case Map.get(report, field) do
      %{} = list_map -> list_map
      _value -> %{}
    end
  end
end
