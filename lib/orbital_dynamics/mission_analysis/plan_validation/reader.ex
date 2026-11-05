defmodule OrbitalDynamics.MissionAnalysis.PlanValidation.Reader do
  @moduledoc false
  @limit 64 * 1024 * 1024
  def read(path) do
    with {:ok, stat} <- File.stat(path),
         true <- stat.size <= @limit,
         {:ok, bytes} <- File.read(path),
         true <- byte_size(bytes) <= @limit do
      decoders = %{
        object_start: fn _ -> %{} end,
        object_push: fn key, value, object ->
          if Map.has_key?(object, key), do: throw({:invalid_json, "duplicate JSON key"})
          Map.put(object, key, value)
        end,
        object_finish: fn object, state -> {object, state} end
      }

      case :json.decode(bytes, :root, decoders) do
        {%{} = value, :root, <<>>} -> {:ok, value}
        _ -> {:error, "one JSON object required"}
      end
    else
      false -> {:error, "artifact exceeds 64 MiB"}
      {:error, reason} -> {:error, "cannot read artifact: #{inspect(reason)}"}
    end
  rescue
    _ in [ArgumentError, ErlangError] -> {:error, "malformed JSON artifact"}
  catch
    {:invalid_json, message} -> {:error, message}
  end
end
