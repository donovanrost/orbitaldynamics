defmodule OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewEmbeddedRows do
  @moduledoc false

  import OrbitalDynamics.CandidateRefresh.SourceReportSummary.Common,
    only: [compact_map: 1]

  alias OrbitalDynamics.CandidateRefresh.OperationalFeedback
  alias OrbitalDynamics.CandidateRefresh.SourceReports.ManeuverReviewEmbeddedRowSources

  def row_from_review_or_import_row(%{} = row) do
    row
    |> Map.drop(["source_review_row"])
    |> Map.merge(ManeuverReviewEmbeddedRowSources.embedded_review(row))
    |> Map.put_new("maneuver_id", row["maneuver_id"] || row["subject_id"] || row["id"])
    |> Map.put_new("scenario_id", row["scenario_id"])
    |> Map.put_new("maneuver_type", row["maneuver_type"])
    |> Map.put_new("maneuver_success", row["maneuver_success"])
    |> Map.put_new("maneuver_result", row["maneuver_result"])
    |> Map.put_new("maneuver_success_factor", row["maneuver_success_factor"])
    |> Map.put_new("maneuver_success_factor_source", row["maneuver_success_factor_source"])
    |> Map.put_new("execution_uncertainty_status", row["execution_uncertainty_status"])
    |> Map.put_new("execution_uncertainty", row["execution_uncertainty"])
    |> Map.put_new("timing_3sigma_s", row["timing_3sigma_s"])
    |> Map.put_new("delta_v_3sigma_km_s", row["delta_v_3sigma_km_s"])
    |> Map.put_new("delta_v_3sigma_magnitude_km_s", row["delta_v_3sigma_magnitude_km_s"])
    |> Map.put_new("execution_uncertainty_source", row["execution_uncertainty_source"])
    |> compact_map()
    |> case do
      maneuver_review_row when is_map(maneuver_review_row) ->
        if OperationalFeedback.maneuver_review_feedback_key(maneuver_review_row) not in [nil, ""] do
          maneuver_review_row
        end

      _maneuver_review_row ->
        nil
    end
  end
end
