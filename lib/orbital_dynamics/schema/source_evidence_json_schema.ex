defmodule OrbitalDynamics.Schema.SourceEvidenceJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

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
