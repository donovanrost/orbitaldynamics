defmodule OrbitalDynamics.Schema.CandidateRejectionReportJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @count_fields [
    "candidate_count",
    "row_count",
    "rejected_count",
    "not_rejected_count",
    "reviewable_count",
    "invalid_candidate_input_count"
  ]

  @stable_id_array_fields [
    "rejected_candidate_ids",
    "not_rejected_candidate_ids",
    "reviewable_candidate_ids",
    "invalid_candidate_input_ids"
  ]

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{"type" => "string", "enum" => model_limits}
    }
  end

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property("model", _opts) do
    %{"type" => "string", "const" => "artifact_only_candidate_rejection_explanation"}
  end

  def property("source", _opts) do
    %{"type" => "string"}
  end

  def property(field, _opts) when field in @count_fields do
    %{"type" => "integer", "minimum" => 0}
  end

  def property("rejection_reason_counts", opts) do
    opts
    |> Keyword.fetch!(:rejection_reasons)
    |> CommonJsonSchema.enum_count_map()
  end

  def property("candidate_id_sets_by_rejection_reason", opts) do
    enum_stable_id_array_map(
      Keyword.fetch!(opts, :rejection_reasons),
      Keyword.fetch!(opts, :stable_id_pattern)
    )
  end

  def property("candidate_ids_by_required_operator_action", opts) do
    enum_stable_id_array_map(
      Keyword.fetch!(opts, :required_operator_actions),
      Keyword.fetch!(opts, :stable_id_pattern)
    )
  end

  def property(field, opts) when field in @stable_id_array_fields do
    opts
    |> Keyword.fetch!(:stable_id_pattern)
    |> CommonJsonSchema.stable_id_array()
  end

  def property("required_operator_action_counts", opts) do
    opts
    |> Keyword.fetch!(:required_operator_actions)
    |> CommonJsonSchema.enum_count_map()
  end

  defp enum_stable_id_array_map(values, stable_id_pattern) do
    %{
      "type" => "object",
      "propertyNames" => %{"enum" => values},
      "additionalProperties" => CommonJsonSchema.stable_id_array(stable_id_pattern)
    }
  end
end
