defmodule OrbitalDynamics.StudyRun do
  @moduledoc """
  Execution record for a study.

  `StudyRun` captures the runtime metadata needed to audit or reproduce a
  mission analysis batch. It is intentionally a data structure, not persistence
  or scheduling infrastructure.
  """

  alias OrbitalDynamics.Study

  @statuses [:created, :running, :completed, :failed]

  @enforce_keys [
    :id,
    :study_id,
    :status,
    :backend,
    :node,
    :options,
    :seed_manifest,
    :assumptions,
    :results,
    :errors,
    :metadata
  ]
  defstruct [
    :id,
    :study_id,
    :status,
    :backend,
    :node,
    :options,
    :seed_manifest,
    :started_at,
    :completed_at,
    :duration_ms,
    :assumptions,
    :results,
    :errors,
    :metadata
  ]

  @type status :: :created | :running | :completed | :failed

  @type t :: %__MODULE__{
          id: atom() | String.t(),
          study_id: atom() | String.t(),
          status: status(),
          backend: module() | atom(),
          node: node(),
          options: keyword(),
          seed_manifest: map(),
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil,
          duration_ms: non_neg_integer() | nil,
          assumptions: map(),
          results: list(),
          errors: list(),
          metadata: map()
        }

  @doc """
  Creates a study execution record.
  """
  def new!(id, %Study{} = study, opts \\ []) do
    status = Keyword.get(opts, :status, :created)
    backend = Keyword.get(opts, :backend, study.propagator)
    node = Keyword.get(opts, :node, node())
    options = Keyword.get(opts, :options, study.propagator_opts)
    seed_manifest = Keyword.get(opts, :seed_manifest, study.seed_manifest)
    started_at = Keyword.get(opts, :started_at)
    completed_at = Keyword.get(opts, :completed_at)
    duration_ms = Keyword.get(opts, :duration_ms)
    assumptions = Keyword.get(opts, :assumptions, %{})
    results = Keyword.get(opts, :results, [])
    errors = Keyword.get(opts, :errors, [])
    metadata = Keyword.get(opts, :metadata, %{})

    cond do
      id in [nil, ""] ->
        raise ArgumentError, "study run id is required"

      status not in @statuses ->
        raise ArgumentError, "status must be one of :created, :running, :completed, or :failed"

      not Keyword.keyword?(options) ->
        raise ArgumentError, "options must be a keyword list"

      not is_map(seed_manifest) ->
        raise ArgumentError, "seed_manifest must be a map"

      not valid_datetime_or_nil?(started_at) ->
        raise ArgumentError, "started_at must be nil or a DateTime"

      not valid_datetime_or_nil?(completed_at) ->
        raise ArgumentError, "completed_at must be nil or a DateTime"

      not nil_or_non_negative_integer?(duration_ms) ->
        raise ArgumentError, "duration_ms must be nil or a non-negative integer"

      not is_map(assumptions) ->
        raise ArgumentError, "assumptions must be a map"

      not is_list(results) ->
        raise ArgumentError, "results must be a list"

      not is_list(errors) ->
        raise ArgumentError, "errors must be a list"

      not is_map(metadata) ->
        raise ArgumentError, "metadata must be a map"

      true ->
        %__MODULE__{
          id: id,
          study_id: study.id,
          status: status,
          backend: backend,
          node: node,
          options: options,
          seed_manifest: seed_manifest,
          started_at: started_at,
          completed_at: completed_at,
          duration_ms: duration_ms,
          assumptions: assumptions,
          results: results,
          errors: errors,
          metadata: metadata
        }
    end
  end

  @doc """
  Converts a study run record into a JSON-friendly map.
  """
  def to_map(%__MODULE__{} = run) do
    %{
      "id" => encode_value(run.id),
      "study_id" => encode_value(run.study_id),
      "status" => encode_value(run.status),
      "backend" => encode_value(run.backend),
      "node" => encode_value(run.node),
      "options" => encode_value(run.options),
      "seed_manifest" => encode_value(run.seed_manifest),
      "started_at" => encode_datetime(run.started_at),
      "completed_at" => encode_datetime(run.completed_at),
      "duration_ms" => run.duration_ms,
      "assumptions" => encode_value(run.assumptions),
      "results" => encode_value(run.results),
      "errors" => encode_value(run.errors),
      "metadata" => encode_value(run.metadata)
    }
  end

  defp valid_datetime_or_nil?(nil), do: true
  defp valid_datetime_or_nil?(%DateTime{}), do: true
  defp valid_datetime_or_nil?(_value), do: false

  defp nil_or_non_negative_integer?(nil), do: true
  defp nil_or_non_negative_integer?(value), do: is_integer(value) and value >= 0

  defp encode_datetime(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp encode_datetime(nil), do: nil

  defp encode_value(values) when is_list(values) do
    if values != [] and Keyword.keyword?(values) do
      Map.new(values, fn {key, value} -> {encode_key(key), encode_value(value)} end)
    else
      Enum.map(values, &encode_value/1)
    end
  end

  defp encode_value(value) when is_map(value) do
    Map.new(value, fn {key, value} -> {encode_key(key), encode_value(value)} end)
  end

  defp encode_value(nil), do: nil
  defp encode_value(value) when is_boolean(value), do: value
  defp encode_value(value) when is_atom(value), do: Atom.to_string(value)
  defp encode_value(value) when is_tuple(value), do: value |> Tuple.to_list() |> encode_value()
  defp encode_value(value), do: value

  defp encode_key(key) when is_atom(key), do: Atom.to_string(key)
  defp encode_key(key) when is_binary(key), do: key
  defp encode_key(key), do: inspect(key)
end
