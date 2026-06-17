defmodule OrbitalDynamics.CampaignPlanner.TimelineDiffObservationPointingStatusClassification do
  @moduledoc false

  def failure?(status) when is_binary(status) do
    status in [
      "failed",
      "failure",
      "invalid",
      "lost",
      "lost_track",
      "no_solution",
      "off_target",
      "out_of_tolerance",
      "outside_tolerance",
      "target_mismatch",
      "unusable"
    ]
  end

  def failure?(_status), do: false

  def degraded?(status) when is_binary(status) do
    status in ["degraded", "marginal", "off_nominal", "partial"]
  end

  def degraded?(_status), do: false
end
