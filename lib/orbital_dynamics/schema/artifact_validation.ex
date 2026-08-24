defmodule OrbitalDynamics.Schema.ArtifactValidation do
  @moduledoc false

  alias OrbitalDynamics.Schema.{Inference, JsonSafety, PrimitiveValidation}

  @local_search_certificate "local_search_optimization_certificate.v1"
  @validation_options [:contract, :schema_contract, :validation_mode, :artifact_path]
  @selector_options [:contract, :schema_contract]

  def validate(artifact, opts, contracts, callbacks) do
    with {:ok, requested_contract} <- validate_options(opts),
         :ok <- validate_dependencies(contracts, callbacks),
         {:ok, contract_fun} <- fetch_callback(callbacks, :contract, 1),
         {:ok, validate_contract_fun} <- fetch_callback(callbacks, :validate_contract, 3) do
      validate_input(
        artifact,
        opts,
        contracts,
        requested_contract,
        contract_fun,
        validate_contract_fun
      )
    else
      {:error, issue} -> {:error, failure_report(:null, issue)}
    end
  rescue
    _error ->
      {:error,
       failure_report(
         :null,
         PrimitiveValidation.error("$", "artifact validation failed safely")
       )}
  catch
    _kind, _reason ->
      {:error,
       failure_report(
         :null,
         PrimitiveValidation.error("$", "artifact validation failed safely")
       )}
  end

  defp validate_input(
         artifact,
         opts,
         contracts,
         requested_contract,
         contract_fun,
         validate_contract_fun
       ) do
    contract_hint = contract_hint(requested_contract, artifact)

    cond do
      is_map(artifact) ->
        case public_json_issues(artifact, contract_hint) do
          [] ->
            validate_contract(
              artifact,
              opts,
              contracts,
              requested_contract,
              contract_fun,
              validate_contract_fun
            )

          _issues when contract_hint == @local_search_certificate ->
            validate_named_contract(
              contract_hint,
              artifact,
              contract_fun,
              validate_contract_fun
            )

          issues ->
            {:error, failure_report(requested_contract, issues)}
        end

      contract_hint == @local_search_certificate ->
        validate_named_contract(
          contract_hint,
          artifact,
          contract_fun,
          validate_contract_fun
        )

      true ->
        {:error,
         failure_report(
           contract_hint,
           PrimitiveValidation.error("$", "artifact must be a map")
         )}
    end
  end

  defp validate_contract(
         artifact,
         opts,
         contracts,
         requested_contract,
         contract_fun,
         validate_contract_fun
       ) do
    with :ok <- validate_embedded_selector(artifact),
         {:ok, contract_name, artifact} <-
           Inference.artifact_for_validation(artifact, opts, contracts) do
      validate_named_contract(contract_name, artifact, contract_fun, validate_contract_fun)
    else
      {:error, reason} when is_binary(reason) ->
        {:error,
         failure_report(
           requested_contract,
           PrimitiveValidation.error("$", reason)
         )}

      {:error, %{} = issue} ->
        {:error, failure_report(requested_contract, issue)}
    end
  end

  defp validate_named_contract(contract_name, artifact, contract_fun, validate_contract_fun) do
    case contract_fun.(contract_name) do
      {:ok, contract} ->
        issues = validate_contract_fun.(contract_name, contract, artifact)
        validation_report(contract_name, contract, issues)

      :error ->
        {:error,
         failure_report(
           contract_name,
           PrimitiveValidation.error("$", "unknown schema contract: #{contract_name}")
         )}
    end
  end

  defp validation_report(contract_name, contract, issues)
       when is_binary(contract_name) and is_map(contract) do
    if proper_list?(issues) do
      errors = Enum.filter(issues, &(&1["severity"] == "error"))
      warnings = Enum.filter(issues, &(&1["severity"] == "warning"))

      report = %{
        "schema_contract" => contract_name,
        "artifact_family" => contract["artifact_family"],
        "schema_version" => contract["schema_version"],
        "status" => if(errors == [], do: "pass", else: "fail"),
        "errors" => errors,
        "warnings" => warnings
      }

      if errors == [], do: {:ok, report}, else: {:error, report}
    else
      {:error,
       failure_report(
         contract_name,
         PrimitiveValidation.error("$", "schema validator returned malformed issues")
       )}
    end
  end

  defp validate_options(opts) do
    with {:ok, entries} <- collect_options(opts, 0, []),
         :ok <- reject_duplicate_options(entries),
         :ok <- reject_conflicting_selectors(entries),
         :ok <- validate_context_options(entries),
         {:ok, requested_contract} <- requested_contract(entries) do
      {:ok, requested_contract}
    end
  end

  defp collect_options([], _count, entries), do: {:ok, Enum.reverse(entries)}

  defp collect_options([_entry | _tail], count, _entries)
       when count >= length(@validation_options),
       do: option_error("$.options", "contains too many validation options")

  defp collect_options([{key, value} | tail], count, entries)
       when is_atom(key) and key in @validation_options do
    collect_options(tail, count + 1, [{key, value} | entries])
  end

  defp collect_options([_entry | _tail], _count, _entries),
    do: option_error("$.options", "must contain only supported keyword entries")

  defp collect_options(_improper, _count, _entries),
    do: option_error("$.options", "must be a proper keyword list")

  defp reject_duplicate_options(entries) do
    keys = Enum.map(entries, &elem(&1, 0))

    if length(keys) == length(Enum.uniq(keys)),
      do: :ok,
      else: option_error("$.options", "must not contain duplicate options")
  end

  defp reject_conflicting_selectors(entries) do
    keys = MapSet.new(Enum.map(entries, &elem(&1, 0)))

    if MapSet.member?(keys, :contract) and MapSet.member?(keys, :schema_contract),
      do: option_error("$.options", "must declare only one contract selector"),
      else: :ok
  end

  defp validate_context_options(entries) do
    Enum.reduce_while(entries, :ok, fn
      {key, value}, :ok when key in [:validation_mode, :artifact_path] ->
        if is_binary(value) and value != "" and String.valid?(value),
          do: {:cont, :ok},
          else: {:halt, option_error("$.options.#{key}", "must be a non-empty UTF-8 string")}

      {_key, _value}, :ok ->
        {:cont, :ok}
    end)
  end

  defp requested_contract(entries) do
    entries
    |> Enum.filter(fn {key, _value} -> key in @selector_options end)
    |> requested_contract_from_entries()
  end

  defp requested_contract_from_entries([]), do: {:ok, nil}

  defp requested_contract_from_entries([{_key, value}])
       when is_binary(value) and value != "" do
    if String.valid?(value),
      do: {:ok, value},
      else: option_error("$.schema_contract", "must be a valid UTF-8 string")
  end

  defp requested_contract_from_entries(_entries),
    do: option_error("$.schema_contract", "must be a non-empty UTF-8 string")

  defp validate_dependencies(contracts, callbacks) do
    if is_map(contracts) and proper_list?(callbacks),
      do: :ok,
      else: option_error("$", "schema validation dependencies are malformed")
  end

  defp fetch_callback(callbacks, key, arity) do
    case Keyword.fetch(callbacks, key) do
      {:ok, callback} when is_function(callback, arity) -> {:ok, callback}
      _other -> option_error("$", "schema validation callbacks are malformed")
    end
  end

  defp validate_embedded_selector(artifact) do
    if Map.has_key?(artifact, "schema_contract") do
      case artifact["schema_contract"] do
        selector when is_binary(selector) and selector != "" ->
          if String.valid?(selector),
            do: :ok,
            else: option_error("$.schema_contract", "must be a valid UTF-8 string")

        _selector ->
          option_error("$.schema_contract", "must be a non-empty UTF-8 string")
      end
    else
      :ok
    end
  end

  defp contract_hint(requested_contract, _artifact) when is_binary(requested_contract),
    do: requested_contract

  defp contract_hint(nil, %{"schema_contract" => contract_name}) when is_binary(contract_name),
    do: if(String.valid?(contract_name), do: contract_name, else: :null)

  defp contract_hint(_requested_contract, _artifact), do: :null

  defp public_json_issues(artifact, @local_search_certificate), do: JsonSafety.errors(artifact)

  defp public_json_issues(artifact, _legacy_contract) do
    artifact
    |> JsonSafety.artifact_errors()
    |> Enum.reject(&(&1["message"] == "nil is not a JSON value"))
  end

  defp option_error(path, message), do: {:error, PrimitiveValidation.error(path, message)}

  defp failure_report(requested_contract, errors) when is_list(errors) do
    %{
      "schema_contract" => requested_contract || :null,
      "artifact_family" => :null,
      "schema_version" => :null,
      "status" => "fail",
      "errors" => errors,
      "warnings" => []
    }
  end

  defp failure_report(requested_contract, error) do
    %{
      "schema_contract" => requested_contract || :null,
      "artifact_family" => :null,
      "schema_version" => :null,
      "status" => "fail",
      "errors" => [error],
      "warnings" => []
    }
  end

  defp proper_list?([]), do: true
  defp proper_list?([_head | tail]), do: proper_list?(tail)
  defp proper_list?(_value), do: false
end
