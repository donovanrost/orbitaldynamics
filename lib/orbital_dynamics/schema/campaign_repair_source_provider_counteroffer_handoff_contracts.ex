defmodule OrbitalDynamics.Schema.CampaignRepairSourceProviderCounterofferHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @report_source_prefix "campaign_repair.source_provider_counteroffer_report"
  @report_source @report_source_prefix <> ".rows"
  @review_summary_source_prefix "campaign_repair.source_provider_counteroffer_review_summary"
  @review_summary_source @review_summary_source_prefix <> ".review_rows"
  @plan_impact_summary_source_prefix "campaign_repair.source_provider_counteroffer_plan_impact_summary"
  @plan_impact_summary_source @plan_impact_summary_source_prefix <> ".impact_rows"
  @summary_context_fields [
    "model",
    "schema_contract",
    "source",
    "source_artifact_type",
    "source_artifact_id",
    "counteroffer_count",
    "reviewable_count",
    "review_counteroffer_ids",
    "counteroffer_review_status",
    "counteroffer_status_counts",
    "counteroffer_negotiation_state_counts",
    "counteroffer_lock_deadline_count",
    "earliest_counteroffer_lock_deadline_s",
    "expired_counteroffer_lock_deadline_count",
    "active_counteroffer_lock_deadline_count",
    "missing_counteroffer_lock_deadline_count",
    "import_readiness_status",
    "import_classification",
    "provider_counteroffer_import_status_counts",
    "required_import_action_counts",
    "plan_impact_status",
    "counteroffer_lock_deadline_status_counts",
    "counteroffer_ids_by_lock_deadline_status",
    "assumptions"
  ]

  def validate(issues, artifact) do
    issues
    |> validate_report(artifact)
    |> validate_review_summary(artifact)
    |> validate_plan_impact_summary(artifact)
  end

  defp validate_report(
         issues,
         %{"source_provider_counteroffer_report" => %{} = report} = artifact
       ) do
    validate_handoffs(
      issues,
      artifact,
      eligible_rows(report, "rows"),
      @report_source_prefix,
      @report_source,
      "provider-counteroffer report"
    )
  end

  defp validate_report(issues, _artifact), do: issues

  defp validate_review_summary(
         issues,
         %{"source_provider_counteroffer_review_summary" => %{} = summary} = artifact
       ) do
    context = summary_context(summary)

    source_rows =
      summary
      |> eligible_rows("review_rows")
      |> Enum.map(&Map.put(&1, "source_provider_counteroffer_summary", context))

    validate_handoffs(
      issues,
      artifact,
      source_rows,
      @review_summary_source_prefix,
      @review_summary_source,
      "provider-counteroffer review-summary"
    )
  end

  defp validate_review_summary(issues, _artifact), do: issues

  defp validate_plan_impact_summary(
         issues,
         %{"source_provider_counteroffer_plan_impact_summary" => %{} = summary} = artifact
       ) do
    context = summary_context(summary)

    source_rows =
      summary
      |> eligible_rows("impact_rows")
      |> Enum.map(&Map.put(&1, "source_provider_counteroffer_summary", context))

    validate_handoffs(
      issues,
      artifact,
      source_rows,
      @plan_impact_summary_source_prefix,
      @plan_impact_summary_source,
      "provider-counteroffer plan-impact-summary"
    )
  end

  defp validate_plan_impact_summary(issues, _artifact), do: issues

  defp validate_handoffs(
         issues,
         artifact,
         source_rows,
         source_prefix,
         source,
         label
       ) do
    expected_sources = List.duplicate(source, length(source_rows))

    issues
    |> validate_operator_review_handoff(
      artifact,
      source_rows,
      expected_sources,
      source_prefix,
      label
    )
    |> validate_cadence_handoff(
      artifact,
      source_rows,
      expected_sources,
      source_prefix,
      label
    )
  end

  defp validate_operator_review_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         source_rows,
         expected_sources,
         source_prefix,
         label
       ) do
    review_rows =
      indexed_rows(
        Map.get(package, "rows"),
        &operator_counteroffer_row?(&1, source_prefix)
      )

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(source_rows),
      "must contain one Repair source #{label} review row per eligible enclosing row"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing Repair source #{label} source"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      source_rows,
      [["source_provider_counteroffer"]],
      "must match the corresponding eligible enclosing Repair source #{label} row"
    )
  end

  defp validate_operator_review_handoff(
         issues,
         _artifact,
         _source_rows,
         _expected_sources,
         _source_prefix,
         _label
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         source_rows,
         expected_sources,
         source_prefix,
         label
       ) do
    import_rows =
      indexed_rows(
        Map.get(manifest, "rows"),
        &cadence_counteroffer_row?(&1, source_prefix)
      )

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(source_rows),
      "must contain one Repair source #{label} import row per eligible enclosing row"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing Repair source #{label} source"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      source_rows,
      [["source_provider_counteroffer"], ["source_review_row", "source_provider_counteroffer"]],
      "must match the corresponding eligible enclosing Repair source #{label} row"
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _source_rows,
         _expected_sources,
         _source_prefix,
         _label
       ),
       do: issues

  defp operator_counteroffer_row?(row, source_prefix) do
    Map.get(row, "review_type") == "provider_counteroffer_review" and
      repair_counteroffer_source?(row_source(row), source_prefix)
  end

  defp cadence_counteroffer_row?(row, source_prefix) do
    (Map.get(row, "source_review_type") == "provider_counteroffer_review" or
       Map.get(row, "import_action") == "review_provider_counteroffer") and
      repair_counteroffer_source?(row_source(row), source_prefix)
  end

  defp repair_counteroffer_source?(source, source_prefix) when is_binary(source),
    do: String.starts_with?(source, source_prefix)

  defp repair_counteroffer_source?(_source, _source_prefix), do: false

  defp eligible_rows(container, field) do
    case Map.get(container, field) do
      rows when is_list(rows) -> Enum.filter(rows, &eligible_row?/1)
      _rows -> []
    end
  end

  defp eligible_row?(%{} = row) do
    Map.get(row, "reviewable") == true and
      Map.get(row, "required_operator_action") == "review_provider_counteroffer"
  end

  defp eligible_row?(_row), do: false

  defp summary_context(summary) do
    summary
    |> Map.take(@summary_context_fields)
    |> Enum.reject(fn {_field, value} -> is_nil(value) end)
    |> Map.new()
  end
end
