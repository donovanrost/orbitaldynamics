defmodule OrbitalDynamics.Schema.CampaignRepairContactContentionResolutionSummaryHandoffContracts do
  @moduledoc false

  import OrbitalDynamics.Schema.CampaignRepairHandoffValidation,
    only: [
      indexed_rows: 2,
      row_source: 1,
      validate_equal: 5,
      validate_source_copies: 6,
      validate_source_identities: 6
    ]

  @source "campaign_repair.source_contact_contention_resolution_summary.summary_recommendations"
  @summary_context_fields [
    "model",
    "schema_contract",
    "source_artifact_type",
    "source",
    "conflict_group_count",
    "recommendation_count",
    "review_recommendation_count",
    "recommendation_group_ids",
    "review_group_ids",
    "selected_contact_ids",
    "deferred_contact_ids",
    "review_contact_ids",
    "capacity_pack_required_capacity_fraction",
    "capacity_pack_selected_required_capacity_fraction",
    "capacity_pack_deferred_required_capacity_fraction",
    "capacity_pack_required_capacity_fraction_by_status",
    "capacity_pack_required_capacity_fraction_by_ground_station_id",
    "required_capacity_fraction_source_counts",
    "action_counts",
    "assumptions"
  ]

  def validate(issues, artifact) when is_map(artifact) do
    {recommendations, summary_context} = source_rows(artifact)
    expected_sources = List.duplicate(@source, length(recommendations))

    issues
    |> validate_operator_handoff(
      artifact,
      recommendations,
      summary_context,
      expected_sources
    )
    |> validate_cadence_handoff(
      artifact,
      recommendations,
      summary_context,
      expected_sources
    )
  end

  def validate(issues, _artifact), do: issues

  defp validate_operator_handoff(
         issues,
         %{"operator_review_package" => %{} = package},
         recommendations,
         summary_context,
         expected_sources
       ) do
    review_rows =
      indexed_rows(Map.get(package, "rows"), &operator_resolution_summary_row?/1)

    issues
    |> validate_equal(
      "$.operator_review_package.rows",
      length(review_rows),
      length(recommendations),
      "must contain one source contention-resolution-summary review row per producer recommendation"
    )
    |> validate_source_identities(
      "$.operator_review_package.rows",
      review_rows,
      expected_sources,
      [["source"]],
      "must match the enclosing source contention-resolution-summary identity"
    )
    |> validate_source_copies(
      "$.operator_review_package.rows",
      review_rows,
      recommendations,
      [["source_recommendation"]],
      "must match the corresponding enclosing source contention-resolution-summary recommendation"
    )
    |> validate_summary_context_copies(
      "$.operator_review_package.rows",
      review_rows,
      summary_context,
      [["source_contact_contention_resolution_summary"]]
    )
  end

  defp validate_operator_handoff(
         issues,
         _artifact,
         _recommendations,
         _summary_context,
         _expected_sources
       ),
       do: issues

  defp validate_cadence_handoff(
         issues,
         %{"cadence_import_manifest" => %{} = manifest},
         recommendations,
         summary_context,
         expected_sources
       ) do
    import_rows =
      indexed_rows(Map.get(manifest, "rows"), &cadence_resolution_summary_row?/1)

    issues
    |> validate_equal(
      "$.cadence_import_manifest.rows",
      length(import_rows),
      length(recommendations),
      "must contain one source contention-resolution-summary import row per producer recommendation"
    )
    |> validate_source_identities(
      "$.cadence_import_manifest.rows",
      import_rows,
      expected_sources,
      [["source"], ["source_review_row", "source"]],
      "must match the enclosing source contention-resolution-summary identity"
    )
    |> validate_source_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      recommendations,
      [["source_recommendation"], ["source_review_row", "source_recommendation"]],
      "must match the corresponding enclosing source contention-resolution-summary recommendation"
    )
    |> validate_summary_context_copies(
      "$.cadence_import_manifest.rows",
      import_rows,
      summary_context,
      [
        ["source_contact_contention_resolution_summary"],
        ["source_review_row", "source_contact_contention_resolution_summary"]
      ]
    )
  end

  defp validate_cadence_handoff(
         issues,
         _artifact,
         _recommendations,
         _summary_context,
         _expected_sources
       ),
       do: issues

  defp validate_summary_context_copies(
         issues,
         base_path,
         indexed_rows,
         summary_context,
         copy_paths
       ) do
    validate_source_copies(
      issues,
      base_path,
      indexed_rows,
      List.duplicate(summary_context, length(indexed_rows)),
      copy_paths,
      "must match the enclosing source contention-resolution-summary context"
    )
  end

  defp source_rows(artifact) do
    case Map.get(artifact, "source_contact_contention_resolution_summary") do
      %{} = summary ->
        context = summary |> Map.take(@summary_context_fields) |> compact_map()

        recommendations =
          summary
          |> recommendation_rows()
          |> Enum.map(&enrich_recommendation(&1, summary, context))

        {recommendations, context}

      _summary ->
        {[], %{}}
    end
  end

  defp recommendation_rows(%{"recommendations" => rows})
       when is_list(rows) and rows != [],
       do: Enum.filter(rows, &is_map/1)

  defp recommendation_rows(summary) do
    summary
    |> recommendation_group_ids()
    |> Enum.map(&recommendation_row(summary, &1))
  end

  defp recommendation_row(summary, group_id) do
    selected_contact_ids = group_ids(summary, group_id, "selected_contact_ids")
    deferred_contact_ids = group_ids(summary, group_id, "deferred_contact_ids")
    review_contact_ids = group_ids(summary, group_id, "review_contact_ids")

    %{
      "group_id" => group_id,
      "ground_station_id" =>
        group_value(summary, group_id, "ground_station_ids") ||
          single_map_key(
            summary,
            "capacity_pack_required_capacity_fraction_by_ground_station_id"
          ),
      "resource_scope" =>
        group_value(summary, group_id, "resource_scopes") ||
          single_count_key(summary, "resource_scope_counts"),
      "selected_contact_id" => List.first(selected_contact_ids),
      "selected_contact_ids" => selected_contact_ids,
      "deferred_contact_ids" => deferred_contact_ids,
      "review_contact_ids" => review_contact_ids,
      "candidate_count" =>
        Enum.count(Enum.uniq(selected_contact_ids ++ deferred_contact_ids ++ review_contact_ids)),
      "selection_reason" =>
        group_value(summary, group_id, "selection_reasons") ||
          single_count_key(summary, "selection_reason_counts"),
      "action" =>
        group_value(summary, group_id, "actions") ||
          single_count_key(summary, "action_counts") ||
          "recommend_preferred_contact_for_operator_review",
      "review_status" => "operator_review_required",
      "capacity_pack_required_capacity_fraction" =>
        group_number(summary, "capacity_pack_required_capacity_fraction"),
      "capacity_pack_selected_required_capacity_fraction" =>
        group_number(summary, "capacity_pack_selected_required_capacity_fraction"),
      "capacity_pack_deferred_required_capacity_fraction" =>
        group_number(summary, "capacity_pack_deferred_required_capacity_fraction"),
      "capacity_pack_required_capacity_fraction_by_status" =>
        summary["capacity_pack_required_capacity_fraction_by_status"],
      "capacity_pack_required_capacity_fraction_by_ground_station_id" =>
        summary["capacity_pack_required_capacity_fraction_by_ground_station_id"],
      "required_capacity_fraction_source_counts" =>
        summary["required_capacity_fraction_source_counts"]
    }
    |> compact_map()
  end

  defp enrich_recommendation(row, summary, context) do
    row
    |> Map.put("source_contact_contention_resolution_summary", context)
    |> Map.put("source_summary_model", summary["model"])
    |> Map.put("source_summary_schema_contract", summary["schema_contract"])
    |> Map.put("source_summary_source", summary["source"])
    |> Map.put("source_artifact_type", summary["source_artifact_type"])
    |> Map.put("schema_contract", summary["schema_contract"])
    |> compact_map()
  end

  defp recommendation_group_ids(summary) do
    keyed_group_ids =
      [
        "selected_contact_ids_by_group_id",
        "deferred_contact_ids_by_group_id",
        "review_contact_ids_by_group_id"
      ]
      |> Enum.flat_map(fn field ->
        case summary[field] do
          %{} = by_group -> Map.keys(by_group)
          _value -> []
        end
      end)

    [summary["recommendation_group_ids"], summary["review_group_ids"], keyed_group_ids]
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp group_ids(summary, group_id, field) do
    value =
      case summary["#{field}_by_group_id"] do
        %{} = by_group -> by_group[group_id]
        _value -> nil
      end

    (value || summary[field] || [])
    |> List.wrap()
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
  end

  defp group_value(summary, group_id, field) do
    case summary["#{field}_by_group_id"] do
      %{} = by_group ->
        by_group[group_id]
        |> List.wrap()
        |> Enum.reject(&(&1 in [nil, ""]))
        |> List.first()

      _value ->
        nil
    end
  end

  defp group_number(summary, field), do: numeric_or_nil(summary[field])

  defp single_map_key(summary, field) do
    case summary[field] do
      %{} = values when map_size(values) == 1 -> values |> Map.keys() |> List.first()
      _value -> nil
    end
  end

  defp single_count_key(summary, field) do
    case summary[field] do
      %{} = counts when map_size(counts) == 1 -> counts |> Map.keys() |> List.first()
      _value -> nil
    end
  end

  defp numeric_or_nil(value) when is_integer(value) or is_float(value), do: value * 1.0

  defp numeric_or_nil(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _other -> nil
    end
  end

  defp numeric_or_nil(_value), do: nil

  defp operator_resolution_summary_row?(row) do
    Map.get(row, "review_type") == "contact_contention_recommendation" and
      resolution_summary_source?(row_source(row))
  end

  defp cadence_resolution_summary_row?(row) do
    (Map.get(row, "source_review_type") == "contact_contention_recommendation" or
       Map.get(row, "import_action") == "review_contact_contention_resolution") and
      resolution_summary_source?(row_source(row))
  end

  defp resolution_summary_source?(source) when is_binary(source),
    do: String.starts_with?(source, @source)

  defp resolution_summary_source?(_source), do: false

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_field, value} -> is_nil(value) end)
    |> Map.new()
  end
end
