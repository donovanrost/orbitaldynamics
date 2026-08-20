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

  @doc "Returns the stable schema contract name."
  def schema_contract, do: @schema_contract

  @doc "Returns the required authority-context fields in deterministic order."
  def required_fields, do: @required_fields

  @doc """
  Builds a canonical authority context and derives its stable content identity.

  The supplied evaluation time may fall outside the effective interval so a
  caller can construct deterministic not-yet-effective and stale evidence. Use
  `validate/1` or `evaluate/2` to classify its eligibility.
  """
  def new(attrs) when is_map(attrs) and not is_struct(attrs) do
    with {:ok, normalized} <- normalize_fields(attrs),
         :ok <- validate_bounds(normalized) do
      {:ok, Map.put(normalized, "authority_context_id", identity(normalized))}
    end
  end

  def new(_attrs), do: {:error, malformed_failure(nil, [error("$", "must be an object")])}

  @doc "Builds a canonical authority context or raises `ArgumentError`."
  def new!(attrs) do
    case new(attrs) do
      {:ok, context} ->
        context

      {:error, failure} ->
        raise ArgumentError, failure["reason"]
    end
  end

  @doc """
  Validates shape, content identity, effective bounds, and evaluation-time
  eligibility without reading process or application configuration.
  """
  def validate(context) when is_map(context) and not is_struct(context) do
    context = stringify_keys(context)

    with :ok <- require_all_fields(context),
         :ok <- reject_unknown_fields(context),
         {:ok, normalized} <- normalize_fields(context),
         :ok <- validate_bounds(normalized),
         :ok <- validate_identity(context, normalized),
         :ok <- validate_evaluation_time(normalized) do
      {:ok, Map.put(normalized, "authority_context_id", context["authority_context_id"])}
    else
      {:error, %{"reason_code" => _reason_code} = failure} -> {:error, failure}
      {:error, errors} when is_list(errors) -> {:error, malformed_failure(context, errors)}
    end
  end

  def validate(context),
    do: {:error, malformed_failure(context, [error("$", "must be an object")])}

  @doc """
  Evaluates an authority context for an explicit policy boundary.

  Any mode other than `:explicit`/`"explicit"` is treated as the legacy path
  and returns `:legacy`; it does not inspect or copy context evidence.
  """
  def evaluate(mode, context) when mode in [:explicit, "explicit"] do
    case context do
      nil ->
        {:error,
         failure(
           "missing_authority_context",
           "explicit authority-context mode requires authority_context.v1",
           nil
         )}

      _value ->
        case validate(context) do
          {:ok, normalized} -> {:ok, normalized, valid_evaluation(normalized)}
          {:error, failure} -> {:error, failure}
        end
    end
  end

  def evaluate(_mode, _context), do: :legacy

  @doc "Returns the content-derived stable identity for canonical context fields."
  def identity(context) when is_map(context) and not is_struct(context) do
    context = stringify_keys(context)

    stable_input =
      {
        @schema_contract,
        context["authority_source"],
        context["source_revision"],
        context["effective_from"],
        context["valid_until"],
        context["evaluation_time"]
      }

    digest =
      :crypto.hash(:sha256, :erlang.term_to_binary(stable_input, [:deterministic]))
      |> Base.encode16(case: :lower)

    @identity_prefix <> digest
  end

  defp require_all_fields(context) do
    missing = Enum.reject(@required_fields, &present?(Map.get(context, &1)))

    if missing == [] do
      :ok
    else
      {:error, Enum.map(missing, &error("$.#{&1}", "is required"))}
    end
  end

  defp reject_unknown_fields(context) do
    unexpected = Map.keys(context) -- @required_fields

    if unexpected == [] do
      :ok
    else
      {:error, Enum.map(unexpected, &error("$.#{&1}", "is not allowed"))}
    end
  end

  defp normalize_fields(attrs) do
    attrs = stringify_keys(attrs)

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

  defp required_string(attrs, field) do
    case Map.get(attrs, field) do
      value when is_binary(value) ->
        if String.trim(value) == "" do
          {:error, [error("$.#{field}", "must be a non-empty string")]}
        else
          {:ok, value}
        end

      _value ->
        {:error, [error("$.#{field}", "must be a non-empty string")]}
    end
  end

  defp required_datetime(attrs, field) do
    case Map.get(attrs, field) do
      %DateTime{} = value ->
        {:ok, canonical_datetime(value)}

      value when is_binary(value) ->
        case DateTime.from_iso8601(value) do
          {:ok, datetime, _offset} ->
            {:ok, canonical_datetime(datetime)}

          {:error, _reason} ->
            {:error, [error("$.#{field}", "must be an ISO 8601 date-time with an offset")]}
        end

      _value ->
        {:error, [error("$.#{field}", "must be an ISO 8601 date-time with an offset")]}
    end
  end

  defp validate_schema_contract(@schema_contract), do: :ok

  defp validate_schema_contract(_value),
    do: {:error, [error("$.schema_contract", "must equal authority_context.v1")]}

  defp validate_bounds(context) do
    effective_from = datetime!(context["effective_from"])
    valid_until = datetime!(context["valid_until"])

    if DateTime.compare(effective_from, valid_until) == :lt do
      :ok
    else
      {:error, [error("$.valid_until", "must be after effective_from")]}
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
           %{"expected" => expected, "actual" => context["authority_context_id"]}
         )
       ]}
    end
  end

  defp validate_evaluation_time(context) do
    effective_from = datetime!(context["effective_from"])
    valid_until = datetime!(context["valid_until"])
    evaluation_time = datetime!(context["evaluation_time"])

    cond do
      DateTime.compare(evaluation_time, effective_from) == :lt ->
        {:error,
         failure(
           "authority_context_not_yet_effective",
           "authority context is not effective at the caller-supplied evaluation_time",
           context
         )}

      DateTime.compare(evaluation_time, valid_until) != :lt ->
        {:error,
         failure(
           "stale_authority_context",
           "authority context is stale at or after valid_until",
           context
         )}

      true ->
        :ok
    end
  end

  defp valid_evaluation(context) do
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
      "provenance" => evaluation_provenance(context)
    }
  end

  defp malformed_failure(context, errors) do
    failure(
      "malformed_authority_context",
      "authority context is malformed",
      context,
      %{"validation_errors" => errors}
    )
  end

  defp failure(reason_code, reason, context, extra \\ %{}) do
    %{
      "mode" => "explicit",
      "eligibility_status" => "non_eligible",
      "outcome" => "blocked_by_policy",
      "reason_code" => reason_code,
      "reason" => reason,
      "provenance" => evaluation_provenance(context)
    }
    |> Map.merge(extra)
  end

  defp evaluation_provenance(context) do
    %{
      "input_source" => "caller_supplied",
      "validation" => "deterministic_no_wall_clock",
      "provided_authority_context" => json_value(context)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp error(path, reason, evidence \\ nil) do
    %{"path" => path, "reason" => reason}
    |> maybe_put("evidence", evidence)
  end

  defp datetime!(value) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(value)
    datetime
  end

  defp canonical_datetime(datetime) do
    datetime
    |> DateTime.shift_zone!("Etc/UTC")
    |> DateTime.to_unix(:microsecond)
    |> DateTime.from_unix!(:microsecond)
    |> DateTime.to_iso8601()
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(_value), do: false

  defp stringify_keys(%DateTime{} = value), do: DateTime.to_iso8601(value)

  defp stringify_keys(%{} = map) do
    Map.new(map, fn {key, value} -> {stringify_key(key), stringify_keys(value)} end)
  end

  defp stringify_keys(values) when is_list(values), do: Enum.map(values, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp json_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp json_value(%_{} = struct), do: struct |> Map.from_struct() |> json_value()

  defp json_value(%{} = map),
    do: Map.new(map, fn {key, value} -> {stringify_key(key), json_value(value)} end)

  defp json_value(values) when is_list(values), do: Enum.map(values, &json_value/1)
  defp json_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> json_value()
  defp json_value(nil), do: nil
  defp json_value(value) when is_atom(value), do: Atom.to_string(value)
  defp json_value(value) when is_binary(value) or is_number(value) or is_boolean(value), do: value

  defp json_value(value) when is_bitstring(value) do
    value
    |> :erlang.term_to_binary([:deterministic])
    |> Base.encode64()
  end

  defp json_value(value) when is_pid(value), do: "unsupported_pid"
  defp json_value(value) when is_port(value), do: "unsupported_port"
  defp json_value(value) when is_reference(value), do: "unsupported_reference"
  defp json_value(value) when is_function(value), do: "unsupported_function"

  defp stringify_key(value) when is_binary(value), do: value
  defp stringify_key(value) when is_atom(value) or is_number(value), do: to_string(value)
  defp stringify_key(_value), do: "__unsupported_map_key__"

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
