defmodule OrbitalDynamics.Schema.ManeuverReviewCapabilityContext do
  @moduledoc false

  def maneuver_recommendation_model_limits do
    OrbitalDynamics.ManeuverReview.recommendation_model_limits()
  end

  def maneuver_review_report_model_limits do
    OrbitalDynamics.ManeuverReview.capabilities()
    |> Map.fetch!(:known_limits)
    |> Enum.map(&Atom.to_string/1)
  end
end
