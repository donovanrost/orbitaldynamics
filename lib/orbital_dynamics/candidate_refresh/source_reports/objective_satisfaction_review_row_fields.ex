defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfactionReviewRowFields do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.SourceReports.ObjectiveSatisfactionValueEncoding

  def row_from_review_or_import_row(%{} = row) do
    embedded =
      cond do
        is_map(row["source_objective_satisfaction"]) ->
          row["source_objective_satisfaction"]

        is_map(get_in(row, ["source_review_row", "source_objective_satisfaction"])) ->
          get_in(row, ["source_review_row", "source_objective_satisfaction"])

        true ->
          %{}
      end

    embedded =
      case embedded do
        %{} = objective -> ObjectiveSatisfactionValueEncoding.stringify_keys(objective)
        _objective -> %{}
      end

    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(embedded)
    |> Map.put_new("id", row["objective_id"] || row["subject_id"] || row["id"])
    |> Map.put_new("objective", row["objective"] || row["objective_type"])
    |> Map.put_new("status", row["objective_status"])
    |> Map.put_new("target_id", row["target_id"])
    |> Map.put_new("ground_station_id", row["ground_station_id"])
    |> compact_map()
    |> case do
      objective_row when is_map(objective_row) ->
        if Map.get(objective_row, "objective") not in [nil, ""], do: objective_row

      _objective_row ->
        nil
    end
  end

  def row_from_review_or_import_row(_row), do: nil
end
