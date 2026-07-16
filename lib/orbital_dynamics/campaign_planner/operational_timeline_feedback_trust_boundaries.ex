defmodule OrbitalDynamics.CampaignPlanner.OperationalTimelineFeedbackTrustBoundaries do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    ContactThroughputFields,
    RealizedFeedbackContext,
    RealizedFeedbackRows,
    RealizedFeedbackTrustBoundaries
  }

  def feedback_boundaries(rows) do
    rows
    |> Enum.reduce(%{}, fn row, boundaries ->
      trust_boundary = trust_boundary(row)

      if trust_boundary in [nil, ""] do
        boundaries
      else
        boundaries
        |> RealizedFeedbackTrustBoundaries.put_timeline_boundary(
          "command_success_rate",
          RealizedFeedbackContext.activity_id(row),
          trust_boundary,
          RealizedFeedbackRows.operator_review_command?(row)
        )
        |> RealizedFeedbackTrustBoundaries.put_timeline_boundary(
          "maneuver_success_rate",
          RealizedFeedbackContext.activity_id(row),
          trust_boundary,
          RealizedFeedbackRows.operator_review_maneuver?(row)
        )
        |> RealizedFeedbackTrustBoundaries.put_timeline_boundary(
          "contact_success_rate",
          station_id(row),
          trust_boundary,
          RealizedFeedbackRows.operator_review_contact?(row)
        )
        |> RealizedFeedbackTrustBoundaries.put_timeline_boundary(
          "station_throughput_factor",
          station_id(row),
          trust_boundary,
          RealizedFeedbackRows.operator_review_contact?(row) and
            not is_nil(ContactThroughputFields.station_throughput_value(row))
        )
        |> RealizedFeedbackTrustBoundaries.put_timeline_boundary(
          "observation_success_rate",
          Map.get(row, "target_id"),
          trust_boundary,
          RealizedFeedbackRows.operator_review_observation?(row)
        )
      end
    end)
    |> case do
      boundaries when boundaries == %{} -> nil
      boundaries -> boundaries
    end
  end

  defp station_id(row), do: Map.get(row, "ground_station_id") || Map.get(row, "station_id")

  defp trust_boundary(row) do
    Map.get(row, "trust_boundary") ||
      get_in(row, ["provenance", "trust_boundary"]) ||
      row["_source_report_trust_boundary"]
  end
end
