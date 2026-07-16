defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactFilter.StationSuppressionFields.IdMaps do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def fields(reports) do
    Map.new(FieldSpecs.values(), fn {field, field_fun} ->
      value =
        reports
        |> Enum.map(field_fun)
        |> merge_string_list_maps()

      {field, value}
    end)
  end
end
