defmodule OrbitalDynamics.Environment.Provider do
  @moduledoc """
  Behaviour and validation helpers for environment provider adapters.

  Provider capability records are deliberately explicit about source coverage,
  interpolation, supported bodies, and network access. A provider capability is
  not proof of high-fidelity data; it is the contract a caller can inspect
  before trusting an adapter in a planning run.
  """

  @type capability :: %{optional(String.t()) => term()}

  @sha256_regex ~r/\A[0-9a-f]{64}\z/
  @max_container_depth 12
  @max_container_entries 4_096
  @max_list_length 1_024
  @max_map_size 128
  @max_key_bytes 256
  @max_scalar_bytes 4_096
  @max_total_bytes 1_000_000
  @safe_number_limit 1.0e15
  @capability_aliases [
    {:id, "id"},
    {:schema_contract, "schema_contract"},
    {:category, "category"},
    {:model, "model"},
    {:source, "source"},
    {:validation_level, "validation_level"},
    {:coverage, "coverage"},
    {:interpolation, "interpolation"},
    {:supported_bodies, "supported_bodies"},
    {:network_access, "network_access"},
    {:known_limits, "known_limits"},
    {:outputs, "outputs"},
    {:parameters, "parameters"},
    {:supported_frames, "supported_frames"},
    {:supported_time_scales, "supported_time_scales"},
    {:source_identity, "source_identity"},
    {:trust_boundary, "trust_boundary"},
    {:provenance, "provenance"}
  ]
  @request_aliases [
    {:starts_at_s, "starts_at_s"},
    {:ends_at_s, "ends_at_s"},
    {:body, "body"},
    {:bodies, "bodies"},
    {:central_body, "central_body"},
    {:output, "output"},
    {:outputs, "outputs"},
    {:product, "product"},
    {:kind, "kind"},
    {:frame, "frame"},
    {:frames, "frames"},
    {:inertial_frame, "inertial_frame"},
    {:earth_fixed_frame, "earth_fixed_frame"},
    {:time_scale, "time_scale"},
    {:time_scales, "time_scales"}
  ]
  @request_keys Enum.flat_map(@request_aliases, fn {atom_key, string_key} ->
                  [atom_key, string_key]
                end)
  @coverage_aliases [
    {:starts_at_s, "starts_at_s"},
    {:ends_at_s, "ends_at_s"}
  ]

  @callback capabilities() :: capability()
  @callback fetch(atom(), keyword()) :: {:ok, map()} | {:error, term()}

  @optional_callbacks fetch: 2

  @doc """
  Validates the minimal provider capability shape.
  """
  def validate_capability(%{__struct__: _struct}), do: {:error, {:invalid_container, :capability}}

  def validate_capability(%{} = record) do
    with :ok <- preflight_container(record, :capability),
         :ok <- reject_alias_collisions(record, @capability_aliases) do
      required = [
        "id",
        "schema_contract",
        "category",
        "model",
        "source",
        "validation_level",
        "coverage",
        "interpolation",
        "supported_bodies",
        "network_access",
        "known_limits"
      ]

      missing = Enum.reject(required, &Map.has_key?(record, &1))

      cond do
        missing != [] ->
          {:error, {:missing_keys, missing}}

        record["schema_contract"] != "environment_provider_capability.v1" ->
          {:error, {:invalid_field, "schema_contract"}}

        not is_binary(record["model"]) ->
          {:error, {:invalid_field, "model"}}

        not is_map(record["coverage"]) ->
          {:error, {:invalid_field, "coverage"}}

        not valid_coverage?(record["coverage"]) ->
          {:error, {:invalid_field, "coverage"}}

        not is_list(record["supported_bodies"]) ->
          {:error, {:invalid_field, "supported_bodies"}}

        not string_list?(record["supported_bodies"]) ->
          {:error, {:invalid_field, "supported_bodies"}}

        not is_boolean(record["network_access"]) ->
          {:error, {:invalid_field, "network_access"}}

        record["network_access"] == true and not trust_boundary_declared?(record) ->
          {:error, {:missing_trust_boundary, "network_access"}}

        Map.has_key?(record, "outputs") and not string_list?(record["outputs"]) ->
          {:error, {:invalid_field, "outputs"}}

        Map.has_key?(record, "parameters") and not is_map(record["parameters"]) ->
          {:error, {:invalid_field, "parameters"}}

        Map.has_key?(record, "supported_frames") and
            not string_list?(record["supported_frames"]) ->
          {:error, {:invalid_field, "supported_frames"}}

        Map.has_key?(record, "supported_time_scales") and
            not string_list?(record["supported_time_scales"]) ->
          {:error, {:invalid_field, "supported_time_scales"}}

        Map.has_key?(record, "source_identity") and
            not valid_source_identity?(record["source_identity"]) ->
          {:error, {:invalid_field, "source_identity"}}

        not is_list(record["known_limits"]) ->
          {:error, {:invalid_field, "known_limits"}}

        not string_list?(record["known_limits"]) ->
          {:error, {:invalid_field, "known_limits"}}

        true ->
          :ok
      end
    end
  end

  def validate_capability(_record), do: {:error, :invalid_record}

  defp string_list?(values) when is_list(values) do
    case bounded_list_items(values, :list, @max_list_length) do
      {:ok, items} -> Enum.all?(items, &is_binary/1)
      {:error, _reason} -> false
    end
  end

  defp string_list?(_values), do: false

  defp trust_boundary_declared?(record) do
    trust_boundary =
      case Map.get(record, "trust_boundary") do
        value when is_binary(value) -> value
        _value -> provenance_trust_boundary(record)
      end

    case trust_boundary do
      value when is_binary(value) and value != "" -> true
      _value -> false
    end
  end

  defp provenance_trust_boundary(%{"provenance" => %{} = provenance}),
    do: Map.get(provenance, "trust_boundary")

  defp provenance_trust_boundary(_record), do: nil

  @doc """
  Returns true when a provider capability covers the requested time span.

  `nil` coverage bounds are treated as open-ended. The request may use atom or
  string keys for `starts_at_s` and `ends_at_s`.
  """
  def covers_time_span?(%{__struct__: _struct}, _request), do: false
  def covers_time_span?(_record, %{__struct__: _struct}), do: false

  def covers_time_span?(%{} = record, request) when is_map(request) do
    with :ok <- validate_capability(record),
         {:ok, request_start, request_end} <- request_span(request) do
      coverage = record["coverage"]
      time_span_covered?(coverage, request_start, request_end)
    else
      _error -> false
    end
  end

  def covers_time_span?(_record, _request), do: false

  @doc """
  Returns true when a provider capability covers the requested time span, body,
  and output product.

  Requests may use atom or string keys. `body`, `bodies`, `output`, `outputs`,
  `product`, or `kind` are treated as optional fit criteria; omitted criteria do
  not constrain the result.
  """
  def supports_request?(%{__struct__: _struct}, _request), do: false
  def supports_request?(_record, %{__struct__: _struct}), do: false

  def supports_request?(%{} = record, request) when is_map(request) do
    with :ok <- validate_capability(record),
         {:ok, request_start, request_end} <- request_span(request) do
      record["coverage"]
      |> time_span_covered?(request_start, request_end)
      |> and?(bodies_supported?(record, request))
      |> and?(outputs_supported?(record, request))
      |> and?(frames_supported?(record, request))
      |> and?(time_scales_supported?(record, request))
    else
      _error -> false
    end
  end

  def supports_request?(_record, _request), do: false

  defp valid_coverage?(%{} = coverage) do
    with :ok <- reject_alias_collisions(coverage, @coverage_aliases) do
      starts_at_s = Map.get(coverage, "starts_at_s")
      ends_at_s = Map.get(coverage, "ends_at_s")

      valid_bound?(starts_at_s) and valid_bound?(ends_at_s) and
        (is_nil(starts_at_s) or is_nil(ends_at_s) or starts_at_s <= ends_at_s)
    else
      {:error, _reason} -> false
    end
  end

  defp valid_bound?(nil), do: true
  defp valid_bound?(value), do: finite_number?(value)

  defp request_span(request) do
    with :ok <- preflight_container(request, :request),
         :ok <- reject_alias_collisions(request, @request_aliases),
         :ok <- reject_unsupported_request_keys(request) do
      starts_at_s = alias_value(request, :starts_at_s, "starts_at_s")
      ends_at_s = alias_value(request, :ends_at_s, "ends_at_s")

      cond do
        not finite_number?(starts_at_s) ->
          {:error, {:invalid_field, "starts_at_s"}}

        not finite_number?(ends_at_s) ->
          {:error, {:invalid_field, "ends_at_s"}}

        ends_at_s < starts_at_s ->
          {:error, {:invalid_field, "ends_at_s"}}

        true ->
          {:ok, starts_at_s, ends_at_s}
      end
    end
  end

  defp reject_unsupported_request_keys(request) do
    Enum.reduce_while(Map.keys(request), :ok, fn key, :ok ->
      if key in @request_keys do
        {:cont, :ok}
      else
        {:halt, {:error, {:unsupported_key, :request}}}
      end
    end)
  end

  defp time_span_covered?(coverage, request_start, request_end) do
    coverage_start = coverage["starts_at_s"]
    coverage_end = coverage["ends_at_s"]

    (is_nil(coverage_start) or request_start >= coverage_start) and
      (is_nil(coverage_end) or request_end <= coverage_end)
  end

  defp bodies_supported?(record, request) do
    request
    |> requested_values([
      {:body, "body"},
      {:bodies, "bodies"},
      {:central_body, "central_body"}
    ])
    |> values_supported?(record["supported_bodies"])
  end

  defp outputs_supported?(record, request) do
    request
    |> requested_values([
      {:output, "output"},
      {:outputs, "outputs"},
      {:product, "product"},
      {:kind, "kind"}
    ])
    |> values_supported?(record["outputs"])
  end

  defp frames_supported?(record, request) do
    request
    |> requested_values([
      {:frame, "frame"},
      {:frames, "frames"},
      {:inertial_frame, "inertial_frame"},
      {:earth_fixed_frame, "earth_fixed_frame"}
    ])
    |> values_supported?(record["supported_frames"])
  end

  defp time_scales_supported?(record, request) do
    request
    |> requested_values([{:time_scale, "time_scale"}, {:time_scales, "time_scales"}])
    |> values_supported?(record["supported_time_scales"])
  end

  defp requested_values(request, keys) do
    keys
    |> Enum.find_value(:missing, fn {atom_key, string_key} ->
      case alias_value(request, atom_key, string_key) do
        nil -> nil
        value -> {:ok, value}
      end
    end)
    |> case do
      :missing -> {:ok, []}
      {:ok, values} -> normalize_requested_values(values)
    end
  end

  defp normalize_requested_values(nil), do: {:ok, []}

  defp normalize_requested_values(values) when is_list(values) do
    case bounded_list_items(values, :request, @max_list_length) do
      {:ok, items} -> {:ok, Enum.map(items, &normalize_requested_value/1)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_requested_values(value), do: {:ok, [normalize_requested_value(value)]}

  defp normalize_requested_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_requested_value(value) when is_binary(value), do: value
  defp normalize_requested_value(value), do: value

  defp values_supported?({:ok, []}, _supported_values), do: true

  defp values_supported?({:ok, requested_values}, supported_values)
       when is_list(supported_values) do
    string_list?(supported_values) and Enum.all?(requested_values, &(&1 in supported_values))
  end

  defp values_supported?(_requested_values, _supported_values), do: false

  defp valid_source_identity?(%{
         "provider_revision" => provider_revision,
         "source_revision" => source_revision,
         "content_identity" => %{
           "algorithm" => "sha256",
           "sha256" => sha256
         }
       }) do
    nonempty_string?(provider_revision) and nonempty_string?(source_revision) and
      is_binary(sha256) and Regex.match?(@sha256_regex, sha256)
  end

  defp valid_source_identity?(_identity), do: false

  defp nonempty_string?(value), do: is_binary(value) and String.trim(value) != ""

  defp and?(left, right), do: left and right

  defp reject_alias_collisions(map, aliases) do
    Enum.reduce_while(aliases, :ok, fn {atom_key, string_key}, :ok ->
      if Map.has_key?(map, atom_key) and Map.has_key?(map, string_key) do
        {:halt, {:error, {:atom_string_alias_collision, string_key}}}
      else
        {:cont, :ok}
      end
    end)
  end

  defp alias_value(map, atom_key, string_key) do
    case {Map.fetch(map, atom_key), Map.fetch(map, string_key)} do
      {{:ok, value}, :error} -> value
      {:error, {:ok, value}} -> value
      _missing_or_collision -> nil
    end
  end

  defp preflight_container(term, field) do
    preflight_container([{term, 0}], %{bytes: 0, nodes: 0}, field)
  end

  defp preflight_container([], _context, _field), do: :ok

  defp preflight_container(_stack, %{nodes: nodes}, field) when nodes > @max_container_entries,
    do: {:error, {:container_limit_exceeded, field}}

  defp preflight_container(_stack, %{bytes: bytes}, field) when bytes > @max_total_bytes,
    do: {:error, {:container_limit_exceeded, field}}

  defp preflight_container([{_term, depth} | _rest], _context, field)
       when depth > @max_container_depth do
    {:error, {:container_depth_exceeded, field}}
  end

  defp preflight_container([{%{__struct__: _struct}, _depth} | _rest], _context, field),
    do: {:error, {:invalid_container, field}}

  defp preflight_container([{tuple, _depth} | _rest], _context, field) when is_tuple(tuple) do
    {:error, {:invalid_container, field}}
  end

  defp preflight_container([{%{} = map, depth} | rest], context, field) do
    cond do
      map_size(map) > @max_map_size ->
        {:error, {:container_limit_exceeded, field}}

      true ->
        with :ok <- validate_map_keys(map, field),
             :ok <- reject_generic_alias_collisions(map),
             {:ok, context} <- add_nodes(context, map_size(map), field),
             {:ok, context} <- add_key_bytes(context, Map.keys(map), field) do
          children = Enum.map(Map.values(map), &{&1, depth + 1})
          preflight_container(children ++ rest, context, field)
        end
    end
  end

  defp preflight_container([{list, depth} | rest], context, field) when is_list(list) do
    case bounded_list_items(list, field, @max_list_length) do
      {:ok, items} ->
        with {:ok, context} <- add_nodes(context, length(items), field) do
          children = Enum.map(items, &{&1, depth + 1})
          preflight_container(children ++ rest, context, field)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp preflight_container([{term, _depth} | rest], context, field) do
    with {:ok, context} <- preflight_scalar(term, context, field) do
      preflight_container(rest, context, field)
    end
  end

  defp preflight_scalar(nil, context, field), do: add_nodes(context, 1, field)

  defp preflight_scalar(value, context, field) when is_boolean(value),
    do: add_nodes(context, 1, field)

  defp preflight_scalar(value, context, field) when is_integer(value) or is_float(value) do
    if finite_number?(value) do
      add_nodes(context, 1, field)
    else
      {:error, {:invalid_container, field}}
    end
  end

  defp preflight_scalar(value, context, field) when is_binary(value) do
    with :ok <- validate_scalar_bytes(value, field),
         {:ok, context} <- add_nodes(context, 1, field) do
      add_bytes(context, byte_size(value), field)
    end
  end

  defp preflight_scalar(value, context, :request) when is_atom(value) do
    request_value = Atom.to_string(value)

    with :ok <- validate_scalar_bytes(request_value, :request),
         {:ok, context} <- add_nodes(context, 1, :request) do
      add_bytes(context, byte_size(request_value), :request)
    end
  end

  defp preflight_scalar(_value, _context, field), do: {:error, {:invalid_container, field}}

  defp validate_map_keys(map, field) do
    Enum.reduce_while(Map.keys(map), :ok, fn key, :ok ->
      case validate_map_key(key, field) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_map_key(key, field) when is_atom(key),
    do: validate_key_bytes(Atom.to_string(key), field)

  defp validate_map_key(key, field) when is_binary(key), do: validate_key_bytes(key, field)
  defp validate_map_key(_key, field), do: {:error, {:invalid_container, field}}

  defp validate_key_bytes(key, field) do
    if byte_size(key) <= @max_key_bytes do
      :ok
    else
      {:error, {:container_limit_exceeded, field}}
    end
  end

  defp reject_generic_alias_collisions(%{} = map) do
    keys = Map.keys(map)

    atom_key_strings =
      keys
      |> Enum.filter(&is_atom/1)
      |> Enum.map(&Atom.to_string/1)
      |> MapSet.new()

    case Enum.find(keys, fn key -> is_binary(key) and MapSet.member?(atom_key_strings, key) end) do
      nil -> :ok
      key -> {:error, {:atom_string_alias_collision, key}}
    end
  end

  defp add_key_bytes(context, keys, field) do
    Enum.reduce_while(keys, {:ok, context}, fn key, {:ok, context} ->
      bytes =
        if is_atom(key) do
          byte_size(Atom.to_string(key))
        else
          byte_size(key)
        end

      case add_bytes(context, bytes, field) do
        {:ok, context} -> {:cont, {:ok, context}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp add_nodes(%{nodes: nodes} = context, amount, field) do
    next_nodes = nodes + amount

    if next_nodes <= @max_container_entries do
      {:ok, %{context | nodes: next_nodes}}
    else
      {:error, {:container_limit_exceeded, field}}
    end
  end

  defp validate_scalar_bytes(value, field) do
    if byte_size(value) <= @max_scalar_bytes do
      :ok
    else
      {:error, {:container_limit_exceeded, field}}
    end
  end

  defp add_bytes(%{bytes: bytes} = context, amount, field) do
    next_bytes = bytes + amount

    if next_bytes <= @max_total_bytes do
      {:ok, %{context | bytes: next_bytes}}
    else
      {:error, {:container_limit_exceeded, field}}
    end
  end

  defp bounded_list_items(list, field, limit) when is_list(list) do
    bounded_list_items(list, [], 0, field, limit)
  end

  defp bounded_list_items(_list, _acc, count, field, limit) when count > limit,
    do: {:error, {:container_limit_exceeded, field}}

  defp bounded_list_items([], acc, _count, _field, _limit), do: {:ok, Enum.reverse(acc)}

  defp bounded_list_items([head | tail], acc, count, field, limit) do
    bounded_list_items(tail, [head | acc], count + 1, field, limit)
  end

  defp bounded_list_items(_improper_tail, _acc, _count, field, _limit),
    do: {:error, {:invalid_container, field}}

  defp finite_number?(value) when is_integer(value), do: abs(value) <= @safe_number_limit

  defp finite_number?(value) when is_float(value) do
    value == value and value - value == 0.0 and abs(value) <= @safe_number_limit
  end

  defp finite_number?(_value), do: false
end
