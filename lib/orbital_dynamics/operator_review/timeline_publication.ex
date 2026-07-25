defmodule OrbitalDynamics.OperatorReview.TimelinePublication do
  @moduledoc false

  alias OrbitalDynamics.OperatorReview.Capabilities
  alias OrbitalDynamics.OperatorReview.PackageBuilder

  @schema_contract "operator_review_package.v1"

  def dependency_impact_package(summary) do
    {rows, source_artifact_id, provenance} = dependency_impact_package_input(summary)

    build_package(rows, "timeline_dependency_impact_summary.v1", source_artifact_id, provenance)
  end

  def publication_package(summary) do
    {rows, source_artifact_id, provenance} = publication_package_input(summary)

    build_package(rows, "timeline_publication_summary.v1", source_artifact_id, provenance)
  end

  def dependency_impact_package_input(summary) do
    summary = stringify_keys(summary || %{})

    {
      dependency_impact_rows(summary),
      Map.get(summary, "id") || Map.get(summary, "source") ||
        "timeline_dependency_impact_summary",
      Map.get(summary, "provenance", %{})
    }
  end

  def publication_package_input(summary) do
    summary = stringify_keys(summary || %{})
    summary = Map.put_new(summary, "schema_contract", "timeline_publication_summary.v1")

    {
      publication_rows(summary),
      Map.get(summary, "publication_id") || Map.get(summary, "source_artifact_id") ||
        "timeline_publication_summary",
      Map.get(summary, "provenance", %{})
    }
  end

  def candidate_refresh_dependency_impact_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_timeline_dependency_impact_summary",
         artifact["source_timeline_dependency_impact_summary"]},
        {"candidate_refresh.timeline_dependency_impact_summary",
         artifact["timeline_dependency_impact_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_dependency_impact_rows(summary_or_summaries, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_dependency_impact_rows(artifact)
  end

  def source_dependency_impact_rows(summaries, source) when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_dependency_impact_rows(summary, "#{source}[#{index}]")
    end)
  end

  def source_dependency_impact_rows(%{} = summary, source) do
    summary
    |> stringify_keys()
    |> dependency_impact_rows("#{source}.dependency_impact_rows")
  end

  def source_dependency_impact_rows(_summary, _source), do: []

  defp candidate_refresh_result_artifact_dependency_impact_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_dependency_impact_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_dependency_impact_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_dependency_impact_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_dependency_impact_rows(
         %{"schema_contract" => "timeline_dependency_impact_summary.v1"} = summary,
         source
       ) do
    source_dependency_impact_rows(summary, source)
  end

  defp result_artifact_dependency_impact_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_dependency_impact_summary",
       artifact["source_timeline_dependency_impact_summary"]},
      {"#{source}.timeline_dependency_impact_summary",
       artifact["timeline_dependency_impact_summary"]}
    ]
    |> Enum.flat_map(fn {summary_source, summary_or_summaries} ->
      source_dependency_impact_rows(summary_or_summaries, summary_source)
    end)
  end

  defp result_artifact_dependency_impact_rows(_artifact, _source), do: []

  def candidate_refresh_publication_rows(artifact) do
    direct_rows =
      [
        {"candidate_refresh.source_timeline_publication_summary",
         artifact["source_timeline_publication_summary"]},
        {"candidate_refresh.timeline_publication_summary",
         artifact["timeline_publication_summary"]}
      ]
      |> Enum.flat_map(fn {source, summary_or_summaries} ->
        source_publication_rows(summary_or_summaries, source)
      end)

    direct_rows ++ candidate_refresh_result_artifact_publication_rows(artifact)
  end

  defp source_publication_rows(summaries, source) when is_list(summaries) do
    summaries
    |> Enum.with_index()
    |> Enum.flat_map(fn {summary, index} ->
      source_publication_rows(summary, "#{source}[#{index}]")
    end)
  end

  defp source_publication_rows(%{} = summary, source) do
    summary
    |> stringify_keys()
    |> publication_rows(source)
  end

  defp source_publication_rows(_summary, _source), do: []

  defp candidate_refresh_result_artifact_publication_rows(artifact) do
    [
      {"candidate_refresh.source_result_artifact", artifact["source_result_artifact"]},
      {"candidate_refresh.result_artifact", artifact["result_artifact"]}
    ]
    |> Enum.flat_map(fn {source, artifact_or_artifacts} ->
      result_artifact_publication_rows(artifact_or_artifacts, source)
    end)
  end

  defp result_artifact_publication_rows(artifacts, source) when is_list(artifacts) do
    artifacts
    |> Enum.with_index()
    |> Enum.flat_map(fn {artifact, index} ->
      result_artifact_publication_rows(artifact, "#{source}[#{index}]")
    end)
  end

  defp result_artifact_publication_rows(
         %{"schema_contract" => "timeline_publication_summary.v1"} = summary,
         source
       ) do
    source_publication_rows(summary, source)
  end

  defp result_artifact_publication_rows(%{} = artifact, source) do
    artifact = stringify_keys(artifact)

    [
      {"#{source}.source_timeline_publication_summary",
       artifact["source_timeline_publication_summary"]},
      {"#{source}.timeline_publication_summary", artifact["timeline_publication_summary"]}
    ]
    |> Enum.flat_map(fn {summary_source, summary_or_summaries} ->
      source_publication_rows(summary_or_summaries, summary_source)
    end)
  end

  defp result_artifact_publication_rows(_artifact, _source), do: []

  def dependency_impact_rows(summary),
    do: dependency_impact_rows(summary, "timeline_dependency_impact_summary.rows")

  def dependency_impact_rows(%{} = summary, source) do
    summary
    |> Map.get("dependency_impact_rows", [])
    |> Enum.map(&stringify_keys/1)
    |> Enum.reject(&(&1["dependency_impact_status"] == "clear"))
    |> Enum.with_index(1)
    |> Enum.map(fn {row, index} ->
      dependency_impact_review_row(row, index, source, summary)
    end)
  end

  def dependency_impact_rows(_summary, _source), do: []

  defp dependency_impact_review_row(row, index, source, summary) do
    %{
      "id" => review_id(["timeline_dependency_impact", row["id"] || row["timeline_id"], index]),
      "review_type" => "timeline_dependency_impact_review",
      "source" => source,
      "subject_id" => row["timeline_id"] || row["activity_id"],
      "timeline_id" => row["timeline_id"],
      "activity_id" => row["activity_id"],
      "activity_type" => row["activity_type"],
      "scenario_id" => row["scenario_id"],
      "dependency_impact_scope" => row["scope"],
      "dependency_impact_status" => row["dependency_impact_status"] || "review_required",
      "action" => row["required_operator_action"],
      "required_operator_action" => row["required_operator_action"],
      "approval_status" => "operator_review_required",
      "reason" => row["operator_action_reason"],
      "operator_action_reason" => row["operator_action_reason"],
      "status" => row["status"],
      "source_activity_count" => summary["source_activity_count"],
      "replacement_activity_count" => summary["replacement_activity_count"],
      "changed_source_activity_count" => summary["changed_source_activity_count"],
      "changed_source_timeline_count" => summary["changed_source_timeline_count"],
      "dependent_activity_count" => summary["dependent_activity_count"],
      "source_dependent_activity_count" => summary["source_dependent_activity_count"],
      "replacement_dependent_activity_count" => summary["replacement_dependent_activity_count"],
      "impacted_source_activity_ids" => summary["impacted_source_activity_ids"],
      "impacted_source_timeline_ids" => summary["impacted_source_timeline_ids"],
      "dependent_activity_ids" => summary["dependent_activity_ids"],
      "dependent_timeline_ids" => summary["dependent_timeline_ids"],
      "source_dependent_activity_ids" => summary["source_dependent_activity_ids"],
      "source_dependent_timeline_ids" => summary["source_dependent_timeline_ids"],
      "replacement_dependent_activity_ids" => summary["replacement_dependent_activity_ids"],
      "replacement_dependent_timeline_ids" => summary["replacement_dependent_timeline_ids"],
      "source_dependency_impact_impacted_dependency_activity_ids" =>
        summary["impacted_dependency_activity_ids"],
      "source_dependency_impact_impacted_dependency_timeline_ids" =>
        summary["impacted_dependency_timeline_ids"],
      "source_dependency_impact_impacted_exclusive_with_activity_ids" =>
        summary["impacted_exclusive_with_activity_ids"],
      "source_dependency_impact_impacted_exclusive_with_timeline_ids" =>
        summary["impacted_exclusive_with_timeline_ids"],
      "dependency_activity_ids" => row["dependency_activity_ids"],
      "dependency_timeline_ids" => row["dependency_timeline_ids"],
      "exclusive_with_activity_ids" => row["exclusive_with_activity_ids"],
      "exclusive_with_timeline_ids" => row["exclusive_with_timeline_ids"],
      "impacted_dependency_activity_ids" => row["impacted_dependency_activity_ids"],
      "impacted_dependency_timeline_ids" => row["impacted_dependency_timeline_ids"],
      "impacted_exclusive_with_activity_ids" => row["impacted_exclusive_with_activity_ids"],
      "impacted_exclusive_with_timeline_ids" => row["impacted_exclusive_with_timeline_ids"],
      "source_timeline_dependency_impact" => row
    }
    |> compact_map()
  end

  def publication_rows(summary), do: publication_rows(summary, "timeline_publication_summary")

  def publication_rows(%{} = summary, source) do
    [
      %{
        "id" =>
          review_id([
            "timeline_publication",
            summary["publication_id"] || summary["source_artifact_id"] || "summary",
            summary["publication_sequence"] || 0
          ]),
        "review_type" => "timeline_publication_review",
        "source" => source,
        "subject_id" => summary["publication_id"] || summary["source_artifact_id"],
        "publication_id" => summary["publication_id"],
        "publication_sequence" => summary["publication_sequence"],
        "publication_status" => summary["publication_status"],
        "downstream_invalidation_status" => summary["downstream_invalidation_status"],
        "publication_authority" => summary["publication_authority"],
        "source_artifact_id" => summary["source_artifact_id"],
        "source_artifact_type" => summary["source_artifact_type"],
        "supersedes_artifact_ids" => summary["supersedes_artifact_ids"],
        "downstream_product_ids" => summary["downstream_product_ids"],
        "invalidated_downstream_product_ids" => summary["invalidated_downstream_product_ids"],
        "downstream_invalidation_reason_counts" =>
          summary["downstream_invalidation_reason_counts"],
        "invalidated_downstream_product_ids_by_reason" =>
          summary["invalidated_downstream_product_ids_by_reason"],
        "dependency_impact_status" => summary["dependency_impact_status"],
        "dependency_impact_row_count" => summary["dependency_impact_row_count"],
        "impacted_source_activity_ids" => summary["impacted_source_activity_ids"],
        "impacted_source_timeline_ids" => summary["impacted_source_timeline_ids"],
        "dependent_activity_ids" => summary["dependent_activity_ids"],
        "dependent_timeline_ids" => summary["dependent_timeline_ids"],
        "source_dependent_activity_ids" => summary["source_dependent_activity_ids"],
        "source_dependent_timeline_ids" => summary["source_dependent_timeline_ids"],
        "replacement_dependent_activity_ids" => summary["replacement_dependent_activity_ids"],
        "replacement_dependent_timeline_ids" => summary["replacement_dependent_timeline_ids"],
        "impacted_dependency_activity_ids" => summary["impacted_dependency_activity_ids"],
        "impacted_dependency_timeline_ids" => summary["impacted_dependency_timeline_ids"],
        "impacted_exclusive_with_activity_ids" => summary["impacted_exclusive_with_activity_ids"],
        "impacted_exclusive_with_timeline_ids" => summary["impacted_exclusive_with_timeline_ids"],
        "timeline_diff_row_count" => summary["timeline_diff_row_count"],
        "timeline_diff_changed_count" => summary["timeline_diff_changed_count"],
        "timeline_diff_review_required_count" => summary["timeline_diff_review_required_count"],
        "changed_field_counts" => summary["changed_field_counts"],
        "changed_timeline_ids" => summary["changed_timeline_ids"],
        "review_timeline_ids" => summary["review_timeline_ids"],
        "timeline_ids_by_changed_field" => summary["timeline_ids_by_changed_field"],
        "action" => "review_timeline_publication",
        "required_operator_action" => "review_timeline_publication",
        "approval_status" => "operator_review_required",
        "reason" => publication_review_reason(summary),
        "operator_action_reason" => publication_operator_action_reason(summary),
        "source_timeline_publication_summary" => summary
      }
      |> compact_map()
    ]
  end

  def publication_rows(_summary, _source), do: []

  defp publication_review_reason(%{} = summary) do
    "review publication #{summary["publication_id"] || summary["source_artifact_id"]} before downstream handoff"
  end

  defp publication_operator_action_reason(%{
         "publication_status" => "published_with_downstream_invalidations"
       }),
       do: "publication_invalidates_downstream_products"

  defp publication_operator_action_reason(%{
         "dependency_impact_status" => "review_required"
       }),
       do: "publication_dependency_impact_review_required"

  defp publication_operator_action_reason(%{
         "timeline_diff_review_required_count" => count
       })
       when is_integer(count) and count > 0,
       do: "publication_timeline_diff_review_required"

  defp publication_operator_action_reason(_summary), do: "publication_metadata_review_required"

  defp review_id(parts) do
    parts
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.map(&encode_value/1)
    |> Enum.join(":")
  end

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(nil), do: nil
  defp encode_value(:null), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp build_package(rows, source_artifact_type, source_artifact_id, provenance) do
    PackageBuilder.build(
      rows,
      source_artifact_type,
      source_artifact_id,
      provenance,
      @schema_contract,
      Capabilities.model_limits()
    )
  end
end
