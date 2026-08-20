defmodule OrbitalDynamics.CadenceImport.OuterAdmission do
  @moduledoc """
  Finite whole-input admission for Domain 20 Cadence consumer dry runs.

  The checked V3 artifact is larger than the generic JSON-safety aggregate and
  collection budgets, so this boundary first applies fixed outer limits and
  then reuses `OrbitalDynamics.Schema.JsonSafety` on bounded segments. Only the
  known large V3 collections are segmented: campaign branches, embedded
  manifest rows, operator-review rows, and score-term rows. Unknown fields are
  validated as ordinary values and retain the generic 2,048-item collection
  limit.

  Work is finite: external term size, top-level fields, known collection
  lengths, segment map sizes, and the total number of segments are all capped
  before segment validation. List counting stops at the configured limit plus
  one; this module does not introduce an unbounded recursive term walker.
  """

  alias OrbitalDynamics.Schema.JsonSafety

  @campaign_contract "campaign_strategy.v3"
  @manifest_contract "cadence_import_manifest.v1"
  @max_external_size_bytes 67_108_864
  @max_top_level_fields 64
  @max_campaign_branches 64
  @max_manifest_rows 4_096
  @max_operator_review_rows 4_096
  @max_score_term_rows 4_096
  @max_segment_map_fields 2_048
  @max_validation_work_items 16_384

  @doc "Returns the fixed Domain 20 whole-input admission limits."
  def limits do
    %{
      "max_external_size_bytes" => @max_external_size_bytes,
      "max_top_level_fields" => @max_top_level_fields,
      "max_campaign_branches" => @max_campaign_branches,
      "max_manifest_rows" => @max_manifest_rows,
      "max_operator_review_rows" => @max_operator_review_rows,
      "max_score_term_rows" => @max_score_term_rows,
      "max_segment_map_fields" => @max_segment_map_fields,
      "max_validation_work_items" => @max_validation_work_items,
      "segment_json_safety" => JsonSafety.limits()
    }
  end

  @doc "Validates the complete outer term before schema inference or delegation."
  @spec validate(term()) :: :ok | {:error, map()}
  def validate(input) do
    try do
      validate_input(input)
    rescue
      _exception ->
        failure(
          "unsafe_outer_input",
          "Cadence dry-run outer input admission did not complete",
          %{}
        )
    catch
      _kind, _reason ->
        failure(
          "unsafe_outer_input",
          "Cadence dry-run outer input admission did not complete",
          %{}
        )
    end
  end

  defp validate_input(%_module{}) do
    failure("invalid_outer_input", "Cadence dry-run input must be a plain JSON map", %{})
  end

  defp validate_input(%{} = input) do
    with :ok <- validate_external_size(input),
         :ok <- validate_map_shape(input, "$", @max_top_level_fields),
         {:ok, work_items} <- validation_work_items(input),
         :ok <- validate_work_limit(work_items) do
      validate_segments(input)
    end
  end

  defp validate_input(_input) do
    failure("invalid_outer_input", "Cadence dry-run input must be a JSON map", %{})
  end

  defp validate_external_size(input) do
    size = :erlang.external_size(input)

    if size <= @max_external_size_bytes do
      :ok
    else
      failure("unsafe_outer_input", "Cadence dry-run input exceeds its outer size limit", %{
        "actual_external_size_bytes" => size,
        "max_external_size_bytes" => @max_external_size_bytes,
        "path" => "$"
      })
    end
  end

  defp validate_map_shape(%{} = map, path, max_fields) do
    cond do
      is_struct(map) ->
        failure("unsafe_outer_input", "outer input contains an unsupported struct", %{
          "path" => path
        })

      map_size(map) > max_fields ->
        failure("unsafe_outer_input", "outer input map exceeds its field limit", %{
          "actual_field_count" => map_size(map),
          "max_field_count" => max_fields,
          "path" => path
        })

      true ->
        validate_map_keys(map, path)
    end
  end

  defp validate_map_keys(map, path) do
    with {:ok, normalized_keys} <- normalize_map_keys(Map.keys(map), path) do
      if length(normalized_keys) == length(Enum.uniq(normalized_keys)) do
        :ok
      else
        failure(
          "unsafe_outer_input",
          "outer input contains duplicate atom/string keys after normalization",
          %{"path" => path}
        )
      end
    end
  end

  defp normalize_map_keys(keys, path) do
    Enum.reduce_while(keys, {:ok, []}, fn key, {:ok, normalized} ->
      case normalize_key(key) do
        {:ok, value} -> {:cont, {:ok, [value | normalized]}}
        :error -> {:halt, invalid_map_key(path)}
      end
    end)
  end

  defp normalize_key(key) when is_atom(key), do: {:ok, Atom.to_string(key)}

  defp normalize_key(key) when is_binary(key) do
    if String.valid?(key), do: {:ok, key}, else: :error
  end

  defp normalize_key(_key), do: :error

  defp invalid_map_key(path) do
    failure("unsafe_outer_input", "outer input map keys must be valid UTF-8 strings", %{
      "path" => path
    })
  end

  defp validation_work_items(input) do
    base = map_size(input)

    cond do
      campaign_artifact?(input) ->
        campaign_work_items(input, base)

      input["schema_contract"] == @manifest_contract ->
        row_container_work(input, base, "$", @max_manifest_rows)

      true ->
        {:ok, base}
    end
  end

  defp campaign_work_items(input, base) do
    with {:ok, branch_work} <- branches_work(Map.get(input, "branches")),
         {:ok, manifest_work} <-
           row_container_work(
             Map.get(input, "cadence_import_manifest"),
             0,
             "$.cadence_import_manifest",
             @max_manifest_rows
           ),
         {:ok, review_work} <-
           row_container_work(
             Map.get(input, "operator_review_package"),
             0,
             "$.operator_review_package",
             @max_operator_review_rows
           ),
         {:ok, score_work} <-
           row_container_work(
             Map.get(input, "score_term_report"),
             0,
             "$.score_term_report",
             @max_score_term_rows
           ) do
      {:ok, base + branch_work + manifest_work + review_work + score_work}
    end
  end

  defp branches_work(nil), do: {:ok, 0}
  defp branches_work(:null), do: {:ok, 0}

  defp branches_work(branches) do
    with {:ok, count} <- bounded_list_count(branches, @max_campaign_branches, "$.branches") do
      Enum.reduce_while(branches, {:ok, count}, fn branch, {:ok, work} ->
        case branch_work(branch) do
          {:ok, branch_items} -> {:cont, {:ok, work + branch_items}}
          {:error, _failure} = error -> {:halt, error}
        end
      end)
    end
  end

  defp branch_work(%{} = branch) do
    with :ok <- validate_map_shape(branch, "$.branches[]", @max_segment_map_fields),
         {:ok, repair_items} <- repair_work(Map.get(branch, "repair_result")) do
      {:ok, map_size(branch) + repair_items}
    end
  end

  defp branch_work(_branch), do: {:ok, 1}

  defp repair_work(%{} = repair) do
    case validate_map_shape(repair, "$.branches[].repair_result", @max_segment_map_fields) do
      :ok -> {:ok, map_size(repair)}
      {:error, _failure} = error -> error
    end
  end

  defp repair_work(_repair), do: {:ok, 0}

  defp row_container_work(nil, base, _path, _limit), do: {:ok, base}
  defp row_container_work(:null, base, _path, _limit), do: {:ok, base}

  defp row_container_work(%{} = container, base, path, limit) do
    with :ok <- validate_map_shape(container, path, @max_segment_map_fields),
         {:ok, row_count} <- row_count(container, path, limit) do
      {:ok, base + map_size(container) + row_count}
    end
  end

  defp row_container_work(_container, base, _path, _limit), do: {:ok, base + 1}

  defp row_count(container, path, limit) do
    if Map.has_key?(container, "rows") do
      bounded_list_count(container["rows"], limit, path <> ".rows")
    else
      {:ok, 0}
    end
  end

  defp bounded_list_count(value, limit, path), do: count_list(value, 0, limit, path)

  defp count_list([], count, _limit, _path), do: {:ok, count}

  defp count_list([_head | tail], count, limit, path) when count < limit,
    do: count_list(tail, count + 1, limit, path)

  defp count_list([_head | _tail], limit, limit, path) do
    failure("unsafe_outer_input", "outer input collection exceeds its item limit", %{
      "actual_item_count_at_least" => limit + 1,
      "max_item_count" => limit,
      "path" => path
    })
  end

  defp count_list(_improper_tail, _count, _limit, path) do
    failure("unsafe_outer_input", "outer input contains an improper list", %{"path" => path})
  end

  defp validate_work_limit(work_items) do
    if work_items <= @max_validation_work_items do
      :ok
    else
      failure("unsafe_outer_input", "outer input exceeds its validation work limit", %{
        "actual_validation_work_items" => work_items,
        "max_validation_work_items" => @max_validation_work_items,
        "path" => "$"
      })
    end
  end

  defp validate_segments(input) do
    cond do
      campaign_artifact?(input) ->
        validate_campaign_segments(input)

      input["schema_contract"] == @manifest_contract ->
        validate_row_container(input, "$", @max_manifest_rows)

      true ->
        validate_segment(input, "$")
    end
  end

  defp campaign_artifact?(input) do
    input["schema_contract"] == @campaign_contract or
      (input["schema_version"] == 3 and
         input["planner"] == "OrbitalDynamics.CampaignPlanner.V3")
  end

  defp validate_campaign_segments(input) do
    input
    |> sorted_entries()
    |> Enum.reduce_while(:ok, fn
      {"branches", branches}, :ok ->
        continue(validate_branches(branches))

      {"cadence_import_manifest", manifest}, :ok ->
        continue(
          validate_row_container(manifest, "$.cadence_import_manifest", @max_manifest_rows)
        )

      {"operator_review_package", package}, :ok ->
        continue(
          validate_row_container(
            package,
            "$.operator_review_package",
            @max_operator_review_rows
          )
        )

      {"score_term_report", report}, :ok ->
        continue(validate_row_container(report, "$.score_term_report", @max_score_term_rows))

      {key, value}, :ok ->
        continue(validate_segment(%{key => value}, "$"))
    end)
  end

  defp validate_branches(branches) do
    with {:ok, _count} <-
           bounded_list_count(branches, @max_campaign_branches, "$.branches") do
      branches
      |> Enum.with_index()
      |> Enum.reduce_while(:ok, fn {branch, index}, :ok ->
        continue(validate_branch(branch, "$.branches[#{index}]"))
      end)
    end
  end

  defp validate_branch(%{} = branch, path) do
    repair = Map.get(branch, "repair_result")
    envelope = if plain_map?(repair), do: Map.put(branch, "repair_result", %{}), else: branch

    with :ok <- validate_map_shape(branch, path, @max_segment_map_fields),
         :ok <- validate_segment(envelope, path) do
      validate_repair(repair, path <> ".repair_result")
    end
  end

  defp validate_branch(branch, path), do: validate_segment(branch, path)

  defp validate_repair(repair, path) do
    if plain_map?(repair) do
      with :ok <- validate_map_shape(repair, path, @max_segment_map_fields) do
        repair
        |> sorted_entries()
        |> Enum.reduce_while(:ok, fn {key, value}, :ok ->
          continue(validate_segment(%{key => value}, path))
        end)
      end
    else
      :ok
    end
  end

  defp validate_row_container(container, path, limit) do
    if plain_map?(container) do
      rows = Map.get(container, "rows")

      envelope =
        if Map.has_key?(container, "rows"), do: Map.put(container, "rows", []), else: container

      with :ok <- validate_map_shape(container, path, @max_segment_map_fields),
           :ok <- validate_segment(envelope, path) do
        validate_rows(rows, path <> ".rows", limit)
      end
    else
      validate_segment(container, path)
    end
  end

  defp validate_rows(nil, _path, _limit), do: :ok
  defp validate_rows(:null, _path, _limit), do: :ok

  defp validate_rows(rows, path, limit) do
    with {:ok, _count} <- bounded_list_count(rows, limit, path) do
      rows
      |> Enum.with_index()
      |> Enum.reduce_while(:ok, fn {row, index}, :ok ->
        continue(validate_segment(row, "#{path}[#{index}]"))
      end)
    end
  end

  defp validate_segment(value, path) do
    case JsonSafety.errors(value, path) do
      [] ->
        :ok

      [issue | _issues] ->
        failure("unsafe_outer_input", "outer input contains unsafe or unbounded JSON data", %{
          "issue" => issue
        })
    end
  end

  defp sorted_entries(map) do
    map
    |> Enum.map(fn {key, value} -> {{normalized_sort_key(key), key}, value} end)
    |> Enum.sort_by(fn {{sort_key, _key}, _value} -> sort_key end)
    |> Enum.map(fn {{_sort_key, key}, value} -> {key, value} end)
  end

  defp normalized_sort_key(key) when is_atom(key), do: Atom.to_string(key)
  defp normalized_sort_key(key) when is_binary(key), do: key
  defp normalized_sort_key(_key), do: ""

  defp plain_map?(value), do: is_map(value) and not is_struct(value)

  defp continue(:ok), do: {:cont, :ok}
  defp continue({:error, _failure} = error), do: {:halt, error}

  defp failure(code, message, details) do
    {:error, %{"code" => code, "message" => message, "details" => details}}
  end
end
