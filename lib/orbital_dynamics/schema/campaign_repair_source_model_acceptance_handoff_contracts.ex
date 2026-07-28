defmodule OrbitalDynamics.Schema.CampaignRepairSourceModelAcceptanceHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @repair_source_prefix "campaign_repair.source_model_acceptance_report"
  @repair_source @repair_source_prefix <> ".rows"
  @context_fields [
    "schema_contract",
    "schema_version",
    "model",
    "report_id",
    "intended_use",
    "status",
    "model_count",
    "accepted_count",
    "review_required_count",
    "blocked_count",
    "unknown_model_count",
    "status_counts",
    "validation_level_counts",
    "model_ids_by_status",
    "model_ids_by_validation_level",
    "model_ids_by_intended_use",
    "assumptions",
    "model_limits"
  ]

  def validate(issues, artifact) when is_map(artifact) do
    report = source_report(artifact)
    source_rows = reviewable_rows(report)
    expected_sources = List.duplicate(@repair_source, length(source_rows))
    report_contexts = List.duplicate(Map.take(report, @context_fields), length(source_rows))

    validate_operator_review_handoff(
      issues,
      artifact,
      source_rows,
      report_contexts,
      expected_sources
    )
  end

  def validate(issues, _artifact), do: issues

  defp source_report(%{"source_model_acceptance_report" => %{} = report}), do: report
  defp source_report(_artifact), do: %{}

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         source_rows,
         report_contexts,
         expected_sources
       ) do
    review_rows = indexed_rows(Map.get(package, "rows"), &operator_model_acceptance_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(source_rows),
      "must contain one Repair source model-acceptance review row per eligible enclosing report row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source model-acceptance report source"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_rows,
      [["source_model_acceptance_row"]],
      "must match the corresponding eligible enclosing Repair source model-acceptance row"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      report_contexts,
      [["source_model_acceptance_report"]],
      "must match the producer-derived enclosing Repair source model-acceptance report context"
    )
  end

  defp validate_operator_review_handoff(
         issues,
         _artifact,
         _source_rows,
         _report_contexts,
         _expected_sources
       ),
       do: issues

  defp operator_model_acceptance_row?(row) do
    Map.get(row, "review_type") == "model_acceptance_review" and
      repair_model_acceptance_source?(row_source(row))
  end

  defp repair_model_acceptance_source?(source) when is_binary(source),
    do: String.starts_with?(source, @repair_source_prefix)

  defp repair_model_acceptance_source?(_source), do: false

  defp reviewable_rows(report) do
    case Map.get(report, "rows") do
      rows when is_list(rows) ->
        Enum.filter(
          rows,
          &(is_map(&1) and Map.get(&1, "status") not in [nil, "accepted", "accepted_for_use"])
        )

      _rows ->
        []
    end
  end
end
