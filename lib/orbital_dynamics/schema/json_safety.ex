defmodule OrbitalDynamics.Schema.JsonSafety do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  @max_float 1.7976931348623157e308

  def normalize_input!(value, label) when is_binary(label),
    do: normalize(value, label)

  def validate_artifact!(value, label) when is_binary(label) do
    case errors(value) do
      [] ->
        value

      [%{"path" => path, "message" => message} | _rest] ->
        raise ArgumentError, "#{label} is not recursively JSON-safe at #{path}: #{message}"
    end
  end

  def errors(value, path \\ "$") do
    value
    |> validate(path, [])
    |> Enum.reverse()
  end

  defp normalize(value, _label) when is_boolean(value), do: value

  defp normalize(value, label) when is_binary(value) do
    if String.valid?(value),
      do: value,
      else: raise(ArgumentError, "#{label} contains invalid UTF-8 string content")
  end

  defp normalize(nil, _label), do: :null
  defp normalize(:null, _label), do: :null
  defp normalize(value, _label) when is_integer(value), do: value

  defp normalize(value, label) when is_float(value) do
    if finite_float?(value),
      do: value,
      else: raise(ArgumentError, "#{label} contains a non-finite number")
  end

  defp normalize(value, _label) when is_atom(value), do: Atom.to_string(value)

  defp normalize(value, label) when is_list(value),
    do: normalize_list(value, label, 0)

  defp normalize(%_module{} = _value, label),
    do: raise(ArgumentError, "#{label} contains an unsupported struct")

  defp normalize(%{} = map, label) do
    entries =
      Enum.map(map, fn {key, value} ->
        normalized_key = normalize_key!(key, label)
        {normalized_key, normalize(value, "#{label}.#{normalized_key}")}
      end)

    keys = Enum.map(entries, &elem(&1, 0))

    if length(keys) != length(Enum.uniq(keys)) do
      raise ArgumentError, "#{label} contains duplicate atom/string keys after normalization"
    end

    Map.new(entries)
  end

  defp normalize(value, label),
    do: raise(ArgumentError, "#{label} contains unsupported #{input_type(value)} content")

  defp normalize_list([], _label, _index), do: []

  defp normalize_list([head | tail], label, index) do
    [normalize(head, "#{label}[#{index}]") | normalize_list(tail, label, index + 1)]
  end

  defp normalize_list(_improper_tail, label, _index),
    do: raise(ArgumentError, "#{label} contains an improper list")

  defp normalize_key!(key, _label) when is_atom(key), do: Atom.to_string(key)

  defp normalize_key!(key, label) when is_binary(key) do
    if String.valid?(key),
      do: key,
      else: raise(ArgumentError, "#{label} contains an invalid UTF-8 object key")
  end

  defp normalize_key!(_key, label),
    do: raise(ArgumentError, "#{label} contains a non-string object key")

  defp validate(value, _path, issues) when is_boolean(value), do: issues

  defp validate(value, path, issues) when is_binary(value) do
    if String.valid?(value),
      do: issues,
      else: [error(path, "must be a valid UTF-8 JSON string") | issues]
  end

  defp validate(:null, _path, issues), do: issues
  defp validate(value, _path, issues) when is_integer(value), do: issues

  defp validate(value, path, issues) when is_float(value) do
    if finite_float?(value),
      do: issues,
      else: [error(path, "must be a finite JSON number") | issues]
  end

  defp validate(value, path, issues) when is_list(value),
    do: validate_list(value, path, 0, issues)

  defp validate(%_module{} = _value, path, issues),
    do: [error(path, "structs are not JSON values") | issues]

  defp validate(%{} = map, path, issues) do
    normalized_keys =
      map
      |> Map.keys()
      |> Enum.filter(&(is_atom(&1) or is_binary(&1)))
      |> Enum.map(&if(is_atom(&1), do: Atom.to_string(&1), else: &1))

    issues =
      if length(normalized_keys) == length(Enum.uniq(normalized_keys)),
        do: issues,
        else: [error(path, "contains duplicate atom/string keys after normalization") | issues]

    Enum.reduce(map, issues, fn
      {key, value}, acc when is_binary(key) ->
        if String.valid?(key) do
          validate(value, "#{path}.#{key}", acc)
        else
          [error("#{path}.<invalid_utf8_key>", "object keys must be valid UTF-8 strings") | acc]
        end

      {key, value}, acc when is_atom(key) ->
        acc = [error(path, "object keys must be strings") | acc]
        validate(value, "#{path}.#{Atom.to_string(key)}", acc)

      {_key, _value}, acc ->
        [error(path, "object keys must be strings") | acc]
    end)
  end

  defp validate(value, path, issues),
    do: [error(path, "#{input_type(value)} is not a JSON value") | issues]

  defp validate_list([], _path, _index, issues), do: issues

  defp validate_list([head | tail], path, index, issues) do
    issues = validate(head, "#{path}[#{index}]", issues)
    validate_list(tail, path, index + 1, issues)
  end

  defp validate_list(_improper_tail, path, _index, issues),
    do: [error(path, "improper lists are not JSON arrays") | issues]

  defp error(path, message), do: PrimitiveValidation.error(path, message)

  defp finite_float?(value),
    do: value == value and value <= @max_float and value >= -@max_float

  defp input_type(value) when is_nil(value), do: "nil"
  defp input_type(value) when is_tuple(value), do: "tuple"
  defp input_type(value) when is_pid(value), do: "PID"
  defp input_type(value) when is_reference(value), do: "reference"
  defp input_type(value) when is_function(value), do: "function"
  defp input_type(value) when is_bitstring(value), do: "non-binary bitstring"
  defp input_type(_value), do: "unsupported term"
end
