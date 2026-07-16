defmodule OrbitalDynamics.CandidateRefresh.SourceReportSummary.ContactContentionResolution.RecommendationFields.ContactFields.ContactMaps.MapFields do
  @moduledoc false

  alias __MODULE__.FieldSpecs

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [merge_string_list_maps: 1]

  def fields(reports) do
    Map.new(FieldSpecs.string_list_map_fields(), fn field ->
      {field, string_list_map_field(reports, field)}
    end)
  end

  defp string_list_map_field(reports, field) do
    reports
    |> Enum.map(&Map.get(&1, field, %{}))
    |> merge_string_list_maps()
  end
end
