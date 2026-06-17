defmodule OrbitalDynamics.CampaignPlanner.RequestIO do
  @moduledoc false

  alias OrbitalDynamics.Schema

  def validation_report(type, path, opts)
      when type in ["repair", "strategy"] and is_binary(path) do
    base_report = request_validation_report_base(type, path)

    case read_json_request_for_lint(path) do
      {:ok, request, request_metadata} ->
        {source_plan, errors} = lint_request_source_plan(request, path, opts)
        errors = lint_request_type(type, request) ++ errors

        base_report
        |> Map.put("request", request_metadata)
        |> Map.put("source_plan", source_plan)
        |> Map.put("errors", errors)
        |> Map.put("error_count", length(errors))
        |> Map.put("status", lint_status(errors))

      {:error, request_metadata, errors} ->
        base_report
        |> Map.put("request", request_metadata)
        |> Map.put("errors", errors)
        |> Map.put("error_count", length(errors))
        |> Map.put("status", "fail")
    end
  end

  def validation_report(type, path, _opts) when is_binary(path) do
    %{
      "schema_contract" => "campaign_request_lint.v1",
      "validation_mode" => "campaign_request_lint",
      "semantic_validator" => "OrbitalDynamics.CampaignPlanner.request_validation_report/3",
      "lint_task" => "mix orbital_dynamics.campaign.lint --type repair|strategy --request PATH",
      "type" => type,
      "request" => %{"path" => path, "sha256" => nil},
      "source_plan" => %{"status" => "not_checked"},
      "status" => "fail",
      "error_count" => 1,
      "errors" => [
        request_lint_error("unsupported_type", "$.type", "type must be repair or strategy")
      ]
    }
  end

  def load_json_request!(path) do
    path
    |> File.read!()
    |> :json.decode()
    |> case do
      %{} = request -> request
      _value -> raise ArgumentError, "request JSON must decode to an object"
    end
  end

  def put_referenced_prior_plan!(%{"prior_plan" => %{}} = request, _request_path, _opts),
    do: request

  def put_referenced_prior_plan!(%{prior_plan: %{}} = request, _request_path, _opts),
    do: request

  def put_referenced_prior_plan!(request, request_path, opts) do
    case get_key(request, :source_plan_ref) do
      nil ->
        request

      %{} = source_plan_ref ->
        request
        |> Map.delete("source_plan_ref")
        |> Map.delete(:source_plan_ref)
        |> Map.put("prior_plan", load_referenced_artifact!(source_plan_ref, request_path, opts))

      _source_plan_ref ->
        raise ArgumentError, "source_plan_ref must be an object"
    end
  end

  defp load_referenced_artifact!(source_plan_ref, request_path, opts) do
    source_path =
      source_plan_ref
      |> get_key(:path)
      |> case do
        path when is_binary(path) and path != "" -> path
        _path -> raise ArgumentError, "source_plan_ref.path is required"
      end

    request_dir = request_path |> Path.expand() |> Path.dirname()
    base_path = opts |> Keyword.get(:base_path, File.cwd!()) |> Path.expand()
    source_path = resolve_request_reference_path!(source_path, request_dir, base_path)

    artifact =
      source_path
      |> File.read!()
      |> :json.decode()

    case get_key(source_plan_ref, :artifact_key) do
      nil ->
        artifact

      artifact_key when is_binary(artifact_key) and artifact_key != "" ->
        Map.fetch!(artifact, artifact_key)

      _artifact_key ->
        raise ArgumentError, "source_plan_ref.artifact_key must be a string when supplied"
    end
  end

  defp resolve_request_reference_path!(path, request_dir, base_path) do
    candidates =
      if Path.type(path) == :absolute do
        [path]
      else
        [
          Path.expand(path, base_path),
          Path.expand(path, request_dir)
        ]
      end

    Enum.find(candidates, &File.exists?/1) ||
      raise ArgumentError, "source_plan_ref.path does not exist: #{path}"
  end

  defp request_validation_report_base(type, path) do
    %{
      "schema_contract" => "campaign_request_lint.v1",
      "validation_mode" => "campaign_request_lint",
      "semantic_validator" => "OrbitalDynamics.CampaignPlanner.request_validation_report/3",
      "lint_task" => "mix orbital_dynamics.campaign.lint --type #{type} --request PATH",
      "type" => type,
      "request" => %{"path" => path, "sha256" => nil},
      "source_plan" => %{"status" => "not_checked"},
      "status" => "pass",
      "error_count" => 0,
      "errors" => []
    }
  end

  defp read_json_request_for_lint(path) do
    case File.read(path) do
      {:ok, content} ->
        request_metadata = %{
          "path" => path,
          "sha256" => sha256(content)
        }

        case decode_json_object_for_lint(content) do
          {:ok, request} ->
            {:ok, request, request_metadata}

          {:error, message} ->
            {:error, request_metadata, [request_lint_error("invalid_json", "$", message)]}
        end

      {:error, reason} ->
        request_metadata = %{"path" => path, "sha256" => nil}

        {:error, request_metadata,
         [
           request_lint_error(
             "request_file_error",
             "$",
             "could not read request file: #{inspect(reason)}"
           )
         ]}
    end
  end

  defp decode_json_object_for_lint(content) do
    try do
      case :json.decode(content) do
        %{} = request -> {:ok, request}
        _value -> {:error, "request JSON must decode to an object"}
      end
    rescue
      exception -> {:error, Exception.message(exception)}
    end
  end

  defp lint_request_type(type, request) do
    case get_key(request, :request_type) do
      nil ->
        []

      request_type when type == "repair" and request_type == "campaign_plan_repair" ->
        []

      request_type when type == "strategy" and request_type == "campaign_strategy" ->
        []

      request_type when type == "strategy" and request_type == "campaign_strategy_v3" ->
        []

      request_type ->
        [
          request_lint_error(
            "request_type_mismatch",
            "$.request_type",
            "request_type #{inspect(request_type)} does not match campaign #{type}"
          )
        ]
    end
  end

  defp lint_request_source_plan(request, request_path, opts) do
    inline_prior_plan = inline_prior_plan(request)
    source_plan_ref = get_key(request, :source_plan_ref)

    cond do
      is_map(inline_prior_plan) and is_nil(source_plan_ref) ->
        validate_linted_source_plan(inline_prior_plan, %{
          "status" => "pass",
          "source" => "inline_prior_plan",
          "path" => nil,
          "artifact_key" => nil
        })

      is_map(inline_prior_plan) and not is_nil(source_plan_ref) ->
        {%{"status" => "fail", "source" => "ambiguous"},
         [
           request_lint_error(
             "ambiguous_prior_plan_source",
             "$",
             "request must use either prior_plan/campaign_plan/source_plan or source_plan_ref, not both"
           )
         ]}

      is_nil(source_plan_ref) ->
        {%{"status" => "fail", "source" => "missing"},
         [
           request_lint_error(
             "missing_prior_plan_source",
             "$.source_plan_ref",
             "source_plan_ref or inline prior_plan/campaign_plan/source_plan is required"
           )
         ]}

      is_map(source_plan_ref) ->
        lint_source_plan_ref(source_plan_ref, request_path, opts)

      true ->
        {%{"status" => "fail", "source" => "source_plan_ref"},
         [request_lint_error("invalid_source_plan_ref", "$.source_plan_ref", "must be an object")]}
    end
  end

  defp inline_prior_plan(request) do
    get_key(request, :prior_plan) || get_key(request, :campaign_plan) ||
      get_key(request, :source_plan)
  end

  defp lint_source_plan_ref(source_plan_ref, request_path, opts) do
    source_path = get_key(source_plan_ref, :path)
    artifact_key = get_key(source_plan_ref, :artifact_key)

    cond do
      not (is_binary(source_path) and source_path != "") ->
        {%{"status" => "fail", "source" => "source_plan_ref", "path" => source_path},
         [
           request_lint_error(
             "missing_source_plan_ref_path",
             "$.source_plan_ref.path",
             "source_plan_ref.path is required"
           )
         ]}

      not (is_nil(artifact_key) or (is_binary(artifact_key) and artifact_key != "")) ->
        {%{
           "status" => "fail",
           "source" => "source_plan_ref",
           "path" => source_path,
           "artifact_key" => artifact_key
         },
         [
           request_lint_error(
             "invalid_source_plan_ref_artifact_key",
             "$.source_plan_ref.artifact_key",
             "source_plan_ref.artifact_key must be a string when supplied"
           )
         ]}

      true ->
        do_lint_source_plan_ref(source_plan_ref, request_path, opts, source_path, artifact_key)
    end
  end

  defp do_lint_source_plan_ref(_source_plan_ref, request_path, opts, source_path, artifact_key) do
    request_dir = request_path |> Path.expand() |> Path.dirname()
    base_path = opts |> Keyword.get(:base_path, File.cwd!()) |> Path.expand()

    try do
      resolved_path = resolve_request_reference_path!(source_path, request_dir, base_path)
      artifact = resolved_path |> File.read!() |> :json.decode()

      source_artifact =
        if artifact_key do
          Map.fetch!(artifact, artifact_key)
        else
          artifact
        end

      validate_linted_source_plan(source_artifact, %{
        "status" => "pass",
        "source" => "source_plan_ref",
        "path" => resolved_path,
        "artifact_key" => artifact_key,
        "requested_path" => source_path,
        "sha256" => resolved_path |> File.read!() |> sha256()
      })
    rescue
      exception ->
        {%{
           "status" => "fail",
           "source" => "source_plan_ref",
           "path" => source_path,
           "artifact_key" => artifact_key
         },
         [
           request_lint_error(
             "source_plan_ref_error",
             "$.source_plan_ref",
             Exception.message(exception)
           )
         ]}
    end
  end

  defp validate_linted_source_plan(source_plan, source_metadata) do
    case Schema.validate_artifact(source_plan, contract: "campaign_plan.v1") do
      {:ok, _report} ->
        {source_metadata
         |> Map.put("status", "pass")
         |> Map.put("schema_contract", "campaign_plan.v1")
         |> Map.put("plan_id", source_plan_id(source_plan)), []}

      {:error, %{"errors" => errors}} ->
        message =
          errors
          |> List.first()
          |> case do
            %{"path" => path, "message" => message} -> "#{path}: #{message}"
            _error -> "source plan does not satisfy campaign_plan.v1"
          end

        {source_metadata
         |> Map.put("status", "fail")
         |> Map.put("schema_contract", "campaign_plan.v1"),
         [
           request_lint_error(
             "invalid_source_plan_contract",
             "$.source_plan_ref",
             message
           )
         ]}
    end
  end

  defp lint_status([]), do: "pass"
  defp lint_status(_errors), do: "fail"

  defp request_lint_error(code, path, message) do
    %{
      "code" => code,
      "path" => path,
      "message" => message
    }
  end

  defp sha256(content) do
    :crypto.hash(:sha256, content)
    |> Base.encode16(case: :lower)
  end

  defp source_plan_id(prior_plan) do
    Map.get(prior_plan, "plan_id") ||
      [Map.get(prior_plan, "study_id"), Map.get(prior_plan, "generated_at")]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(":")
  end

  defp get_key(nil, _key), do: nil

  defp get_key(%{} = map, key) when is_atom(key),
    do: fetch_key_or_alias(map, key, Atom.to_string(key))

  defp fetch_key_or_alias(map, key, alias_key) do
    case Map.fetch(map, key) do
      {:ok, nil} -> Map.get(map, alias_key)
      {:ok, value} -> value
      :error -> Map.get(map, alias_key)
    end
  end
end
