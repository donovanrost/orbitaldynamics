defmodule OrbitalDynamics.AuthorityContext do
  @moduledoc """
  Builds and deterministically evaluates immutable authority-context artifacts.

  An authority context is caller-supplied evidence only. This module performs
  no authority lookup, approval, scheduling, import write, or execution. Its
  evaluation time is a required field; validation never reads the wall clock.
  `effective_from` is inclusive and `valid_until` is exclusive.
  """

  @schema_contract "authority_context.v1"
  @identity_prefix "authority_context:"
  @builder_fields [
    "schema_contract",
    "authority_source",
    "source_revision",
    "effective_from",
    "valid_until",
    "evaluation_time"
  ]
  @required_fields [
    "schema_contract",
    "authority_context_id",
    "authority_source",
    "source_revision",
    "effective_from",
    "valid_until",
    "evaluation_time"
  ]

  @type artifact :: %{required(String.t()) => String.t()}
  @type evaluation :: map()

  defmodule UnsupportedEvidence do
    @moduledoc false
    defstruct [:evidence]
  end

  @doc "Returns the stable schema contract name."
  def schema_contract, do: @schema_contract

  @doc "Returns the required authority-context fields in deterministic order."
  def required_fields, do: @required_fields

  @doc """
  Builds a canonical authority context and derives its stable content identity.

  The supplied evaluation time may fall outside the effective interval so a
  caller can construct deterministic not-yet-effective and stale evidence. Use
  `validate/1` or an explicit evaluation function to classify its eligibility.
  """
  def new(attrs) when is_map(attrs) and not is_struct(attrs) do
    input = constructor_input(attrs)

    with {:ok, context} <- build_context(attrs) do
      {:ok, context}
    else
      {:error, errors} when is_list(errors) ->
        {:error, malformed_failure(input, errors)}
    end
  end

  def new(attrs),
    do: {:error, malformed_failure(constructor_input(attrs), [error("$", "must be an object")])}

  @doc "Builds a canonical authority context or raises `ArgumentError`."
  def new!(attrs) do
    case new(attrs) do
      {:ok, context} -> context
      {:error, failure} -> raise ArgumentError, failure["reason"]
    end
  end

  @doc """
  Validates shape, content identity, effective bounds, and evaluation-time
  eligibility without reading process or application configuration.
  """
  def validate(context),
    do: validate_context(context, evaluation_provenance(explicit_input(context)))

  @doc """
  Evaluates supplied mode and context values as an explicit caller boundary.

  This arity represents two supplied values. Only `:explicit`/`"explicit"` is
  accepted; callers that need an absent-input legacy path use
  `evaluate_options/1` with neither option present.
  """
  def evaluate(mode, context) do
    evaluate_input(%{
      operation: "policy_boundary",
      mode_supplied?: true,
      mode: mode,
      context_supplied?: true,
      context: context
    })
  end

  @doc """
  Evaluates presence-sensitive authority options.

  Only the complete absence of both options returns `:legacy`. A supplied
  context without exact explicit mode, or any supplied unsupported mode, fails
  closed with caller evidence preserved in the returned evaluation.
  """
  def evaluate_options(opts) when is_list(opts) or is_map(opts) do
    mode = option(opts, :authority_context_mode)
    context = option(opts, :authority_context)

    evaluate_input(%{
      operation: "policy_boundary",
      mode_supplied?: mode != :absent,
      mode: option_value(mode),
      context_supplied?: context != :absent,
      context: option_value(context)
    })
  end

  @doc """
  Recomputes an authority evaluation solely from its preserved caller evidence.

  Returns the normalized context for a successful evaluation and `nil` for a
  reproducible failure evaluation. No process configuration or wall clock is
  read.
  """
  def recompute_evaluation(%{"provenance" => provenance}) when is_map(provenance) do
    with {:ok, input} <- input_from_provenance(provenance) do
      case evaluate_input(input, provenance) do
        {:ok, context, evaluation} -> {:ok, context, evaluation}
        {:error, evaluation} -> {:ok, nil, evaluation}
        :legacy -> {:error, [error("$", "evaluation provenance may not describe legacy mode")]}
      end
    end
  end

  def recompute_evaluation(_evaluation),
    do: {:error, [error("$.provenance", "must preserve canonical caller evidence")]}

  @doc """
  Validates the semantic correlation between a context and its evaluation.

  Map validity and copy equality are insufficient: this function recomputes
  the expected result from preserved caller evidence, then compares both the
  normalized context and the complete evaluation.
  """
  def validate_evaluation(context, evaluation) when is_map(evaluation) do
    with {:ok, expected_context, expected_evaluation} <- recompute_evaluation(evaluation),
         :ok <- validate_evaluation_context(context, expected_context),
         :ok <- validate_evaluation_copy(evaluation, expected_evaluation) do
      {:ok, %{context: expected_context, evaluation: expected_evaluation}}
    end
  end

  def validate_evaluation(_context, _evaluation),
    do: {:error, [error("$.authority_context_evaluation", "must be an object")]}

  @doc "Returns the content-derived stable identity for canonical context fields."
  def identity(context) when is_map(context) and not is_struct(context) do
    stable_input =
      {
        @schema_contract,
        field(context, "authority_source"),
        field(context, "source_revision"),
        field(context, "effective_from"),
        field(context, "valid_until"),
        field(context, "evaluation_time")
      }

    digest =
      :crypto.hash(:sha256, :erlang.term_to_binary(stable_input, [:deterministic]))
      |> Base.encode16(case: :lower)

    @identity_prefix <> digest
  end

  defp validate_context(context, provenance) when is_map(context) and not is_struct(context) do
    input = explicit_input(context)

    with {:ok, context} <- normalize_input_map(context, @required_fields),
         :ok <- require_fields(context, @required_fields),
         {:ok, normalized} <- normalize_fields(context),
         :ok <- validate_bounds(normalized),
         :ok <- validate_identity(context, normalized),
         :ok <- validate_evaluation_time(normalized, provenance) do
      {:ok, Map.put(normalized, "authority_context_id", context["authority_context_id"])}
    else
      {:error, %{"reason_code" => _reason_code} = failure} ->
        {:error, failure}

      {:error, errors} when is_list(errors) ->
        {:error, malformed_failure(input, errors, provenance)}
    end
  end

  defp validate_context(context, provenance),
    do:
      {:error,
       malformed_failure(
         explicit_input(context),
         [error("$", "must be an object")],
         provenance
       )}

  defp build_context(attrs) when is_map(attrs) and not is_struct(attrs) do
    with {:ok, attrs} <- normalize_input_map(attrs, @builder_fields),
         :ok <- require_fields(attrs, @builder_fields),
         {:ok, normalized} <- normalize_fields(attrs),
         :ok <- validate_bounds(normalized) do
      {:ok, Map.put(normalized, "authority_context_id", identity(normalized))}
    end
  end

  defp build_context(_attrs), do: {:error, [error("$", "must be an object")]}

  defp evaluate_input(input, provenance_override \\ nil) do
    provenance = provenance_override || evaluation_provenance(input)

    cond do
      not input.mode_supplied? and not input.context_supplied? ->
        :legacy

      ambiguous_option?(input.mode) or ambiguous_option?(input.context) ->
        {:error,
         failure(
           "ambiguous_authority_context_options",
           "authority context options contain conflicting or duplicate caller inputs",
           "invalid",
           provenance,
           %{"validation_errors" => ambiguous_option_errors(input)}
         )}

      not input.mode_supplied? ->
        {:error,
         failure(
           "missing_authority_context_mode",
           "authority_context requires exact explicit authority-context mode",
           "missing",
           provenance
         )}

      input.mode not in [:explicit, "explicit"] ->
        {:error,
         failure(
           "invalid_authority_context_mode",
           "authority_context_mode must equal explicit when supplied",
           "invalid",
           provenance
         )}

      not input.context_supplied? or is_nil(input.context) ->
        {:error,
         failure(
           "missing_authority_context",
           "explicit authority-context mode requires authority_context.v1",
           "explicit",
           provenance
         )}

      input.operation == "constructor" ->
        case build_context(input.context) do
          {:ok, normalized} -> {:ok, normalized, valid_evaluation(normalized, provenance)}
          {:error, errors} -> {:error, malformed_failure(input, errors, provenance)}
        end

      true ->
        case validate_context(input.context, provenance) do
          {:ok, normalized} -> {:ok, normalized, valid_evaluation(normalized, provenance)}
          {:error, failure} -> {:error, failure}
        end
    end
  end

  defp normalize_input_map(attrs, allowed_fields) do
    attrs
    |> Enum.sort_by(fn {key, value} ->
      evidence_sort_key({term_evidence(key), term_evidence(value)})
    end)
    |> Enum.reduce({%{}, MapSet.new(), []}, fn {key, value}, {normalized, seen, errors} ->
      case normalized_key(key) do
        {:ok, normalized_key} ->
          cond do
            MapSet.member?(seen, normalized_key) ->
              {normalized, seen,
               [
                 error(
                   "$.#{normalized_key}",
                   "contains duplicate atom/string keys after normalization",
                   %{"normalized_field" => normalized_key}
                 )
                 | errors
               ]}

            normalized_key not in allowed_fields ->
              {normalized, MapSet.put(seen, normalized_key),
               [error("$.#{normalized_key}", "is not allowed") | errors]}

            true ->
              {Map.put(normalized, normalized_key, value), MapSet.put(seen, normalized_key),
               errors}
          end

        :error ->
          {normalized, seen,
           [
             error("$", "map keys must be strings or atoms", %{
               "unsupported_key" => term_evidence(key)
             })
             | errors
           ]}
      end
    end)
    |> case do
      {normalized, _seen, []} -> {:ok, normalized}
      {_normalized, _seen, errors} -> {:error, Enum.reverse(errors)}
    end
  end

  defp normalize_fields(attrs) do
    with {:ok, schema_contract} <- required_string(attrs, "schema_contract"),
         :ok <- validate_schema_contract(schema_contract),
         {:ok, authority_source} <- required_string(attrs, "authority_source"),
         {:ok, source_revision} <- required_string(attrs, "source_revision"),
         {:ok, effective_from} <- required_datetime(attrs, "effective_from"),
         {:ok, valid_until} <- required_datetime(attrs, "valid_until"),
         {:ok, evaluation_time} <- required_datetime(attrs, "evaluation_time") do
      {:ok,
       %{
         "schema_contract" => @schema_contract,
         "authority_source" => authority_source,
         "source_revision" => source_revision,
         "effective_from" => effective_from,
         "valid_until" => valid_until,
         "evaluation_time" => evaluation_time
       }}
    end
  end

  defp require_fields(attrs, fields) do
    missing = Enum.reject(fields, &Map.has_key?(attrs, &1))

    if missing == [],
      do: :ok,
      else: {:error, Enum.map(missing, &error("$.#{&1}", "is required"))}
  end

  defp required_string(attrs, field) do
    case Map.get(attrs, field) do
      value when is_binary(value) ->
        if String.valid?(value) and String.trim(value) != "",
          do: {:ok, value},
          else: {:error, [error("$.#{field}", "must be a non-empty UTF-8 string")]}

      _value ->
        {:error, [error("$.#{field}", "must be a non-empty UTF-8 string")]}
    end
  end

  defp required_datetime(attrs, field) do
    case Map.get(attrs, field) do
      %DateTime{} = value ->
        case canonical_datetime(value) do
          {:ok, canonical} -> {:ok, canonical}
          {:error, _reason} -> datetime_error(field)
        end

      value when is_binary(value) ->
        case DateTime.from_iso8601(value) do
          {:ok, datetime, _offset} ->
            case canonical_datetime(datetime) do
              {:ok, canonical} -> {:ok, canonical}
              {:error, _reason} -> datetime_error(field)
            end

          {:error, _reason} ->
            datetime_error(field)
        end

      _value ->
        datetime_error(field)
    end
  end

  defp datetime_error(field),
    do: {:error, [error("$.#{field}", "must be a supported ISO 8601 date-time with an offset")]}

  defp validate_schema_contract(@schema_contract), do: :ok

  defp validate_schema_contract(_value),
    do: {:error, [error("$.schema_contract", "must equal authority_context.v1")]}

  defp validate_bounds(context) do
    with {:ok, effective_from, _offset} <- DateTime.from_iso8601(context["effective_from"]),
         {:ok, valid_until, _offset} <- DateTime.from_iso8601(context["valid_until"]) do
      if DateTime.compare(effective_from, valid_until) == :lt,
        do: :ok,
        else: {:error, [error("$.valid_until", "must be after effective_from")]}
    else
      _error -> {:error, [error("$", "contains an invalid canonical date-time")]}
    end
  end

  defp validate_identity(context, normalized) do
    expected = identity(normalized)

    if context["authority_context_id"] == expected do
      :ok
    else
      {:error,
       [
         error(
           "$.authority_context_id",
           "must match the content-derived authority context identity",
           %{"expected" => expected, "actual" => term_evidence(context["authority_context_id"])}
         )
       ]}
    end
  end

  defp validate_evaluation_time(context, provenance) do
    {:ok, effective_from, _offset} = DateTime.from_iso8601(context["effective_from"])
    {:ok, valid_until, _offset} = DateTime.from_iso8601(context["valid_until"])
    {:ok, evaluation_time, _offset} = DateTime.from_iso8601(context["evaluation_time"])

    cond do
      DateTime.compare(evaluation_time, effective_from) == :lt ->
        {:error,
         failure(
           "authority_context_not_yet_effective",
           "authority context is not effective at the caller-supplied evaluation_time",
           "explicit",
           provenance
         )}

      DateTime.compare(evaluation_time, valid_until) != :lt ->
        {:error,
         failure(
           "stale_authority_context",
           "authority context is stale at or after valid_until",
           "explicit",
           provenance
         )}

      true ->
        :ok
    end
  end

  defp valid_evaluation(context, provenance) do
    %{
      "mode" => "explicit",
      "eligibility_status" => "eligible",
      "outcome" => "policy_evaluation_allowed",
      "reason_code" => "authority_context_valid",
      "reason" => "authority context is effective at the caller-supplied evaluation_time",
      "authority_context_id" => context["authority_context_id"],
      "authority_source" => context["authority_source"],
      "source_revision" => context["source_revision"],
      "evaluation_time" => context["evaluation_time"],
      "provenance" => provenance
    }
  end

  defp malformed_failure(input, errors, provenance \\ nil) do
    failure(
      "malformed_authority_context",
      "authority context is malformed",
      "explicit",
      provenance || evaluation_provenance(input),
      %{"validation_errors" => errors}
    )
  end

  defp failure(reason_code, reason, mode, provenance, extra \\ %{}) do
    %{
      "mode" => mode,
      "eligibility_status" => "non_eligible",
      "outcome" => "blocked_by_policy",
      "reason_code" => reason_code,
      "reason" => reason,
      "provenance" => provenance
    }
    |> Map.merge(extra)
  end

  defp evaluation_provenance(input) do
    %{
      "input_source" => "caller_supplied",
      "validation" => "deterministic_no_wall_clock",
      "operation" => input.operation,
      "authority_context_mode_supplied" => input.mode_supplied?,
      "authority_context_supplied" => input.context_supplied?
    }
    |> maybe_put_evidence("provided_authority_context_mode", input.mode_supplied?, input.mode)
    |> maybe_put_evidence("provided_authority_context", input.context_supplied?, input.context)
  end

  defp input_from_provenance(provenance) do
    with :ok <- validate_provenance_keys(provenance),
         {:ok, operation} <- provenance_operation(provenance),
         {:ok, mode_supplied?} <-
           provenance_boolean(provenance, "authority_context_mode_supplied"),
         {:ok, context_supplied?} <- provenance_boolean(provenance, "authority_context_supplied"),
         {:ok, mode} <-
           provenance_value(provenance, "provided_authority_context_mode", mode_supplied?),
         {:ok, context} <-
           provenance_value(provenance, "provided_authority_context", context_supplied?) do
      {:ok,
       %{
         operation: operation,
         mode_supplied?: mode_supplied?,
         mode: mode,
         context_supplied?: context_supplied?,
         context: context
       }}
    end
  end

  defp validate_provenance_keys(provenance) do
    required = [
      "input_source",
      "validation",
      "operation",
      "authority_context_mode_supplied",
      "authority_context_supplied"
    ]

    cond do
      provenance["input_source"] != "caller_supplied" ->
        {:error, [error("$.provenance.input_source", "must equal caller_supplied")]}

      provenance["validation"] != "deterministic_no_wall_clock" ->
        {:error, [error("$.provenance.validation", "must equal deterministic_no_wall_clock")]}

      Enum.any?(required, &(not Map.has_key?(provenance, &1))) ->
        {:error, [error("$.provenance", "must preserve canonical caller evidence")]}

      true ->
        :ok
    end
  end

  defp provenance_operation(%{"operation" => operation})
       when operation in ["constructor", "policy_boundary"],
       do: {:ok, operation}

  defp provenance_operation(_provenance),
    do: {:error, [error("$.provenance.operation", "must equal constructor or policy_boundary")]}

  defp provenance_boolean(provenance, key) do
    case Map.fetch(provenance, key) do
      {:ok, value} when is_boolean(value) -> {:ok, value}
      _value -> {:error, [error("$.provenance.#{key}", "must be a boolean")]}
    end
  end

  defp provenance_value(provenance, key, true) do
    case Map.fetch(provenance, key) do
      {:ok, evidence} -> decode_evidence(evidence)
      :error -> {:error, [error("$.provenance.#{key}", "is required when supplied is true")]}
    end
  end

  defp provenance_value(provenance, key, false) do
    if Map.has_key?(provenance, key),
      do: {:error, [error("$.provenance.#{key}", "must be absent when supplied is false")]},
      else: {:ok, nil}
  end

  defp validate_evaluation_context(context, nil) do
    if is_nil(context),
      do: :ok,
      else: {:error, [error("$.authority_context", "must be absent for a failed evaluation")]}
  end

  defp validate_evaluation_context(context, expected_context) do
    case validate_context(context, evaluation_provenance(explicit_input(context))) do
      {:ok, normalized} when normalized == expected_context ->
        :ok

      {:ok, _normalized} ->
        {:error,
         [
           error(
             "$.authority_context",
             "must match the context recomputed from evaluation provenance"
           )
         ]}

      {:error, _failure} ->
        {:error, [error("$.authority_context", "must be a valid authority_context.v1 object")]}
    end
  end

  defp validate_evaluation_copy(evaluation, expected_evaluation) do
    if evaluation == expected_evaluation,
      do: :ok,
      else:
        {:error,
         [
           error(
             "$.authority_context_evaluation",
             "must equal the deterministic evaluation recomputed from caller evidence"
           )
         ]}
  end

  defp option(opts, key) when is_list(opts) do
    string_key = Atom.to_string(key)

    values =
      Enum.flat_map(opts, fn
        {candidate, value} when candidate == key or candidate == string_key -> [value]
        _entry -> []
      end)

    case values do
      [] -> :absent
      [value] -> {:present, value}
      _values -> {:present, {:ambiguous_option, Atom.to_string(key), values}}
    end
  end

  defp option(opts, key) when is_map(opts) do
    values =
      [key, Atom.to_string(key)]
      |> Enum.flat_map(fn candidate ->
        case Map.fetch(opts, candidate) do
          {:ok, value} -> [value]
          :error -> []
        end
      end)

    case values do
      [] -> :absent
      [value] -> {:present, value}
      _values -> {:present, {:ambiguous_option, Atom.to_string(key), values}}
    end
  end

  defp option_value(:absent), do: nil
  defp option_value({:present, value}), do: value

  defp explicit_input(context) do
    %{
      operation: "policy_boundary",
      mode_supplied?: true,
      mode: "explicit",
      context_supplied?: true,
      context: context
    }
  end

  defp constructor_input(context),
    do: %{explicit_input(context) | operation: "constructor"}

  defp ambiguous_option?({:ambiguous_option, key, values})
       when is_binary(key) and is_list(values),
       do: true

  defp ambiguous_option?(_value), do: false

  defp ambiguous_option_errors(input) do
    [input.mode, input.context]
    |> Enum.flat_map(fn
      {:ambiguous_option, key, values} ->
        [
          error("$.#{key}", "contains conflicting or duplicate caller inputs", %{
            "provided_values" => Enum.map(values, &term_evidence/1)
          })
        ]

      _value ->
        []
    end)
  end

  defp canonical_datetime(%DateTime{time_zone: time_zone} = datetime)
       when time_zone in ["Etc/UTC", "UTC"] do
    try do
      unix = DateTime.to_unix(datetime, :microsecond)

      case DateTime.from_unix(unix, :microsecond) do
        {:ok, utc} -> {:ok, DateTime.to_iso8601(utc)}
        {:error, reason} -> {:error, reason}
      end
    rescue
      exception -> {:error, exception.__struct__}
    end
  end

  defp canonical_datetime(%DateTime{}), do: {:error, :unsupported_time_zone}

  defp normalized_key(value) when is_binary(value) do
    if String.valid?(value), do: {:ok, value}, else: :error
  end

  defp normalized_key(value) when is_atom(value), do: {:ok, Atom.to_string(value)}
  defp normalized_key(_value), do: :error

  defp field(context, key) do
    case Map.fetch(context, key) do
      {:ok, value} -> value
      :error -> Map.get(context, String.to_existing_atom(key))
    end
  end

  defp term_evidence(value) when is_binary(value),
    do: %{"term_type" => "binary", "base64" => Base.encode64(value)}

  defp term_evidence(value) when is_atom(value),
    do: %{"term_type" => "atom", "value" => Atom.to_string(value)}

  defp term_evidence(value) when is_integer(value),
    do: %{"term_type" => "integer", "value" => value}

  defp term_evidence(value) when is_float(value),
    do: %{"term_type" => "float", "value" => value}

  defp term_evidence(%DateTime{} = value),
    do: %{
      "term_type" => "datetime",
      "base64" => value |> :erlang.term_to_binary([:deterministic]) |> Base.encode64()
    }

  defp term_evidence(%module{} = value),
    do: %{
      "term_type" => "struct",
      "module" => Atom.to_string(module),
      "fields" => term_evidence(Map.from_struct(value))
    }

  defp term_evidence(value) when is_map(value) do
    entries =
      value
      |> Enum.map(fn {key, entry_value} ->
        %{"key" => term_evidence(key), "value" => term_evidence(entry_value)}
      end)
      |> Enum.sort_by(&evidence_sort_key/1)

    %{"term_type" => "map", "entries" => entries}
  end

  defp term_evidence(value) when is_list(value), do: list_evidence(value, [])

  defp term_evidence(value) when is_tuple(value),
    do: %{
      "term_type" => "tuple",
      "items" => value |> Tuple.to_list() |> Enum.map(&term_evidence/1)
    }

  defp term_evidence(value) when is_pid(value), do: %{"term_type" => "pid"}
  defp term_evidence(value) when is_port(value), do: %{"term_type" => "port"}
  defp term_evidence(value) when is_reference(value), do: %{"term_type" => "reference"}

  defp term_evidence(value) when is_function(value) do
    {:arity, arity} = Function.info(value, :arity)
    %{"term_type" => "function", "arity" => arity}
  end

  defp term_evidence(value) when is_bitstring(value),
    do: %{
      "term_type" => "bitstring",
      "base64" => value |> :erlang.term_to_binary([:deterministic]) |> Base.encode64()
    }

  defp list_evidence([], items),
    do: %{"term_type" => "list", "items" => Enum.reverse(items)}

  defp list_evidence([head | tail], items),
    do: list_evidence(tail, [term_evidence(head) | items])

  defp list_evidence(tail, items),
    do: %{
      "term_type" => "improper_list",
      "items" => Enum.reverse(items),
      "tail" => term_evidence(tail)
    }

  defp decode_evidence(%{"term_type" => "binary", "base64" => encoded} = evidence)
       when map_size(evidence) == 2 and is_binary(encoded) do
    case Base.decode64(encoded) do
      {:ok, value} -> {:ok, value}
      :error -> invalid_evidence()
    end
  end

  defp decode_evidence(%{"term_type" => "atom", "value" => value} = evidence)
       when map_size(evidence) == 2 and is_binary(value) do
    try do
      {:ok, String.to_existing_atom(value)}
    rescue
      ArgumentError -> invalid_evidence()
    end
  end

  defp decode_evidence(%{"term_type" => "integer", "value" => value} = evidence)
       when map_size(evidence) == 2 and is_integer(value),
       do: {:ok, value}

  defp decode_evidence(%{"term_type" => "float", "value" => value} = evidence)
       when map_size(evidence) == 2 and is_float(value),
       do: {:ok, value}

  defp decode_evidence(%{"term_type" => "datetime", "base64" => encoded} = evidence)
       when map_size(evidence) == 2 and is_binary(encoded) do
    with {:ok, binary} <- Base.decode64(encoded),
         {:ok, %DateTime{} = datetime} <- safe_binary_to_term(binary) do
      {:ok, datetime}
    else
      _error -> invalid_evidence()
    end
  end

  defp decode_evidence(%{"term_type" => "map", "entries" => entries} = evidence)
       when map_size(evidence) == 2 and is_list(entries) do
    if entries == Enum.sort_by(entries, &evidence_sort_key/1) do
      Enum.reduce_while(entries, {:ok, %{}}, fn
        %{"key" => key, "value" => value} = entry, {:ok, map} when map_size(entry) == 2 ->
          with {:ok, decoded_key} <- decode_evidence(key),
               false <- Map.has_key?(map, decoded_key),
               {:ok, decoded_value} <- decode_evidence(value) do
            {:cont, {:ok, Map.put(map, decoded_key, decoded_value)}}
          else
            true -> {:halt, invalid_evidence()}
            {:error, errors} -> {:halt, {:error, errors}}
          end

        _entry, _acc ->
          {:halt, invalid_evidence()}
      end)
    else
      invalid_evidence()
    end
  end

  defp decode_evidence(%{"term_type" => type, "items" => items} = evidence)
       when map_size(evidence) == 2 and type in ["list", "tuple"] and is_list(items) do
    with {:ok, values} <- decode_evidence_list(items) do
      if type == "tuple", do: {:ok, List.to_tuple(values)}, else: {:ok, values}
    end
  end

  defp decode_evidence(%{"term_type" => type} = evidence)
       when map_size(evidence) == 1 and type in ["pid", "port", "reference"] do
    {:ok, %UnsupportedEvidence{evidence: evidence}}
  end

  defp decode_evidence(%{"term_type" => "function", "arity" => arity} = evidence)
       when map_size(evidence) == 2 and is_integer(arity) and arity >= 0 do
    {:ok, %UnsupportedEvidence{evidence: evidence}}
  end

  defp decode_evidence(
         %{"term_type" => "struct", "module" => module, "fields" => fields} = evidence
       )
       when map_size(evidence) == 3 and is_binary(module) and is_map(fields),
       do: {:ok, %UnsupportedEvidence{evidence: evidence}}

  defp decode_evidence(%{"term_type" => "bitstring", "base64" => encoded} = evidence)
       when map_size(evidence) == 2 and is_binary(encoded) do
    case Base.decode64(encoded) do
      {:ok, _binary} -> {:ok, %UnsupportedEvidence{evidence: evidence}}
      :error -> invalid_evidence()
    end
  end

  defp decode_evidence(
         %{"term_type" => "improper_list", "items" => items, "tail" => tail} = evidence
       )
       when map_size(evidence) == 3 and is_list(items) and is_map(tail),
       do: {:ok, %UnsupportedEvidence{evidence: evidence}}

  defp decode_evidence(_evidence), do: invalid_evidence()

  defp decode_evidence_list(items) do
    Enum.reduce_while(items, {:ok, []}, fn evidence, {:ok, values} ->
      case decode_evidence(evidence) do
        {:ok, value} -> {:cont, {:ok, [value | values]}}
        {:error, errors} -> {:halt, {:error, errors}}
      end
    end)
    |> case do
      {:ok, values} -> {:ok, Enum.reverse(values)}
      error -> error
    end
  end

  defp safe_binary_to_term(binary) do
    try do
      {:ok, :erlang.binary_to_term(binary, [:safe])}
    rescue
      ArgumentError -> invalid_evidence()
    end
  end

  defp invalid_evidence,
    do: {:error, [error("$.provenance", "contains invalid canonical term evidence")]}

  defp evidence_sort_key(value), do: :erlang.term_to_binary(value, [:deterministic])

  defp maybe_put_evidence(map, _key, false, _value), do: map
  defp maybe_put_evidence(map, key, true, value), do: Map.put(map, key, term_evidence(value))

  defp error(path, reason, evidence \\ nil) do
    %{"path" => path, "reason" => reason}
    |> maybe_put("evidence", evidence)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
