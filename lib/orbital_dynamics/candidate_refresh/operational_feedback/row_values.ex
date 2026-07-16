defmodule OrbitalDynamics.CandidateRefresh.OperationalFeedback.RowValues do
  @moduledoc false

  @stable_id_pattern ~r/^[A-Za-z0-9][A-Za-z0-9._:@-]*$/

  def first_number(row, paths) do
    Enum.find_value(paths, fn
      path when is_list(path) -> row |> get_in(path) |> numeric_value()
      path -> row |> Map.get(path) |> numeric_value()
    end)
  end

  def failure_token?(value) do
    value
    |> normalized_token()
    |> case do
      token
      when token in [
             "failed",
             "failure",
             "contact_failed",
             "link_failed",
             "no_contact",
             "missed",
             "lost",
             "dropped",
             "timeout",
             "timed_out",
             "aborted",
             "incomplete",
             "unsuccessful"
           ] ->
        true

      _token ->
        false
    end
  end

  def stable_id_or_nil(nil), do: nil
  def stable_id_or_nil("nil"), do: nil
  def stable_id_or_nil(value) when is_binary(value), do: if(stable_id?(value), do: value)

  def stable_id_or_nil(value) when is_atom(value),
    do: value |> Atom.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(value) when is_integer(value),
    do: value |> Integer.to_string() |> stable_id_or_nil()

  def stable_id_or_nil(_value), do: nil

  def normalized_token(value) do
    value
    |> encode_value()
    |> case do
      nil ->
        nil

      value ->
        value
        |> String.trim()
        |> String.downcase()
        |> String.replace(~r/[\s-]+/, "_")
        |> String.trim("_")
    end
  end

  def stringify_keys(%_struct{} = struct), do: struct |> Map.from_struct() |> stringify_keys()

  def stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), stringify_keys(value)} end)
  end

  def stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  def stringify_keys(value), do: encode_value(value)

  def stringify_keys_with_keyword_maps(%_struct{} = struct),
    do: struct |> Map.from_struct() |> stringify_keys_with_keyword_maps()

  def stringify_keys_with_keyword_maps(%{} = map) do
    Map.new(map, fn {key, value} ->
      {encode_value_with_keyword_maps(key), stringify_keys_with_keyword_maps(value)}
    end)
  end

  def stringify_keys_with_keyword_maps(values) when is_list(values),
    do: Enum.map(values, &stringify_keys_with_keyword_maps/1)

  def stringify_keys_with_keyword_maps(value), do: encode_value_with_keyword_maps(value)

  def numeric_value(value) when is_number(value), do: value * 1.0

  def numeric_value(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> number
      _error -> nil
    end
  end

  def numeric_value(_value), do: nil

  def numeric_triplet_or_nil(values) when is_list(values) and length(values) == 3 do
    triplet = Enum.map(values, &numeric_value/1)

    if Enum.all?(triplet, &is_number/1), do: triplet, else: nil
  end

  def numeric_triplet_or_nil(_values), do: nil

  def unit_interval(value), do: value |> max(0.0) |> min(1.0)

  def ensure_map(%{} = value), do: value
  def ensure_map(_value), do: %{}

  def compact_nonempty(feedback) do
    feedback
    |> Enum.reject(fn {_key, value} -> value in [nil, %{}, []] end)
    |> Map.new()
  end

  def compact_nil_values(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  def encode_value(%{} = map) do
    Map.new(map, fn {key, value} -> {encode_value(key), encode_value(value)} end)
  end

  def encode_value(values) when is_list(values) do
    Enum.map(values, &encode_value/1)
  end

  def encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  def encode_value(nil), do: nil
  def encode_value(value) when is_boolean(value), do: value
  def encode_value(value) when is_atom(value), do: Atom.to_string(value)
  def encode_value(value), do: value

  def encode_value_with_keyword_maps(%{} = map) do
    Map.new(map, fn {key, value} ->
      {encode_value_with_keyword_maps(key), encode_value_with_keyword_maps(value)}
    end)
  end

  def encode_value_with_keyword_maps(values) when is_list(values) do
    if Keyword.keyword?(values) do
      Map.new(values, fn {key, value} ->
        {encode_value_with_keyword_maps(key), encode_value_with_keyword_maps(value)}
      end)
    else
      Enum.map(values, &encode_value_with_keyword_maps/1)
    end
  end

  def encode_value_with_keyword_maps(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> encode_value_with_keyword_maps()

  def encode_value_with_keyword_maps(nil), do: nil
  def encode_value_with_keyword_maps(value) when is_boolean(value), do: value
  def encode_value_with_keyword_maps(value) when is_atom(value), do: Atom.to_string(value)
  def encode_value_with_keyword_maps(value), do: value

  defp stable_id?(value), do: Regex.match?(@stable_id_pattern, value)
end
