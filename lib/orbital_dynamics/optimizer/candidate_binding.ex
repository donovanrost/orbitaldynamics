defmodule OrbitalDynamics.Optimizer.CandidateBinding do
  @moduledoc false

  @schema_contract "local_search_candidate_binding.v1"
  @algorithm "erlang_term_to_binary_deterministic_sha256.v1"
  @stable_id ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/
  @sha256 ~r/^[0-9a-f]{64}$/
  @max_float 1.7976931348623157e308
  @fields ~w(schema_contract alternative_id parameter_revision parameter_content_identity)

  def schema_contract, do: @schema_contract
  def algorithm, do: @algorithm

  def build(alternative_id, parameter_revision, parameters) do
    normalize!(%{
      "schema_contract" => @schema_contract,
      "alternative_id" => alternative_id,
      "parameter_revision" => parameter_revision,
      "parameter_content_identity" => parameter_content_identity(parameters)
    })
  end

  def parameter_content_identity(parameters) when is_map(parameters) do
    parameters = stringify!(parameters, "parameters")

    unless map_size(parameters) > 0 and
             Enum.all?(parameters, fn {key, value} ->
               Regex.match?(~r/^[A-Za-z][A-Za-z0-9_.-]*$/, key) and finite?(value)
             end) do
      raise ArgumentError, "parameters must be a non-empty finite numeric map"
    end

    digest =
      parameters
      |> :erlang.term_to_binary([:deterministic])
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)

    %{"algorithm" => @algorithm, "sha256" => digest}
  end

  def parameter_content_identity(_parameters),
    do: raise(ArgumentError, "parameters must be a non-empty finite numeric map")

  def normalize!(binding) when is_map(binding) do
    binding = stringify!(binding, "candidate_binding")

    if Enum.sort(Map.keys(binding)) != Enum.sort(@fields) do
      raise ArgumentError, "candidate_binding must contain exactly #{inspect(@fields)}"
    end

    require_equal!(binding["schema_contract"], @schema_contract, "schema_contract")
    non_blank!(binding["alternative_id"], "alternative_id")

    unless Regex.match?(@stable_id, binding["parameter_revision"] || "") do
      raise ArgumentError, "candidate_binding.parameter_revision must be a stable identity"
    end

    validate_content_identity!(binding["parameter_content_identity"])
    binding
  end

  def normalize!(_binding), do: raise(ArgumentError, "candidate_binding must be a map")

  def optional_from_container!(container) when is_map(container) do
    values =
      [:candidate_binding, "candidate_binding"]
      |> Enum.flat_map(fn key ->
        case Map.fetch(container, key) do
          {:ok, value} -> [value]
          :error -> []
        end
      end)

    case values do
      [] -> nil
      [binding] -> normalize!(binding)
      _values -> raise ArgumentError, "candidate_binding has duplicate normalized keys"
    end
  end

  def json_schema do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "required" => @fields,
      "properties" => %{
        "schema_contract" => %{"type" => "string", "const" => @schema_contract},
        "alternative_id" => %{"type" => "string", "minLength" => 1},
        "parameter_revision" => %{
          "type" => "string",
          "pattern" => "^[A-Za-z0-9][A-Za-z0-9._:@-]*$"
        },
        "parameter_content_identity" => %{
          "type" => "object",
          "additionalProperties" => false,
          "required" => ["algorithm", "sha256"],
          "properties" => %{
            "algorithm" => %{"type" => "string", "const" => @algorithm},
            "sha256" => %{"type" => "string", "pattern" => "^[0-9a-f]{64}$"}
          }
        }
      }
    }
  end

  defp validate_content_identity!(%{"algorithm" => @algorithm, "sha256" => digest} = identity)
       when map_size(identity) == 2 and is_binary(digest) do
    unless Regex.match?(@sha256, digest) do
      raise ArgumentError, "candidate_binding parameter SHA-256 must be lowercase hexadecimal"
    end
  end

  defp validate_content_identity!(_identity) do
    raise ArgumentError,
          "candidate_binding parameter content identity must declare the supported algorithm and SHA-256"
  end

  defp non_blank!(value, field) when is_binary(value) do
    if String.trim(value) == "",
      do: raise(ArgumentError, "candidate_binding.#{field} must be non-empty")
  end

  defp non_blank!(_value, field),
    do: raise(ArgumentError, "candidate_binding.#{field} must be non-empty")

  defp require_equal!(actual, expected, field) do
    unless actual == expected,
      do: raise(ArgumentError, "candidate_binding.#{field} must equal #{inspect(expected)}")
  end

  defp stringify!(map, label) when is_map(map) and not is_struct(map) do
    entries = Enum.map(map, fn {key, value} -> {key!(key, label), stringify!(value, label)} end)
    keys = Enum.map(entries, &elem(&1, 0))

    if length(keys) != length(Enum.uniq(keys)),
      do: raise(ArgumentError, "#{label} contains duplicate keys after key normalization")

    Map.new(entries)
  end

  defp stringify!(value, _label)
       when is_binary(value) or is_boolean(value) or is_nil(value),
       do: value

  defp stringify!(value, _label) when is_atom(value), do: Atom.to_string(value)

  defp stringify!(value, label) when is_number(value) do
    if finite?(value),
      do: value,
      else: raise(ArgumentError, "#{label} contains a non-finite number")
  end

  defp stringify!(_value, label),
    do: raise(ArgumentError, "#{label} must contain only JSON-safe finite scalar values")

  defp key!(key, _label) when is_atom(key), do: Atom.to_string(key)
  defp key!(key, _label) when is_binary(key), do: key
  defp key!(_key, label), do: raise(ArgumentError, "#{label} keys must be atoms or strings")

  defp finite?(value) when is_number(value),
    do: value == value and value <= @max_float and value >= -@max_float

  defp finite?(_value), do: false
end
