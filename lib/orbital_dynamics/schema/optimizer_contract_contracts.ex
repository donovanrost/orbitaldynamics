defmodule OrbitalDynamics.Schema.OptimizerContractContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CollectionValidation, only: [expect_list_count_equals: 5]

  import OrbitalDynamics.Schema.PrimitiveValidation,
    only: [
      error: 2,
      expect_equal: 5,
      expect_non_negative_integer: 4,
      expect_optional_type: 5,
      expect_type: 5
    ]

  import OrbitalDynamics.Schema.StableIdValidation,
    only: [validate_stable_id_list: 4, validate_stable_ids: 4]

  def validate(issues, path, contract) do
    issues
    |> validate_stable_ids(path, contract, ["id"])
    |> expect_equal(path, contract, "schema_contract", "optimizer_contract.v1")
    |> expect_type(path, contract, "optimizer", :binary)
    |> expect_type(path, contract, "objective", :binary)
    |> expect_type(path, contract, "selection_policy", :binary)
    |> expect_non_negative_integer(path, contract, "candidate_count")
    |> expect_non_negative_integer(path, contract, "ranked_timeline_count")
    |> expect_non_negative_integer(path, contract, "selected_activity_count")
    |> expect_type(path, contract, "selected_activity_ids", :list)
    |> expect_optional_type(path, contract, "candidate_activity_ids", :list)
    |> expect_optional_type(path, contract, "ranked_scenario_ids", :list)
    |> expect_optional_type(path, contract, "score_term_keys", :list)
    |> expect_optional_type(path, contract, "deterministic_ordering", :list)
    |> expect_optional_type(path, contract, "preserved_lineage_fields", :list)
    |> expect_optional_type(path, contract, "constraints", :map)
    |> expect_optional_type(path, contract, "scoring_policy", :map)
    |> expect_optional_type(path, contract, "known_limits", :list)
    |> expect_type(path, contract, "assumptions", :map)
    |> validate_counts(path, contract)
    |> validate_stable_id_list(path, contract, "selected_activity_ids")
    |> validate_stable_id_list(path, contract, "candidate_activity_ids")
    |> validate_stable_id_list(path, contract, "ranked_scenario_ids")
  end

  defp validate_counts(issues, path, contract) do
    issues
    |> expect_list_count_equals(path, contract, "candidate_count", "candidate_activity_ids")
    |> expect_list_count_equals(
      path,
      contract,
      "selected_activity_count",
      "selected_activity_ids"
    )
    |> expect_list_count_equals(
      path,
      contract,
      "ranked_timeline_count",
      "ranked_scenario_ids"
    )
    |> validate_selected_ids(path, contract)
  end

  defp validate_selected_ids(
         issues,
         path,
         %{"selected_activity_ids" => selected_ids, "candidate_activity_ids" => candidate_ids}
       )
       when is_list(selected_ids) and is_list(candidate_ids) do
    selected_ids
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {id, index}, acc ->
      if id in candidate_ids do
        acc
      else
        [
          error(
            "#{path}.selected_activity_ids[#{index}]",
            "must reference candidate_activity_ids"
          )
          | acc
        ]
      end
    end)
  end

  defp validate_selected_ids(issues, _path, _contract), do: issues
end
