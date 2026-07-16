defmodule OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactRows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.TimelineDependencyImpactRowValues,
    as: RowValues

  def row_from_review_or_import_row(%{} = row) do
    embedded =
      cond do
        is_map(row["source_timeline_dependency_impact"]) ->
          row["source_timeline_dependency_impact"]

        is_map(get_in(row, ["source_review_row", "source_timeline_dependency_impact"])) ->
          get_in(row, ["source_review_row", "source_timeline_dependency_impact"])

        true ->
          %{}
      end
      |> stringify_keys()

    row
    |> Map.drop(["source_review_row", "source_timeline_dependency_impact"])
    |> Map.merge(embedded)
    |> Map.put_new("scope", row["dependency_impact_scope"])
    |> Map.put_new("dependency_impact_status", row["dependency_impact_status"])
    |> Map.put_new("required_operator_action", row["required_operator_action"])
    |> Map.put_new("activity_id", row["activity_id"])
    |> Map.put_new("timeline_id", row["timeline_id"])
    |> Map.put_new("activity_type", row["activity_type"])
    |> compact_map()
    |> case do
      impact_row when is_map(impact_row) ->
        if row_scope(impact_row) in ["source", "replacement"] or
             impact_row["dependency_impact_status"] not in [nil, ""] do
          impact_row
        end

      _impact_row ->
        nil
    end
  end

  def row_from_review_or_import_row(_row), do: nil

  def summary_values(source, field), do: RowValues.summary_values(source, field)
  def row_scope(row), do: RowValues.row_scope(row)
  def stringify_keys(value), do: RowValues.stringify_keys(value)
end
