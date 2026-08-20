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

  @callback capabilities() :: capability()
  @callback fetch(atom(), keyword()) :: {:ok, map()} | {:error, term()}

  @optional_callbacks fetch: 2

  @doc """
  Validates the minimal provider capability shape.
  """
  def validate_capability(%{} = record) do
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

  def validate_capability(_record), do: {:error, :invalid_record}

  defp string_list?(values) when is_list(values), do: Enum.all?(values, &is_binary/1)
  defp string_list?(_values), do: false

  defp trust_boundary_declared?(record) do
    case Map.get(record, "trust_boundary") || get_in(record, ["provenance", "trust_boundary"]) do
      value when is_binary(value) and value != "" -> true
      _value -> false
    end
  end

  @doc """
  Returns true when a provider capability covers the requested time span.

  `nil` coverage bounds are treated as open-ended. The request may use atom or
  string keys for `starts_at_s` and `ends_at_s`.
  """
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
    starts_at_s = Map.get(coverage, "starts_at_s")
    ends_at_s = Map.get(coverage, "ends_at_s")

    valid_bound?(starts_at_s) and valid_bound?(ends_at_s) and
      (is_nil(starts_at_s) or is_nil(ends_at_s) or starts_at_s <= ends_at_s)
  end

  defp valid_bound?(nil), do: true
  defp valid_bound?(value), do: is_number(value)

  defp request_span(request) do
    starts_at_s = Map.get(request, :starts_at_s) || Map.get(request, "starts_at_s")
    ends_at_s = Map.get(request, :ends_at_s) || Map.get(request, "ends_at_s")

    cond do
      not is_number(starts_at_s) ->
        {:error, {:invalid_field, "starts_at_s"}}

      not is_number(ends_at_s) ->
        {:error, {:invalid_field, "ends_at_s"}}

      ends_at_s < starts_at_s ->
        {:error, {:invalid_field, "ends_at_s"}}

      true ->
        {:ok, starts_at_s, ends_at_s}
    end
  end

  defp time_span_covered?(coverage, request_start, request_end) do
    coverage_start = coverage["starts_at_s"]
    coverage_end = coverage["ends_at_s"]

    (is_nil(coverage_start) or request_start >= coverage_start) and
      (is_nil(coverage_end) or request_end <= coverage_end)
  end

  defp bodies_supported?(record, request) do
    request
    |> requested_values([:body, "body", :bodies, "bodies", :central_body, "central_body"])
    |> values_supported?(record["supported_bodies"])
  end

  defp outputs_supported?(record, request) do
    request
    |> requested_values([
      :output,
      "output",
      :outputs,
      "outputs",
      :product,
      "product",
      :kind,
      "kind"
    ])
    |> values_supported?(record["outputs"])
  end

  defp frames_supported?(record, request) do
    request
    |> requested_values([
      :frame,
      "frame",
      :frames,
      "frames",
      :inertial_frame,
      "inertial_frame",
      :earth_fixed_frame,
      "earth_fixed_frame"
    ])
    |> values_supported?(record["supported_frames"])
  end

  defp time_scales_supported?(record, request) do
    request
    |> requested_values([:time_scale, "time_scale", :time_scales, "time_scales"])
    |> values_supported?(record["supported_time_scales"])
  end

  defp requested_values(request, keys) do
    keys
    |> Enum.find_value(fn key -> Map.get(request, key) end)
    |> normalize_requested_values()
  end

  defp normalize_requested_values(nil), do: []

  defp normalize_requested_values(values) when is_list(values) do
    Enum.map(values, &normalize_requested_value/1)
  end

  defp normalize_requested_values(value), do: [normalize_requested_value(value)]

  defp normalize_requested_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_requested_value(value) when is_binary(value), do: value
  defp normalize_requested_value(value), do: value

  defp values_supported?([], _supported_values), do: true

  defp values_supported?(requested_values, supported_values) when is_list(supported_values) do
    Enum.all?(requested_values, &(&1 in supported_values))
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
end
