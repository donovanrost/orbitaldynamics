defmodule OrbitalDynamics.Schema.FeedbackManeuverHandoffJsonSchema do
  @moduledoc false

  def properties(opts) do
    probability_schema = Keyword.fetch!(opts, :probability_schema)

    %{
      "feedback_weight" => %{"type" => "number", "minimum" => 0.0},
      "feedback_weight_source" => %{"type" => "string"},
      "maneuver_success" => %{"type" => "boolean"},
      "maneuver_result" => %{"type" => "string"},
      "maneuver_success_factor" => probability_schema,
      "maneuver_success_factor_source" => %{"type" => "string"}
    }
  end
end
