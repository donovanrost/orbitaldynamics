defmodule OrbitalDynamics.Schema.OptimizerContractContracts do
  @moduledoc false

  def validate(issues, path, contract, callbacks) when is_list(callbacks) do
    issues
    |> validate_stable_ids(callbacks, path, contract, ["id"])
    |> expect_equal(callbacks, path, contract, "schema_contract", "optimizer_contract.v1")
    |> expect_type(callbacks, path, contract, "optimizer", :binary)
    |> expect_type(callbacks, path, contract, "objective", :binary)
    |> expect_type(callbacks, path, contract, "selection_policy", :binary)
    |> expect_non_negative_integer(callbacks, path, contract, "candidate_count")
    |> expect_non_negative_integer(callbacks, path, contract, "ranked_timeline_count")
    |> expect_non_negative_integer(callbacks, path, contract, "selected_activity_count")
    |> expect_type(callbacks, path, contract, "selected_activity_ids", :list)
    |> expect_optional_type(callbacks, path, contract, "candidate_activity_ids", :list)
    |> expect_optional_type(callbacks, path, contract, "ranked_scenario_ids", :list)
    |> expect_optional_type(callbacks, path, contract, "score_term_keys", :list)
    |> expect_optional_type(callbacks, path, contract, "deterministic_ordering", :list)
    |> expect_optional_type(callbacks, path, contract, "preserved_lineage_fields", :list)
    |> expect_optional_type(callbacks, path, contract, "constraints", :map)
    |> expect_optional_type(callbacks, path, contract, "scoring_policy", :map)
    |> expect_optional_type(callbacks, path, contract, "known_limits", :list)
    |> expect_type(callbacks, path, contract, "assumptions", :map)
    |> validate_counts(callbacks, path, contract)
    |> validate_stable_id_list(callbacks, path, contract, "selected_activity_ids")
    |> validate_stable_id_list(callbacks, path, contract, "candidate_activity_ids")
    |> validate_stable_id_list(callbacks, path, contract, "ranked_scenario_ids")
  end

  defp validate_counts(issues, callbacks, path, contract) do
    issues
    |> expect_list_count_equals(
      callbacks,
      path,
      contract,
      "candidate_count",
      "candidate_activity_ids"
    )
    |> expect_list_count_equals(
      callbacks,
      path,
      contract,
      "selected_activity_count",
      "selected_activity_ids"
    )
    |> expect_list_count_equals(
      callbacks,
      path,
      contract,
      "ranked_timeline_count",
      "ranked_scenario_ids"
    )
    |> validate_selected_ids(callbacks, path, contract)
  end

  defp validate_selected_ids(
         issues,
         callbacks,
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
            callbacks,
            "#{path}.selected_activity_ids[#{index}]",
            "must reference candidate_activity_ids"
          )
          | acc
        ]
      end
    end)
  end

  defp validate_selected_ids(issues, _callbacks, _path, _contract), do: issues

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_stable_id_list(issues, callbacks, path, map, field),
    do: apply(Keyword.fetch!(callbacks, :validate_stable_id_list), [issues, path, map, field])

  defp expect_equal(issues, callbacks, path, map, field, expected),
    do: apply(Keyword.fetch!(callbacks, :expect_equal), [issues, path, map, field, expected])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_type), [issues, path, map, field, type])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do: apply(Keyword.fetch!(callbacks, :expect_optional_type), [issues, path, map, field, type])

  defp expect_non_negative_integer(issues, callbacks, path, map, field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_non_negative_integer), [
        issues,
        path,
        map,
        field
      ])

  defp expect_list_count_equals(issues, callbacks, path, map, count_field, list_field),
    do:
      apply(Keyword.fetch!(callbacks, :expect_list_count_equals), [
        issues,
        path,
        map,
        count_field,
        list_field
      ])

  defp error(callbacks, path, message),
    do: apply(Keyword.fetch!(callbacks, :error), [path, message])
end
