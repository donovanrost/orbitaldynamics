defmodule OrbitalDynamics.Schema.ExecutionReviewSchemaProviders do
  @moduledoc false

  def build(stable_id_pattern, opts) when is_binary(stable_id_pattern) and is_list(opts) do
    dependencies = Map.new(opts)

    %{
      {:command_window_row_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.CommandWindowReportJsonSchema.row(
          stable_id_pattern: stable_id_pattern,
          activity_context_schema: call(dependencies, :activity_context_schema),
          policy_decision_schema: call(dependencies, :policy_decision_schema)
        )
      end,
      {:maneuver_review_row_json_schema, 0} => fn ->
        OrbitalDynamics.Schema.ManeuverReviewReportJsonSchema.row(
          stable_id_pattern: stable_id_pattern,
          numeric_triplet_schema: OrbitalDynamics.Schema.CommonJsonSchema.numeric_triplet(),
          policy_decision_schema: call(dependencies, :policy_decision_schema)
        )
      end
    }
  end

  defp call(dependencies, name), do: dependencies |> Map.fetch!(name) |> apply([])
end
