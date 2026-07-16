defmodule OrbitalDynamics.CampaignPlanner.CadenceImportSourceReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{
    BranchRefreshSourceInputs,
    CadenceImportFeedbackRows,
    OperationalFeedbackNormalization,
    OperationalFeedbackSourceMetadata,
    SourceReportArtifacts
  }

  alias __MODULE__.Rows

  def cadence_import_manifests(mission_state),
    do: cadence_import_manifests(mission_state, default_callbacks())

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

  def cadence_import_manifest_reports(mission_state, manifest_key) do
    cadence_import_manifest_reports(mission_state, manifest_key, default_callbacks())
  end

  def cadence_import_manifest_reports(mission_state, "source_cadence_import_manifest", opts) do
    source_cadence_import_manifests(mission_state, opts)
  end

  def cadence_import_manifest_reports(mission_state, "cadence_import_manifest", opts) do
    canonical_cadence_import_manifests(mission_state, opts)
  end

  def candidate_refresh_source_inputs(mission_state) do
    Map.new(candidate_refresh_source_input_collectors(), fn {key, collector} ->
      {key, BranchRefreshSourceInputs.source_reports_or_reports(mission_state, collector)}
    end)
  end

  def prior_plan_cadence_import_manifests(prior_plan, opts \\ default_prior_plan_callbacks())
      when is_list(opts) do
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
    SourceReportArtifacts.direct_entries(artifacts, source_path, opts)
  end

  def result_artifact_embedded_cadence_import_manifests(artifacts_with_sources, opts)
      when is_list(opts) do
    SourceReportArtifacts.result_artifact_embedded_entries(
      artifacts_with_sources,
      cadence_import_manifest_keys(),
      opts
    )
  end

  def rows_with_source(manifests_with_sources), do: Rows.rows_with_source(manifests_with_sources)

  def rows_with_source(manifests_with_sources, opts) when is_list(opts) do
    Rows.rows_with_source(manifests_with_sources, opts)
  end

  def pressure_rows_with_source(manifests_with_sources),
    do: Rows.pressure_rows_with_source(manifests_with_sources)

  def pressure_rows_with_source(manifests_with_sources, opts) when is_list(opts) do
    Rows.pressure_rows_with_source(manifests_with_sources, opts)
  end

  def source_review_rows(manifests_with_sources) do
    manifests_with_sources
    |> rows()
    |> CadenceImportFeedbackRows.source_review_rows()
  end

  def source_review_rows(manifests_with_sources, opts) when is_list(opts) do
    manifests_with_sources
    |> rows(opts)
    |> CadenceImportFeedbackRows.source_review_rows()
  end

  def all_operational_feedback_rows(manifests_with_sources) do
    manifests_with_sources
    |> rows()
    |> CadenceImportFeedbackRows.all_operational_feedback_rows()
  end

  def all_operational_feedback_rows(manifests_with_sources, opts) when is_list(opts) do
    manifests_with_sources
    |> rows(opts)
    |> CadenceImportFeedbackRows.all_operational_feedback_rows()
  end

  def operational_feedback_rows(manifests_with_sources) do
    manifests_with_sources
    |> all_operational_feedback_rows()
    |> Enum.filter(fn row ->
      case Map.get(row, "source_operational_feedback") do
        %{} = feedback -> operational_feedback_data_keys(feedback) != []
        _feedback -> false
      end
    end)
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

  def source_review_metadata(manifests_with_sources) do
    manifests_with_sources
    |> source_review_rows()
    |> CadenceImportFeedbackRows.source_review_metadata()
  end

  def source_review_metadata(manifests_with_sources, opts) when is_list(opts) do
    manifests_with_sources
    |> source_review_rows(opts)
    |> CadenceImportFeedbackRows.source_review_metadata()
  end

  def source_operational_feedback_metadata(manifests_with_sources) do
    manifests_with_sources
    |> all_operational_feedback_rows()
    |> CadenceImportFeedbackRows.source_operational_feedback_metadata()
  end

  def source_operational_feedback_metadata(manifests_with_sources, opts) when is_list(opts) do
    manifests_with_sources
    |> all_operational_feedback_rows(opts)
    |> CadenceImportFeedbackRows.source_operational_feedback_metadata()
  end

  defp source_artifacts(mission_state, fields, opts) do
    SourceReportArtifacts.source_artifacts(mission_state, fields, opts, &stringify_keys/1)
  end

  defp result_artifact_embedded_manifests(mission_state, opts) do
    cadence_import_manifest_keys()
    |> Enum.flat_map(fn manifest_key ->
      SourceReportArtifacts.embedded_reports(mission_state, manifest_key, opts)
    end)
  end

  defp default_callbacks do
    [
      source_artifact_entries: &BranchRefreshSourceInputs.source_artifact_entries/2,
      result_artifact_embedded_reports: &mission_state_result_artifact_embedded_reports/2
    ]
  end

  defp mission_state_result_artifact_embedded_reports(mission_state, manifest_keys) do
    BranchRefreshSourceInputs.result_artifact_embedded_reports(
      mission_state,
      "mission_state",
      manifest_keys
    )
  end

  defp default_prior_plan_callbacks do
    [
      source_artifact_entries: &BranchRefreshSourceInputs.source_artifact_entries/2,
      result_artifacts_with_source: &prior_plan_result_artifacts_with_source/1,
      result_artifact_embedded_report_entries:
        &BranchRefreshSourceInputs.result_artifact_embedded_report_entries/3
    ]
  end

  defp prior_plan_result_artifacts_with_source(prior_plan) do
    BranchRefreshSourceInputs.result_artifacts_with_source(prior_plan, "prior_plan")
  end

  defp cadence_import_manifest_keys do
    ["source_cadence_import_manifest", "cadence_import_manifest"]
  end

  defp candidate_refresh_source_input_collectors,
    do: [
      {"source_cadence_import_manifest",
       &cadence_import_manifest_reports(&1, "source_cadence_import_manifest")},
      {"cadence_import_manifest", &cadence_import_manifest_reports(&1, "cadence_import_manifest")}
    ]

  defp rows(manifests_with_sources, opts) do
    Rows.rows(manifests_with_sources, opts)
  end

  defp rows(manifests_with_sources), do: Rows.rows(manifests_with_sources)

  defp operational_feedback_data_keys(feedback) do
    OperationalFeedbackSourceMetadata.data_keys(
      feedback,
      normalize_operational_feedback: &OperationalFeedbackNormalization.normalize/1
    )
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
