defmodule OrbitalDynamics.CadenceImport.ReviewPackageImport do
  @moduledoc false

  alias OrbitalDynamics.CadenceImport.{
    JsonNormalization,
    ManifestBuilder,
    ReviewPackageRowSourcePolicy,
    ReviewRowMetadata,
    ReviewSummaryContext,
    ReviewTypePolicy
  }

  def build(package, opts, dispatch, config) do
    package = JsonNormalization.stringify_keys(package)

    source_artifact_type =
      Keyword.get(opts, :source_artifact_type, package["source_artifact_type"])

    source_artifact_id = Keyword.get(opts, :source_artifact_id, package["source_artifact_id"])

    rows =
      package
      |> Map.get("rows", [])
      |> Enum.map(&JsonNormalization.stringify_keys/1)
      |> Enum.filter(&ReviewTypePolicy.import_manifest?/1)
      |> Enum.with_index(1)
      |> Enum.map(fn {row, rank} ->
        row
        |> dispatch.(rank)
        |> ReviewRowMetadata.put_run_input_sources(row)
        |> ReviewRowMetadata.put_queue(row)
      end)

    summary_context = ReviewSummaryContext.build(package)

    provenance =
      %{
        "source" => "OrbitalDynamics.CadenceImport.from_operator_review_package",
        "source_artifact_type" => source_artifact_type,
        "source_artifact_id" => source_artifact_id,
        "source_review_count" => package["review_count"],
        "source_repair_id" => Keyword.get(opts, :source_repair_id),
        "source_plan_id" => Keyword.get(opts, :source_plan_id)
      }
      |> Map.merge(summary_context)

    context =
      %{
        "source_artifact_type" => source_artifact_type,
        "source_artifact_id" => source_artifact_id,
        "row_source" => ReviewPackageRowSourcePolicy.resolve(source_artifact_type),
        "deterministic_ordering" => "source review row order"
      }
      |> Map.merge(summary_context)

    ManifestBuilder.build(rows, provenance, context, config)
  end
end
