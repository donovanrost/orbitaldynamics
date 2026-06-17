defmodule OrbitalDynamics.CampaignPlanner.CadenceImportSourceReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.CadenceImportFeedbackRows

  def cadence_import_manifests(mission_state, opts) do
    source_cadence_import_manifests(mission_state, opts) ++
      canonical_cadence_import_manifests(mission_state, opts) ++
      result_artifact_embedded_manifests(mission_state, opts)
  end

  def source_cadence_import_manifests(mission_state, opts) do
    source_artifacts(
      mission_state,
      [
        {"source_cadence_import_manifest", "mission_state.source_cadence_import_manifest"}
      ],
      opts
    )
  end

  def canonical_cadence_import_manifests(mission_state, opts) do
    source_artifacts(
      mission_state,
      [
        {"cadence_import_manifest", "mission_state.cadence_import_manifest"}
      ],
      opts
    )
  end

  def cadence_import_manifest_reports(mission_state, "source_cadence_import_manifest", opts) do
    source_cadence_import_manifests(mission_state, opts)
  end

  def cadence_import_manifest_reports(mission_state, "cadence_import_manifest", opts) do
    canonical_cadence_import_manifests(mission_state, opts)
  end

  def prior_plan_cadence_import_manifests(prior_plan, opts) when is_list(opts) do
    prior_plan = stringify_keys(prior_plan || %{})
    callbacks = prior_plan_callbacks!(opts)

    direct_cadence_import_manifests(
      Map.get(prior_plan, "cadence_import_manifest"),
      "prior_plan.cadence_import_manifest",
      opts
    ) ++
      (prior_plan
       |> callbacks.result_artifacts_with_source.()
       |> result_artifact_embedded_cadence_import_manifests(opts))
  end

  def direct_cadence_import_manifests(artifacts, source_path, opts) when is_list(opts) do
    source_artifact_entries = Keyword.fetch!(opts, :source_artifact_entries)

    source_artifact_entries.(artifacts, source_path)
  end

  def result_artifact_embedded_cadence_import_manifests(artifacts_with_sources, opts)
      when is_list(opts) do
    result_artifact_embedded_report_entries =
      Keyword.fetch!(opts, :result_artifact_embedded_report_entries)

    artifacts_with_sources
    |> Enum.flat_map(fn {artifact, source_path} ->
      cadence_import_manifest_keys()
      |> Enum.flat_map(fn manifest_key ->
        result_artifact_embedded_report_entries.(
          Map.get(artifact, manifest_key),
          artifact,
          "#{source_path}.#{manifest_key}"
        )
      end)
    end)
  end

  def rows_with_source(manifests_with_sources, opts) when is_list(opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    cadence_import_trust_boundary = Keyword.fetch!(opts, :cadence_import_trust_boundary)

    manifests_with_sources
    |> Enum.flat_map(fn {manifest, source_path} ->
      manifest_trust_boundary =
        Map.get(manifest, "trust_boundary") || get_in(manifest, ["provenance", "trust_boundary"])

      manifest
      |> Map.get("rows", [])
      |> Enum.map(stringify_keys)
      |> Enum.map(fn row ->
        row =
          row
          |> Map.put(
            "_source_report_trust_boundary",
            cadence_import_trust_boundary.(row, manifest_trust_boundary)
          )
          |> Map.put("_source_path", "#{source_path}.rows")

        {row, source_path}
      end)
    end)
  end

  def source_review_rows(manifests_with_sources, opts) when is_list(opts) do
    manifests_with_sources
    |> rows(opts)
    |> CadenceImportFeedbackRows.source_review_rows()
  end

  def all_operational_feedback_rows(manifests_with_sources, opts) when is_list(opts) do
    manifests_with_sources
    |> rows(opts)
    |> CadenceImportFeedbackRows.all_operational_feedback_rows()
  end

  def operational_feedback_rows(manifests_with_sources, opts) when is_list(opts) do
    operational_feedback_data_keys = Keyword.fetch!(opts, :operational_feedback_data_keys)

    manifests_with_sources
    |> all_operational_feedback_rows(opts)
    |> Enum.filter(fn row ->
      case Map.get(row, "source_operational_feedback") do
        %{} = feedback -> operational_feedback_data_keys.(feedback) != []
        _feedback -> false
      end
    end)
  end

  def source_review_metadata(manifests_with_sources, opts) when is_list(opts) do
    manifests_with_sources
    |> source_review_rows(opts)
    |> CadenceImportFeedbackRows.source_review_metadata()
  end

  def source_operational_feedback_metadata(manifests_with_sources, opts) when is_list(opts) do
    manifests_with_sources
    |> all_operational_feedback_rows(opts)
    |> CadenceImportFeedbackRows.source_operational_feedback_metadata()
  end

  defp source_artifacts(mission_state, fields, opts) do
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      direct_cadence_import_manifests(Map.get(mission_state, field), source_path, opts)
    end)
  end

  defp result_artifact_embedded_manifests(mission_state, opts) do
    callbacks = callbacks!(opts)

    cadence_import_manifest_keys()
    |> Enum.flat_map(fn manifest_key ->
      callbacks.result_artifact_embedded_reports.(mission_state, manifest_key)
    end)
  end

  defp cadence_import_manifest_keys do
    ["source_cadence_import_manifest", "cadence_import_manifest"]
  end

  defp rows(manifests_with_sources, opts) do
    manifests_with_sources
    |> rows_with_source(opts)
    |> Enum.map(fn {row, _source_path} -> row end)
  end

  defp callbacks!(opts) do
    %{
      source_artifact_entries: Keyword.fetch!(opts, :source_artifact_entries),
      result_artifact_embedded_reports: Keyword.fetch!(opts, :result_artifact_embedded_reports)
    }
  end

  defp prior_plan_callbacks!(opts) do
    %{
      result_artifacts_with_source: Keyword.fetch!(opts, :result_artifacts_with_source)
    }
  end

  defp stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: encode_value(value)

  defp encode_value(%_{} = struct), do: struct |> Map.from_struct() |> encode_value()

  defp encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  defp encode_value(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_value(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value), do: value
end
