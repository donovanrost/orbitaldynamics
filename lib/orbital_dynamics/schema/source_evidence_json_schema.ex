defmodule OrbitalDynamics.Schema.SourceEvidenceJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.OperationalReadiness
  alias OrbitalDynamics.Schema.CommonJsonSchema
  alias OrbitalDynamics.Schema.SourceEvidenceContracts

  def source_evidence(deps) do
    deps
    |> source_evidence_opts()
    |> base()
  end

  def source_evidence_from_context(stable_id_pattern, battery_handoff_properties) do
    stable_id_pattern
    |> source_evidence_opts_from_context(battery_handoff_properties)
    |> base()
  end

  def operational_readiness_source_report(deps) do
    deps
    |> readiness_report_opts()
    |> operational_readiness_report()
  end

  def operational_readiness_source_report_from_context(
        stable_id_pattern,
        battery_handoff_properties
      ) do
    stable_id_pattern
    |> readiness_report_opts_from_context(battery_handoff_properties)
    |> operational_readiness_report()
  end

  def quality_gate_source_report(deps) do
    deps
    |> quality_gate_report_opts()
    |> quality_gate_report()
  end

  def quality_gate_source_report_from_context(
        stable_id_pattern,
        battery_handoff_properties,
        count_map_schema,
        stable_id_array_map_schema
      ) do
    stable_id_pattern
    |> quality_gate_report_opts_from_context(
      battery_handoff_properties,
      count_map_schema,
      stable_id_array_map_schema
    )
    |> quality_gate_report()
  end

  def freshness_report(deps, statuses) do
    deps
    |> source_evidence_opts()
    |> with_status(statuses)
  end

  def freshness_report_from_context(stable_id_pattern, battery_handoff_properties, statuses) do
    stable_id_pattern
    |> source_evidence_opts_from_context(battery_handoff_properties)
    |> with_status(statuses)
  end

  def schema_validation_report(deps, statuses) do
    deps
    |> source_evidence_opts()
    |> with_status(statuses)
  end

  def schema_validation_report_from_context(
        stable_id_pattern,
        battery_handoff_properties,
        statuses
      ) do
    stable_id_pattern
    |> source_evidence_opts_from_context(battery_handoff_properties)
    |> with_status(statuses)
  end

  def execution_report(deps, statuses) do
    deps
    |> source_evidence_opts()
    |> with_status(statuses)
  end

  def execution_report_from_context(stable_id_pattern, battery_handoff_properties, statuses) do
    stable_id_pattern
    |> source_evidence_opts_from_context(battery_handoff_properties)
    |> with_status(statuses)
  end

  def base(opts) do
    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" =>
        opts.stable_id_fields
        |> stable_id_properties(opts.stable_id_pattern)
        |> Map.merge(
          stable_id_list_properties(opts.stable_id_list_fields, opts.stable_id_pattern)
        )
        |> Map.merge(probability_properties(opts.probability_fields))
        |> Map.merge(opts.battery_handoff_properties)
        |> Map.put("diff_status", %{
          "type" => "string",
          "enum" => ["added", "removed", "changed", "unchanged"]
        })
    }
  end

  def operational_readiness_report(opts) do
    opts
    |> base()
    |> with_properties(%{
      "schema_contract" => %{
        "const" => "operational_readiness_report.v1",
        "type" => "string"
      },
      "source_artifact_type" => %{"type" => "string"},
      "source_artifact_id" => %{"type" => "string", "pattern" => opts.stable_id_pattern},
      "readiness_level" => %{
        "type" => "string",
        "enum" => opts.readiness_levels
      },
      "import_classification" => %{
        "type" => "string",
        "enum" => opts.import_classifications
      },
      "status" => %{
        "type" => "string",
        "enum" => opts.gate_statuses
      },
      "gate_count" => %{"type" => "integer", "minimum" => 0},
      "passed_gate_count" => %{"type" => "integer", "minimum" => 0},
      "review_gate_count" => %{"type" => "integer", "minimum" => 0},
      "analysis_gate_count" => %{"type" => "integer", "minimum" => 0},
      "blocked_gate_count" => %{"type" => "integer", "minimum" => 0}
    })
  end

  def quality_gate_report(opts) do
    opts
    |> operational_readiness_report()
    |> with_properties(%{
      "schema_contract" => %{"const" => "quality_gate_report.v1", "type" => "string"},
      "gate_status_counts" => opts.count_map_schema,
      "gate_classification_counts" => opts.count_map_schema,
      "gate_ids_by_status" => opts.stable_id_array_map_schema,
      "gate_ids_by_classification" => opts.stable_id_array_map_schema,
      "quality_gate_row_ids_by_status" => opts.stable_id_array_map_schema,
      "quality_gate_row_ids_by_classification" => opts.stable_id_array_map_schema
    })
  end

  def with_status(opts, statuses) do
    put_in(base(opts), ["properties", "status"], %{
      "type" => "string",
      "enum" => statuses
    })
  end

  defp with_properties(schema, properties) do
    Map.update!(schema, "properties", &Map.merge(&1, properties))
  end

  defp source_evidence_opts(deps) do
    source_evidence_opts_from_context(deps.stable_id_pattern, deps.battery_handoff_properties)
  end

  defp source_evidence_opts_from_context(stable_id_pattern, battery_handoff_properties) do
    %{
      stable_id_pattern: stable_id_pattern,
      stable_id_fields: SourceEvidenceContracts.stable_id_fields(),
      stable_id_list_fields: SourceEvidenceContracts.stable_id_list_fields(),
      probability_fields: SourceEvidenceContracts.probability_fields(),
      battery_handoff_properties: battery_handoff_properties
    }
  end

  defp readiness_report_opts(deps) do
    readiness_report_opts_from_context(deps.stable_id_pattern, deps.battery_handoff_properties)
  end

  defp readiness_report_opts_from_context(stable_id_pattern, battery_handoff_properties) do
    readiness_capabilities = OperationalReadiness.capabilities()

    stable_id_pattern
    |> source_evidence_opts_from_context(battery_handoff_properties)
    |> Map.merge(%{
      readiness_levels: readiness_capabilities.readiness_levels,
      import_classifications: readiness_capabilities.import_classifications,
      gate_statuses: readiness_capabilities.gate_statuses
    })
  end

  defp quality_gate_report_opts(deps) do
    quality_gate_report_opts_from_context(
      deps.stable_id_pattern,
      deps.battery_handoff_properties,
      deps.count_map_schema,
      deps.stable_id_array_map_schema
    )
  end

  defp quality_gate_report_opts_from_context(
         stable_id_pattern,
         battery_handoff_properties,
         count_map_schema,
         stable_id_array_map_schema
       ) do
    stable_id_pattern
    |> readiness_report_opts_from_context(battery_handoff_properties)
    |> Map.merge(%{
      count_map_schema: count_map_schema,
      stable_id_array_map_schema: stable_id_array_map_schema
    })
  end

  defp stable_id_properties(fields, stable_id_pattern) do
    Map.new(fields, &{&1, %{"type" => "string", "pattern" => stable_id_pattern}})
  end

  defp stable_id_list_properties(fields, stable_id_pattern) do
    Map.new(fields, &{&1, CommonJsonSchema.stable_id_array(stable_id_pattern)})
  end

  defp probability_properties(fields) do
    Map.new(fields, &{&1, CommonJsonSchema.probability()})
  end
end
