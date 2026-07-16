defmodule OrbitalDynamics.Schema.StrategyRecommendationContracts do
  @moduledoc false

  def validate(issues, path, recommendation, callbacks) when is_list(callbacks) do
    issues
    |> require_fields(callbacks, path, recommendation, [
      "recommended_branch_id",
      "approval_status",
      "reason",
      "ranked_branch_ids",
      "tradeoffs",
      "explanation",
      "risks_remaining",
      "requires_approval"
    ])
    |> validate_stable_ids(callbacks, path, recommendation, ["recommended_branch_id"])
    |> validate_stable_id_list(
      callbacks,
      path <> ".ranked_branch_ids",
      Map.get(recommendation, "ranked_branch_ids")
    )
    |> validate_optional_schema_contract(
      callbacks,
      path,
      recommendation,
      "strategy_recommendation.v1"
    )
    |> expect_optional_type(callbacks, path, recommendation, "status", :binary)
    |> expect_type(callbacks, path, recommendation, "ranked_branch_ids", :list)
    |> expect_type(callbacks, path, recommendation, "tradeoffs", :list)
    |> expect_type(callbacks, path, recommendation, "requires_approval", :list)
    |> expect_type(callbacks, path, recommendation, "explanation", :list)
    |> validate_consistency(callbacks, path, recommendation)
    |> validate_optional_rows(
      callbacks,
      path <> ".tradeoffs",
      Map.get(recommendation, "tradeoffs"),
      fn acc, row_path, row -> validate_tradeoff(acc, row_path, row, callbacks) end
    )
    |> validate_optional_rows(
      callbacks,
      path <> ".explanation",
      Map.get(recommendation, "explanation"),
      fn acc, row_path, row -> validate_explanation(acc, row_path, row, callbacks) end
    )
    |> validate_optional_rows(
      callbacks,
      path <> ".risks_remaining",
      Map.get(recommendation, "risks_remaining"),
      fn acc, row_path, row -> validate_risk(acc, row_path, row, callbacks) end
    )
  end

  defp validate_consistency(issues, callbacks, path, recommendation) do
    recommended_branch_id = Map.get(recommendation, "recommended_branch_id")

    issues
    |> validate_ranked_branch(callbacks, path, recommendation, recommended_branch_id)
    |> validate_explanation_branch_ids(callbacks, path, recommendation, recommended_branch_id)
    |> validate_approval_requirements(callbacks, path, recommendation)
  end

  defp validate_ranked_branch(
         issues,
         _callbacks,
         _path,
         %{"ranked_branch_ids" => [recommended_branch_id | _ids]},
         recommended_branch_id
       )
       when is_binary(recommended_branch_id),
       do: issues

  defp validate_ranked_branch(
         issues,
         callbacks,
         path,
         %{"ranked_branch_ids" => ids},
         recommended_branch_id
       )
       when is_list(ids) and is_binary(recommended_branch_id) do
    [
      error(callbacks, path <> ".recommended_branch_id", "must be first in ranked_branch_ids")
      | issues
    ]
  end

  defp validate_ranked_branch(
         issues,
         _callbacks,
         _path,
         _recommendation,
         _recommended_branch_id
       ),
       do: issues

  defp validate_explanation_branch_ids(
         issues,
         callbacks,
         path,
         %{"explanation" => explanation},
         recommended_branch_id
       )
       when is_list(explanation) and is_binary(recommended_branch_id) do
    explanation
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      case row do
        %{"recommended_branch_id" => ^recommended_branch_id} ->
          acc

        %{"recommended_branch_id" => _other_branch_id} ->
          [
            error(
              callbacks,
              "#{path}.explanation[#{index}].recommended_branch_id",
              "must match top-level recommended_branch_id"
            )
            | acc
          ]

        _row ->
          acc
      end
    end)
  end

  defp validate_explanation_branch_ids(
         issues,
         _callbacks,
         _path,
         _recommendation,
         _recommended_branch_id
       ),
       do: issues

  defp validate_approval_requirements(issues, callbacks, path, %{
         "approval_status" => approval_status,
         "requires_approval" => rows
       })
       when is_binary(approval_status) and is_list(rows) do
    rows
    |> Enum.with_index()
    |> Enum.reduce(issues, fn {row, index}, acc ->
      case row do
        %{"policy_classification" => ^approval_status} ->
          acc

        %{"policy_classification" => _other_classification} ->
          [
            error(
              callbacks,
              "#{path}.requires_approval[#{index}].policy_classification",
              "must match recommendation approval_status"
            )
            | acc
          ]

        _row ->
          acc
      end
    end)
  end

  defp validate_approval_requirements(issues, _callbacks, _path, _recommendation), do: issues

  defp validate_tradeoff(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, ["dimension", "baseline", "recommended", "delta"])
    |> expect_type(callbacks, path, row, "dimension", :binary)
    |> expect_number(callbacks, path, row, "baseline")
    |> expect_number(callbacks, path, row, "recommended")
    |> expect_number(callbacks, path, row, "delta")
    |> validate_tradeoff_delta(callbacks, path, row)
  end

  defp validate_tradeoff_delta(
         issues,
         callbacks,
         path,
         %{"baseline" => baseline, "recommended" => recommended, "delta" => delta}
       )
       when is_number(baseline) and is_number(recommended) and is_number(delta) do
    if abs(delta - (recommended - baseline)) <= 1.0e-9 do
      issues
    else
      [error(callbacks, path <> ".delta", "must equal recommended minus baseline") | issues]
    end
  end

  defp validate_tradeoff_delta(issues, _callbacks, _path, _row), do: issues

  defp validate_explanation(issues, path, row, callbacks) do
    issues
    |> require_fields(callbacks, path, row, ["type"])
    |> validate_branch_event_summary_fields(callbacks, path, row)
  end

  defp validate_risk(issues, path, risk, callbacks) do
    issues
    |> require_fields(callbacks, path, risk, ["type", "severity", "reason"])
    |> validate_scoped_downlink_context_fields(callbacks, path, risk)
  end

  defp require_fields(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :require_fields), [issues, path, map, fields])

  defp validate_stable_ids(issues, callbacks, path, map, fields),
    do: apply(require_callback(callbacks, :validate_stable_ids), [issues, path, map, fields])

  defp validate_stable_id_list(issues, callbacks, path, values),
    do: apply(require_callback(callbacks, :validate_stable_id_list), [issues, path, values])

  defp validate_optional_schema_contract(issues, callbacks, path, row, expected),
    do:
      apply(require_callback(callbacks, :validate_optional_schema_contract), [
        issues,
        path,
        row,
        expected
      ])

  defp expect_optional_type(issues, callbacks, path, map, field, type),
    do:
      apply(require_callback(callbacks, :expect_optional_type), [
        issues,
        path,
        map,
        field,
        type
      ])

  defp expect_type(issues, callbacks, path, map, field, type),
    do: apply(require_callback(callbacks, :expect_type), [issues, path, map, field, type])

  defp validate_optional_rows(issues, callbacks, path, rows, validator),
    do:
      apply(require_callback(callbacks, :validate_optional_rows), [issues, path, rows, validator])

  defp expect_number(issues, callbacks, path, map, field),
    do: apply(require_callback(callbacks, :expect_number), [issues, path, map, field])

  defp validate_branch_event_summary_fields(issues, callbacks, path, row),
    do:
      apply(require_callback(callbacks, :validate_branch_event_summary_fields), [
        issues,
        path,
        row
      ])

  defp validate_scoped_downlink_context_fields(issues, callbacks, path, row),
    do:
      apply(require_callback(callbacks, :validate_scoped_downlink_context_fields), [
        issues,
        path,
        row
      ])

  defp error(callbacks, path, message),
    do: apply(require_callback(callbacks, :error), [path, message])

  defp require_callback(callbacks, name) do
    Keyword.fetch!(callbacks, name)
  end
end
