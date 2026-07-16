defmodule OrbitalDynamics.CampaignPlanner.OperatorReviewSourceReports do
  @moduledoc false

  alias OrbitalDynamics.CampaignPlanner.{BranchRefreshSourceInputs, SourceReportArtifacts}

  alias __MODULE__.Rows
  alias __MODULE__.SourceMetadata

  def operator_review_packages(mission_state, opts \\ default_callbacks()) do
    source_operator_review_packages(mission_state, opts) ++
      canonical_operator_review_packages(mission_state, opts) ++
      result_artifact_embedded_packages(mission_state, opts)
  end

  def source_operator_review_packages(mission_state, opts \\ default_callbacks()) do
    source_artifacts(
      mission_state,
      [
        {"source_operator_review_package", "mission_state.source_operator_review_package"}
      ],
      opts
    )
  end

  def canonical_operator_review_packages(mission_state, opts \\ default_callbacks()) do
    source_artifacts(
      mission_state,
      [
        {"operator_review_package", "mission_state.operator_review_package"}
      ],
      opts
    )
  end

  def operator_review_package_reports(
        mission_state,
        package_key,
        opts \\ default_callbacks()
      )

  def operator_review_package_reports(mission_state, "source_operator_review_package", opts) do
    source_operator_review_packages(mission_state, opts)
  end

  def operator_review_package_reports(mission_state, "operator_review_package", opts) do
    canonical_operator_review_packages(mission_state, opts)
  end

  def candidate_refresh_source_inputs(mission_state) do
    Map.new(candidate_refresh_source_input_collectors(), fn {key, collector} ->
      {key, BranchRefreshSourceInputs.source_reports_or_reports(mission_state, collector)}
    end)
  end

  def prior_plan_operator_review_packages(prior_plan, opts \\ default_prior_plan_callbacks())
      when is_list(opts) do
    prior_plan = stringify_keys(prior_plan || %{})
    callbacks = prior_plan_callbacks!(opts)

    prior_plan_operator_review_packages(
      prior_plan,
      callbacks.result_artifacts_with_source.(prior_plan),
      opts
    )
  end

  def prior_plan_operator_review_packages(prior_plan, artifacts_with_sources, opts)
      when is_list(artifacts_with_sources) and is_list(opts) do
    direct_operator_review_packages(
      Map.get(prior_plan, "operator_review_package"),
      "prior_plan.operator_review_package",
      opts
    ) ++ result_artifact_embedded_operator_review_packages(artifacts_with_sources, opts)
  end

  def direct_operator_review_packages(artifacts, source_path, opts) when is_list(opts) do
    SourceReportArtifacts.direct_entries(artifacts, source_path, opts)
  end

  def result_artifact_embedded_operator_review_packages(artifacts_with_sources, opts)
      when is_list(opts) do
    SourceReportArtifacts.result_artifact_embedded_entries(
      artifacts_with_sources,
      operator_review_package_keys(),
      opts
    )
  end

  def rows_with_source(packages_with_sources), do: Rows.rows_with_source(packages_with_sources)

  def rows_with_source(packages_with_sources, opts) when is_list(opts) do
    Rows.rows_with_source(packages_with_sources, opts)
  end

  def pressure_rows_with_source(packages_with_sources),
    do: Rows.pressure_rows_with_source(packages_with_sources)

  def pressure_rows_with_source(packages_with_sources, opts) when is_list(opts) do
    Rows.pressure_rows_with_source(packages_with_sources, opts)
  end

  def rows(packages_with_sources), do: Rows.rows(packages_with_sources)

  def rows(packages_with_sources, opts) when is_list(opts) do
    Rows.rows(packages_with_sources, opts)
  end

  def all_operational_feedback_rows(packages_with_sources),
    do: Rows.all_operational_feedback_rows(packages_with_sources)

  def all_operational_feedback_rows(packages_with_sources, opts) when is_list(opts) do
    Rows.all_operational_feedback_rows(packages_with_sources, opts)
  end

  def operational_feedback_rows(packages_with_sources),
    do: Rows.operational_feedback_rows(packages_with_sources)

  def operational_feedback_rows(packages_with_sources, opts) when is_list(opts) do
    Rows.operational_feedback_rows(packages_with_sources, opts)
  end

  def source_operational_feedback_metadata(packages_with_sources) do
    SourceMetadata.source_operational_feedback_metadata(packages_with_sources)
  end

  def source_operational_feedback_metadata(rows_or_packages, packages_or_opts)
      when is_list(packages_or_opts) do
    SourceMetadata.source_operational_feedback_metadata(rows_or_packages, packages_or_opts)
  end

  def source_operational_feedback_metadata(rows, fallback_count_fun)
      when is_function(fallback_count_fun, 0) do
    SourceMetadata.source_operational_feedback_metadata(rows, fallback_count_fun)
  end

  def package_source_report_count(rows, packages_with_sources) do
    SourceMetadata.package_source_report_count(rows, packages_with_sources)
  end

  def source_metadata(rows, source_report_contract, opts) do
    SourceMetadata.source_metadata(rows, source_report_contract, opts)
  end

  def source_metadata_from_packages(packages_with_sources, source_report_contract) do
    SourceMetadata.source_metadata_from_packages(packages_with_sources, source_report_contract)
  end

  def source_metadata_from_packages(packages_with_sources, source_report_contract, row_opts, opts)
      when is_list(row_opts) and is_list(opts) do
    SourceMetadata.source_metadata_from_packages(
      packages_with_sources,
      source_report_contract,
      row_opts,
      opts
    )
  end

  def source_metadata_from_packages(packages_with_sources, source_report_contract, row_opts)
      when is_list(row_opts) do
    SourceMetadata.source_metadata_from_packages(
      packages_with_sources,
      source_report_contract,
      row_opts
    )
  end

  defp source_artifacts(mission_state, fields, opts) do
    SourceReportArtifacts.source_artifacts(mission_state, fields, opts, &stringify_keys/1)
  end

  defp result_artifact_embedded_packages(mission_state, opts) do
    operator_review_package_keys()
    |> Enum.flat_map(fn package_key ->
      SourceReportArtifacts.embedded_reports(mission_state, package_key, opts)
    end)
  end

  defp operator_review_package_keys do
    ["source_operator_review_package", "operator_review_package"]
  end

  defp candidate_refresh_source_input_collectors,
    do: [
      {"source_operator_review_package",
       &operator_review_package_reports(&1, "source_operator_review_package")},
      {"operator_review_package", &operator_review_package_reports(&1, "operator_review_package")}
    ]

  defp default_callbacks do
    [
      source_artifact_entries: &BranchRefreshSourceInputs.source_artifact_entries/2,
      result_artifact_embedded_reports: &mission_state_result_artifact_embedded_reports/2
    ]
  end

  defp mission_state_result_artifact_embedded_reports(mission_state, report_keys) do
    BranchRefreshSourceInputs.result_artifact_embedded_reports(
      mission_state,
      "mission_state",
      report_keys
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
