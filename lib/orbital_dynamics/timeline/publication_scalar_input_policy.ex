defmodule OrbitalDynamics.Timeline.PublicationScalarInputPolicy do
  @moduledoc false

  def publication_source_artifact_type(source_artifact, encode_value) do
    [
      source_artifact["schema_contract"],
      source_artifact["artifact_type"],
      source_artifact["model"]
    ]
    |> Enum.map(encode_value)
    |> Enum.find(&(&1 not in [nil, ""]))
    |> case do
      nil -> "unknown_artifact"
      value -> value
    end
  end

  def publication_sequence!(opts) do
    case Keyword.get(opts, :publication_sequence, Keyword.get(opts, :sequence, 1)) do
      value when is_integer(value) and value >= 0 ->
        value

      value when is_binary(value) ->
        case Integer.parse(value) do
          {integer, ""} when integer >= 0 -> integer
          _parsed -> raise ArgumentError, "publication_sequence must be a non-negative integer"
        end

      _value ->
        raise ArgumentError, "publication_sequence must be a non-negative integer"
    end
  end
end
