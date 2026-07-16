defmodule OrbitalDynamics.Schema.RealizedStateSnapshotJsonSchema do
  @moduledoc false

  @property_fields [
    "activities",
    "spacecraft_states",
    "metadata",
    "model_limits"
  ]

  def property_field?(field) when field in @property_fields, do: true
  def property_field?(_field), do: false

  def property_fun_from_context(deps) when is_list(deps) do
    fn field ->
      property(field, property_opts(field, deps))
    end
  end

  def property_opts("activities", deps) do
    [realized_activity_schema: fetch_dep!(deps, :realized_activity_schema)]
  end

  def property_opts("spacecraft_states", deps) do
    [realized_spacecraft_state_schema: fetch_dep!(deps, :realized_spacecraft_state_schema)]
  end

  def property_opts("metadata", deps) do
    [metadata_schema: fetch_dep!(deps, :metadata_schema)]
  end

  def property_opts("model_limits", deps) do
    [model_limits: fetch_dep!(deps, :model_limits)]
  end

  def property_opts(_field, _deps), do: []

  def property("activities", opts) do
    array_of(Keyword.fetch!(opts, :realized_activity_schema))
  end

  def property("spacecraft_states", opts) do
    array_of(Keyword.fetch!(opts, :realized_spacecraft_state_schema))
  end

  def property("metadata", opts) do
    Keyword.fetch!(opts, :metadata_schema)
  end

  def property("model_limits", opts) do
    %{
      "type" => "array",
      "items" => %{"type" => "string", "enum" => Keyword.fetch!(opts, :model_limits)}
    }
  end

  def metadata(opts) do
    stable_id_pattern = Keyword.fetch!(opts, :stable_id_pattern)

    %{
      "type" => "object",
      "additionalProperties" => true,
      "properties" => %{
        "snapshot_id" => %{"type" => "string"},
        "mission_state_id" => %{"type" => "string"},
        "captured_at" => %{"type" => "string"},
        "source" => %{"type" => "string"},
        "feedback_boundary" => %{"type" => "string"},
        "provider" => %{"type" => "string"},
        "adapter" => %{"type" => "string"},
        "adapter_version" => %{"type" => "string"},
        "external_id" => %{"type" => "string", "pattern" => stable_id_pattern},
        "trust_boundary" => %{"type" => "string"},
        "received_at" => %{"type" => "string"},
        "ingested_at" => %{"type" => "string"},
        "dropped_identityless_spacecraft_state_count" => %{"type" => "integer"},
        "dropped_invalid_identity_spacecraft_state_count" => %{"type" => "integer"},
        "provenance" => %{
          "type" => "object",
          "additionalProperties" => true,
          "properties" => %{"trust_boundary" => %{"type" => "string"}}
        }
      },
      "allOf" => [
        %{
          "if" => %{
            "anyOf" => [
              %{"required" => ["provider"]},
              %{"required" => ["adapter"]},
              %{"required" => ["adapter_version"]},
              %{"required" => ["external_id"]}
            ]
          },
          "then" => %{
            "anyOf" => [
              %{"required" => ["trust_boundary"]},
              %{
                "required" => ["provenance"],
                "properties" => %{
                  "provenance" => %{
                    "type" => "object",
                    "required" => ["trust_boundary"],
                    "properties" => %{"trust_boundary" => %{"type" => "string"}},
                    "additionalProperties" => true
                  }
                }
              }
            ]
          }
        }
      ]
    }
  end

  defp array_of(item_schema) do
    %{
      "type" => "array",
      "items" => item_schema
    }
  end

  defp fetch_dep!(deps, key) do
    case Keyword.fetch!(deps, key) do
      fun when is_function(fun, 0) -> fun.()
      value -> value
    end
  end
end
