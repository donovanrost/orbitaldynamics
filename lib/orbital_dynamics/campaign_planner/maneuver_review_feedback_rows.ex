defmodule OrbitalDynamics.CampaignPlanner.ManeuverReviewFeedbackRows do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    FeedbackNumericValues,
    RealizedActivitySuccessValues,
    RealizedFeedbackContext
  }

  def normalize(row) do
    row =
      if Map.has_key?(row, "activity_id") or row["maneuver_id"] in [nil, ""] do
        row
      else
        Map.put(row, "activity_id", row["maneuver_id"])
      end

    if Map.has_key?(row, "type") or row["maneuver_type"] in [nil, ""] do
      row
    else
      Map.put(row, "type", row["maneuver_type"])
    end
  end

  def feedback_row?(row), do: feedback_row?(row, callbacks())

  def feedback_row?(row, opts) when is_list(opts) do
    maneuver_activity? = Keyword.fetch!(opts, :maneuver_activity?)
    realized_feedback_activity_id = Keyword.fetch!(opts, :realized_feedback_activity_id)

    maneuver_activity?.(row) and realized_feedback_activity_id.(row) not in [nil, ""] and
      not is_nil(success_value(row, opts))
  end

  def success_value(row), do: success_value(row, callbacks())

  def success_value(row, opts) when is_list(opts) do
    unit_interval_number_or_nil = Keyword.fetch!(opts, :unit_interval_number_or_nil)
    maneuver_success_value = Keyword.fetch!(opts, :maneuver_success_value)

    case unit_interval_number_or_nil.(row["maneuver_success_factor"]) do
      value when is_number(value) -> value
      _value -> maneuver_success_value.(row)
    end
  end

  defp callbacks,
    do: [
      maneuver_activity?: &maneuver_activity?/1,
      realized_feedback_activity_id: &RealizedFeedbackContext.activity_id/1,
      unit_interval_number_or_nil: &FeedbackNumericValues.unit_interval_number_or_nil/1,
      maneuver_success_value: &RealizedActivitySuccessValues.maneuver/1
    ]

  defp maneuver_activity?(activity), do: activity["type"] in ["maneuver", "impulsive_burn"]
end
