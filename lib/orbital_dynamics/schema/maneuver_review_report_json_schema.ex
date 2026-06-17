defmodule OrbitalDynamics.Schema.ManeuverReviewReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "maneuver_count",
    "review_required_count",
    "invalid_maneuver_recommendation_count",
    "execution_uncertainty_declared_count",
    "execution_uncertainty_missing_count"
  ]

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_maneuver_review_report"}
  end

  def property("rows", opts) do
    %{
      "type" => "array",
      "items" => Keyword.fetch!(opts, :row_schema)
    }
  end

  def property("invalid_maneuver_recommendation_ids", opts) do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def row(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)
    numeric_triplet_schema = Keyword.fetch!(opts, :numeric_triplet_schema)
    policy_decision_schema = Keyword.fetch!(opts, :policy_decision_schema)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "required" => [
        "id",
        "rank",
        "maneuver_id",
        "scenario_id",
        "maneuver_type",
        "epoch_s",
        "frame",
        "delta_v_km_s",
        "maneuver_model",
        "approval_status",
        "required_operator_action",
        "reason",
        "execution_boundary",
        "source_recommendation"
      ],
      "properties" => %{
        "id" => stable_id(stable_id_pattern),
        "rank" => %{"type" => "integer"},
        "maneuver_id" => stable_id(stable_id_pattern),
        "scenario_id" => stable_id(stable_id_pattern),
        "maneuver_type" => %{"type" => "string"},
        "epoch_s" => %{"type" => "number"},
        "epoch_scale" => %{"type" => "string"},
        "frame" => %{"type" => "string"},
        "delta_v_km_s" => numeric_triplet_schema,
        "delta_v_magnitude_km_s" => %{"type" => "number"},
        "maneuver_model" => %{"type" => "string"},
        "approval_status" => %{"type" => "string"},
        "execution_uncertainty_status" => %{"type" => "string"},
        "required_operator_action" => %{"type" => "string"},
        "reason" => %{"type" => "string"},
        "execution_boundary" => %{"type" => "string"},
        "source_recommendation" => %{"type" => "object"},
        "policy_decision" => policy_decision_schema
      }
    }
  end

  defp stable_id(stable_id_pattern) do
    %{"type" => "string", "pattern" => stable_id_pattern}
  end
end
