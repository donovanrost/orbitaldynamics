defmodule OrbitalDynamics.CampaignPlanner.OperatorReviewSourceReports do
  @moduledoc false

  def operator_review_packages(mission_state, opts) do
    source_operator_review_packages(mission_state, opts) ++
      canonical_operator_review_packages(mission_state, opts) ++
      result_artifact_embedded_packages(mission_state, opts)
  end

  def source_operator_review_packages(mission_state, opts) do
    source_artifacts(
      mission_state,
      [
        {"source_operator_review_package", "mission_state.source_operator_review_package"}
      ],
      opts
    )
  end

  def canonical_operator_review_packages(mission_state, opts) do
    source_artifacts(
      mission_state,
      [
        {"operator_review_package", "mission_state.operator_review_package"}
      ],
      opts
    )
  end

  def operator_review_package_reports(mission_state, "source_operator_review_package", opts) do
    source_operator_review_packages(mission_state, opts)
  end

  def operator_review_package_reports(mission_state, "operator_review_package", opts) do
    canonical_operator_review_packages(mission_state, opts)
  end

  def prior_plan_operator_review_packages(prior_plan, opts) when is_list(opts) do
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
    source_artifact_entries = Keyword.fetch!(opts, :source_artifact_entries)

    source_artifact_entries.(artifacts, source_path)
  end

  def result_artifact_embedded_operator_review_packages(artifacts_with_sources, opts)
      when is_list(opts) do
    result_artifact_embedded_report_entries =
      Keyword.fetch!(opts, :result_artifact_embedded_report_entries)

    artifacts_with_sources
    |> Enum.flat_map(fn {artifact, source_path} ->
      operator_review_package_keys()
      |> Enum.flat_map(fn package_key ->
        result_artifact_embedded_report_entries.(
          Map.get(artifact, package_key),
          artifact,
          "#{source_path}.#{package_key}"
        )
      end)
    end)
  end

  def rows_with_source(packages_with_sources, opts) when is_list(opts) do
    stringify_keys = Keyword.fetch!(opts, :stringify_keys)
    put_if_absent = Keyword.fetch!(opts, :put_if_absent)

    packages_with_sources
    |> Enum.flat_map(fn {package, source_path} ->
      trust_boundary =
        Map.get(package, "trust_boundary") || get_in(package, ["provenance", "trust_boundary"])

      package
      |> Map.get("rows", [])
      |> Enum.map(stringify_keys)
      |> Enum.map(fn row ->
        row =
          row
          |> put_if_absent.("trust_boundary", trust_boundary)
          |> Map.put("_source_report_trust_boundary", trust_boundary)
          |> Map.put("_source_path", "#{source_path}.rows")

        {row, source_path}
      end)
    end)
  end

  def rows(packages_with_sources, opts) when is_list(opts) do
    packages_with_sources
    |> rows_with_source(opts)
    |> Enum.map(fn {row, _source_path} -> row end)
  end

  def all_operational_feedback_rows(packages_with_sources, opts) when is_list(opts) do
    packages_with_sources
    |> rows(opts)
    |> Enum.filter(&Map.has_key?(&1, "source_operational_feedback"))
  end

  def operational_feedback_rows(packages_with_sources, opts) when is_list(opts) do
    operational_feedback_data_keys = Keyword.fetch!(opts, :operational_feedback_data_keys)

    packages_with_sources
    |> all_operational_feedback_rows(opts)
    |> Enum.filter(fn row ->
      case Map.get(row, "source_operational_feedback") do
        %{} = feedback -> operational_feedback_data_keys.(feedback) != []
        _feedback -> false
      end
    end)
  end

  def source_operational_feedback_metadata(rows_or_packages, packages_or_opts)
      when is_list(packages_or_opts) do
    if row_source_opts?(packages_or_opts) do
      packages_with_sources = rows_or_packages
      rows = all_operational_feedback_rows(packages_with_sources, packages_or_opts)

      source_operational_feedback_metadata_from_rows(rows, fn ->
        package_source_report_count(rows, packages_with_sources)
      end)
    else
      rows = rows_or_packages
      packages_with_sources = packages_or_opts

      source_operational_feedback_metadata_from_rows(rows, fn ->
        package_source_report_count(rows, packages_with_sources)
      end)
    end
  end

  def source_operational_feedback_metadata(rows, fallback_count_fun)
      when is_function(fallback_count_fun, 0) do
    source_operational_feedback_metadata_from_rows(rows, fallback_count_fun)
  end

  defp source_operational_feedback_metadata_from_rows(rows, fallback_count_fun) do
    source_report_paths = source_paths(rows)

    %{
      "source_report_contract" => "operator_review_package.v1",
      "source_report_count" => source_report_count(rows, source_report_paths, fallback_count_fun),
      "source_report_paths" => if(source_report_paths == [], do: nil, else: source_report_paths),
      "source_report_row_count" => length(rows),
      "source_review_type_counts" => count_present_values(rows, "review_type"),
      "source_review_action_counts" =>
        count_present_values(rows, ["action", "required_operator_action"]),
      "source_operational_feedback_provenance" => source_operational_feedback_provenance(rows),
      "trust_boundary_status" => trust_boundary_status(rows),
      "trust_boundaries" => trust_boundaries(rows)
    }
    |> compact_map()
  end

  def package_source_report_count([], _packages_with_sources), do: 0

  def package_source_report_count(_rows, packages_with_sources)
      when is_list(packages_with_sources),
      do: length(packages_with_sources)

  def source_metadata(rows, source_report_contract, opts) do
    callbacks = metadata_callbacks!(opts)
    feedback_weight_rows = Enum.map(rows, callbacks.feedback_weight_evidence)
    weighted_feedback_row_count = callbacks.weighted_feedback_row_count.(feedback_weight_rows)
    feedback_weight_sources = callbacks.feedback_weight_sources.(feedback_weight_rows)
    invalid_sections = callbacks.invalid_unit_interval_feedback_sections.(rows)
    source_report_paths = source_paths(rows)

    %{
      "source_report_contract" => source_report_contract,
      "source_report_count" => source_report_count(rows, source_report_paths),
      "source_report_paths" => if(source_report_paths == [], do: nil, else: source_report_paths),
      "source_report_row_count" => length(rows),
      "source_review_type_counts" => count_present_values(rows, "review_type"),
      "source_review_action_counts" =>
        count_present_values(rows, ["action", "required_operator_action"]),
      "source_review_queue_counts" =>
        count_present_values(rows, ["review_queue_key", "review_queue"]),
      "weighted_feedback_row_count" =>
        if(weighted_feedback_row_count > 0, do: weighted_feedback_row_count),
      "feedback_weight_sources" =>
        if(feedback_weight_sources == [], do: nil, else: feedback_weight_sources),
      "invalid_operational_feedback_sections" =>
        if(invalid_sections == [], do: nil, else: invalid_sections),
      "trust_boundary_status" => review_trust_boundary_status(rows),
      "trust_boundaries" => review_trust_boundaries(rows)
    }
    |> compact_map()
  end

  def source_metadata_from_packages(packages_with_sources, source_report_contract, row_opts, opts)
      when is_list(row_opts) and is_list(opts) do
    packages_with_sources
    |> rows(row_opts)
    |> source_metadata(source_report_contract, opts)
  end

  defp source_artifacts(mission_state, fields, opts) do
    mission_state = stringify_keys(mission_state || %{})

    fields
    |> Enum.flat_map(fn {field, source_path} ->
      direct_operator_review_packages(Map.get(mission_state, field), source_path, opts)
    end)
  end

  defp result_artifact_embedded_packages(mission_state, opts) do
    callbacks = callbacks!(opts)

    operator_review_package_keys()
    |> Enum.flat_map(fn package_key ->
      callbacks.result_artifact_embedded_reports.(mission_state, package_key)
    end)
  end

  defp operator_review_package_keys do
    ["source_operator_review_package", "operator_review_package"]
  end

  defp row_source_opts?(opts) do
    Keyword.keyword?(opts) and
      Keyword.has_key?(opts, :stringify_keys) and
      Keyword.has_key?(opts, :put_if_absent)
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

  defp metadata_callbacks!(opts) do
    %{
      feedback_weight_evidence: Keyword.fetch!(opts, :feedback_weight_evidence),
      weighted_feedback_row_count: Keyword.fetch!(opts, :weighted_feedback_row_count),
      feedback_weight_sources: Keyword.fetch!(opts, :feedback_weight_sources),
      invalid_unit_interval_feedback_sections:
        Keyword.fetch!(opts, :invalid_unit_interval_feedback_sections)
    }
  end

  defp source_report_count([], _source_report_paths), do: 0
  defp source_report_count(_rows, []), do: 1
  defp source_report_count(_rows, source_report_paths), do: length(source_report_paths)

  defp source_report_count([], _source_report_paths, _fallback_count_fun), do: 0

  defp source_report_count(_rows, source_report_paths, _fallback_count_fun)
       when source_report_paths != [],
       do: length(source_report_paths)

  defp source_report_count(_rows, _source_report_paths, fallback_count_fun),
    do: fallback_count_fun.()

  defp source_paths(rows) do
    rows
    |> Enum.map(&Map.get(&1, "_source_path"))
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp count_present_values(rows, fields) when is_list(fields) do
    rows
    |> Enum.map(fn row ->
      Enum.find_value(fields, fn field ->
        case Map.get(row, field) do
          value when value in [nil, ""] -> nil
          value -> value
        end
      end)
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> case do
      counts when counts == %{} -> nil
      counts -> counts
    end
  end

  defp count_present_values(rows, field), do: count_present_values(rows, [field])

  defp source_operational_feedback_provenance(rows) do
    rows
    |> Enum.map(&Map.get(&1, "source_operational_feedback_provenance"))
    |> Enum.filter(&is_map/1)
    |> case do
      [] -> nil
      [provenance] -> provenance
      provenances -> %{"sources" => provenances, "source_count" => length(provenances)}
    end
  end

  defp trust_boundary_status(rows) do
    case trust_boundaries(rows) do
      [] -> nil
      _boundaries -> "declared"
    end
  end

  defp trust_boundaries(rows) do
    rows
    |> Enum.flat_map(fn row ->
      [
        row["operational_feedback_trust_boundary"],
        row["trust_boundary"],
        get_in(row, ["provenance", "trust_boundary"]),
        operational_feedback_provenance_trust_boundaries(
          row["source_operational_feedback_provenance"]
        )
      ]
      |> List.flatten()
    end)
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp review_trust_boundary_status(rows) do
    case review_trust_boundaries(rows) do
      boundaries when is_list(boundaries) and boundaries != [] -> "declared"
      _boundaries -> nil
    end
  end

  defp review_trust_boundaries(rows) do
    rows
    |> Enum.flat_map(fn row ->
      [
        row["trust_boundary"],
        get_in(row, ["provenance", "trust_boundary"]),
        row["_source_report_trust_boundary"]
      ]
    end)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
    |> case do
      [] -> nil
      boundaries -> boundaries
    end
  end

  defp operational_feedback_provenance_trust_boundaries(%{} = provenance) do
    provenance = stringify_keys(provenance)

    direct_boundaries = [
      Map.get(provenance, "trust_boundary"),
      Map.get(provenance, "trust_boundaries")
    ]

    nested_boundaries =
      provenance
      |> Map.get("sources", [])
      |> List.wrap()
      |> Enum.flat_map(fn
        %{} = source ->
          source = stringify_keys(source)

          [
            source["trust_boundary"],
            source["trust_boundaries"]
          ]
          |> List.flatten()

        _source ->
          []
      end)

    (direct_boundaries ++ nested_boundaries)
    |> List.flatten()
    |> Enum.filter(&(is_binary(&1) and &1 != ""))
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp operational_feedback_provenance_trust_boundaries(_provenance), do: []

  defp compact_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
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
