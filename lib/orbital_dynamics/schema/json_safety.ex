defmodule OrbitalDynamics.Schema.JsonSafety do
  @moduledoc false

  alias OrbitalDynamics.Schema.PrimitiveValidation

  @max_float 1.7976931348623157e308
  @max_depth 64
  @max_nodes 20_000
  @max_collection_items 2_048
  @max_aggregate_bytes 4_194_304
  @max_issues 100

  def limits do
    %{
      "max_depth" => @max_depth,
      "max_nodes" => @max_nodes,
      "max_collection_items" => @max_collection_items,
      "max_aggregate_bytes" => @max_aggregate_bytes,
      "max_issues" => @max_issues
    }
  end

  def normalize_input!(value, label) when is_binary(label) do
    case resource_errors(value, "$") do
      [] ->
        normalize(value, label)

      [%{"path" => path, "message" => message}] ->
        raise ArgumentError, "#{label} exceeds JSON safety limits at #{path}: #{message}"
    end
  end

  def validate_artifact!(value, label) when is_binary(label) do
    case errors(value) do
      [] ->
        value

      [%{"path" => path, "message" => message} | _rest] ->
        raise ArgumentError, "#{label} is not recursively JSON-safe at #{path}: #{message}"
    end
  end

  def errors(value, path \\ "$") do
    case resource_errors(value, path) do
      [] ->
        state = validate(value, path, %{halted: false, issue_count: 0, issues: []})
        Enum.reverse(state.issues)

      issues ->
        issues
    end
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

  defp resource_errors(value, path) do
    case validate_resources(value, path, 0, %{aggregate_bytes: 0, nodes: 0}) do
      {:ok, _state} -> []
      {:error, issue} -> [issue]
    end
  end

  defp validate_resources(_value, path, depth, _state) when depth > @max_depth,
    do: {:error, error(path, "exceeds maximum JSON nesting depth of #{@max_depth}")}

  defp validate_resources(value, path, depth, state) do
    with {:ok, state} <- consume_node(state, path) do
      validate_resource_value(value, path, depth, state)
    end
  end

  defp validate_resource_value(value, _path, _depth, state) when is_boolean(value),
    do: {:ok, state}

  defp validate_resource_value(:null, _path, _depth, state), do: {:ok, state}
  defp validate_resource_value(nil, _path, _depth, state), do: {:ok, state}

  defp validate_resource_value(value, path, _depth, state) when is_binary(value),
    do: consume_bytes(state, byte_size(value), path)

  defp validate_resource_value(value, path, _depth, state) when is_atom(value),
    do: consume_bytes(state, value |> Atom.to_string() |> byte_size(), path)

  defp validate_resource_value(value, path, depth, state) when is_list(value),
    do: validate_resource_list(value, path, depth, 0, state)

  defp validate_resource_value(%_module{}, _path, _depth, state), do: {:ok, state}

  defp validate_resource_value(%{} = map, path, depth, state) do
    if map_size(map) > @max_collection_items do
      {:error, error(path, "exceeds maximum JSON collection size of #{@max_collection_items}")}
    else
      Enum.reduce_while(map, {:ok, state}, fn {key, value}, {:ok, acc} ->
        with {:ok, acc} <- consume_node(acc, path),
             {:ok, acc} <- consume_key_bytes(acc, key, path),
             {:ok, acc} <-
               validate_resources(value, resource_child_path(path, key), depth + 1, acc) do
          {:cont, {:ok, acc}}
        else
          {:error, issue} -> {:halt, {:error, issue}}
        end
      end)
    end
  end

  defp validate_resource_value(_value, _path, _depth, state), do: {:ok, state}

  defp validate_resource_list([], _path, _depth, _index, state), do: {:ok, state}

  defp validate_resource_list([_head | _tail], path, _depth, index, _state)
       when index >= @max_collection_items,
       do:
         {:error, error(path, "exceeds maximum JSON collection size of #{@max_collection_items}")}

  defp validate_resource_list([head | tail], path, depth, index, state) do
    case validate_resources(head, "#{path}[#{index}]", depth + 1, state) do
      {:ok, state} -> validate_resource_list(tail, path, depth, index + 1, state)
      {:error, issue} -> {:error, issue}
    end
  end

  defp validate_resource_list(_improper_tail, path, _depth, _index, _state),
    do: {:error, error(path, "improper lists are not JSON arrays")}

  defp consume_node(%{nodes: nodes}, path) when nodes >= @max_nodes,
    do: {:error, error(path, "exceeds maximum JSON node budget of #{@max_nodes}")}

  defp consume_node(state, _path), do: {:ok, %{state | nodes: state.nodes + 1}}

  defp consume_key_bytes(state, key, path) when is_binary(key),
    do: consume_bytes(state, byte_size(key), path)

  defp consume_key_bytes(state, key, path) when is_atom(key),
    do: consume_bytes(state, key |> Atom.to_string() |> byte_size(), path)

  defp consume_key_bytes(state, _key, _path), do: {:ok, state}

  defp consume_bytes(state, bytes, path) do
    if bytes > @max_aggregate_bytes - state.aggregate_bytes do
      {:error,
       error(
         path,
         "exceeds maximum aggregate JSON string byte budget of #{@max_aggregate_bytes}"
       )}
    else
      {:ok, %{state | aggregate_bytes: state.aggregate_bytes + bytes}}
    end
  end

  defp resource_child_path(path, key) when is_binary(key) do
    if String.valid?(key), do: "#{path}.#{key}", else: "#{path}.<invalid_utf8_key>"
  end

  defp resource_child_path(path, key) when is_atom(key), do: "#{path}.#{Atom.to_string(key)}"
  defp resource_child_path(path, _key), do: "#{path}.<non_string_key>"

  defp validate(_value, _path, %{halted: true} = state), do: state

  defp validate(value, _path, state) when is_boolean(value), do: state

  defp validate(value, path, state) when is_binary(value) do
    if String.valid?(value),
      do: state,
      else: add_issue(state, path, "must be a valid UTF-8 JSON string")
  end

  defp validate(:null, _path, state), do: state
  defp validate(value, _path, state) when is_integer(value), do: state

  defp validate(value, path, state) when is_float(value) do
    if finite_float?(value),
      do: state,
      else: add_issue(state, path, "must be a finite JSON number")
  end

  defp validate(value, path, state) when is_list(value),
    do: validate_list(value, path, 0, state)

  defp validate(%_module{} = _value, path, state),
    do: add_issue(state, path, "structs are not JSON values")

  defp validate(%{} = map, path, state) do
    normalized_keys =
      map
      |> Map.keys()
      |> Enum.filter(&(is_atom(&1) or is_binary(&1)))
      |> Enum.map(&if(is_atom(&1), do: Atom.to_string(&1), else: &1))

    state =
      if length(normalized_keys) == length(Enum.uniq(normalized_keys)),
        do: state,
        else: add_issue(state, path, "contains duplicate atom/string keys after normalization")

    Enum.reduce_while(map, state, fn
      _entry, %{halted: true} = acc ->
        {:halt, acc}

      {key, value}, acc when is_binary(key) ->
        next =
          if String.valid?(key) do
            validate(value, "#{path}.#{key}", acc)
          else
            add_issue(
              acc,
              "#{path}.<invalid_utf8_key>",
              "object keys must be valid UTF-8 strings"
            )
          end

        {:cont, next}

      {key, value}, acc when is_atom(key) ->
        acc = add_issue(acc, path, "object keys must be strings")
        next = validate(value, "#{path}.#{Atom.to_string(key)}", acc)

        {:cont, next}

      {_key, _value}, acc ->
        {:cont, add_issue(acc, path, "object keys must be strings")}
    end)
  end

  defp validate(value, path, state),
    do: add_issue(state, path, "#{input_type(value)} is not a JSON value")

  defp validate_list([], _path, _index, state), do: state

  defp validate_list([head | tail], path, index, state) do
    state = validate(head, "#{path}[#{index}]", state)

    if state.halted,
      do: state,
      else: validate_list(tail, path, index + 1, state)
  end

  defp validate_list(_improper_tail, path, _index, state),
    do: add_issue(state, path, "improper lists are not JSON arrays")

  defp add_issue(%{halted: true} = state, _path, _message), do: state

  defp add_issue(state, path, message) do
    if state.issue_count < @max_issues - 1 do
      %{
        state
        | issue_count: state.issue_count + 1,
          issues: [error(path, message) | state.issues]
      }
    else
      %{
        state
        | halted: true,
          issue_count: @max_issues,
          issues: [
            error(
              path,
              "JSON safety issue budget exhausted after #{@max_issues - 1} errors"
            )
            | state.issues
          ]
      }
    end
  end

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
