defmodule OrbitalDynamics.Schema.CadenceImportManifestJsonSchema do
  @moduledoc false

  alias OrbitalDynamics.Schema.CommonJsonSchema

  @enum_count_fields [
    "import_action_counts",
    "import_status_counts",
    "cadence_import_status_counts",
    "source_review_type_counts"
  ]

  @non_negative_count_map_fields [
    "source_review_action_counts",
    "source_review_queue_counts"
  ]

  def property("source_artifact_type", opts) do
    capability = Keyword.fetch!(opts, :capability)

    %{
      "type" => "string",
      "enum" => capability.supported_sources
    }
  end

  def property("model", _opts) do
    %{
      "type" => "string",
      "const" => "artifact_only_cadence_import_manifest"
    }
  end

  def property("model_limits", opts) do
    model_limits = Keyword.fetch!(opts, :model_limits)

    %{
      "type" => "array",
      "const" => model_limits,
      "items" => %{
        "type" => "string",
        "enum" => model_limits
      }
    }
  end

  def property("rows", opts) do
    %{"type" => "array", "items" => Keyword.fetch!(opts, :row_schema)}
  end

  def property(field, _opts) when field in @non_negative_count_map_fields do
    CommonJsonSchema.non_negative_integer_count_map()
  end

  def property(field, opts) when field in @enum_count_fields do
    opts
    |> Keyword.fetch!(:capability)
    |> enum_count_values(field)
    |> CommonJsonSchema.enum_count_map()
  end

  def property(field, opts) do
    scalar_count_fields = Keyword.fetch!(opts, :scalar_count_fields)

    if field in scalar_count_fields do
      %{"type" => "integer", "minimum" => 0}
    else
      raise ArgumentError, "unknown Cadence import manifest JSON Schema property: #{field}"
    end
  end

  defp enum_count_values(capability, "import_action_counts"), do: capability.import_actions

  defp enum_count_values(capability, "import_status_counts"), do: capability.import_statuses

  defp enum_count_values(capability, "cadence_import_status_counts"),
    do: capability.cadence_import_statuses

  defp enum_count_values(capability, "source_review_type_counts"),
    do: capability.source_review_types
end
