defmodule OrbitalDynamics.InputIntegrity do
  @moduledoc """
  Exact-byte content-identity verification for opt-in file input boundaries.

  The caller supplies a lowercase SHA-256 digest out of band. Verification
  returns the bytes that were hashed so consumers do not reopen the path between
  checking its identity and parsing it.
  """

  @sha256_regex ~r/\A[0-9a-f]{64}\z/
  @assumptions [
    "the caller obtained the declared digest independently of the file read",
    "the exact bytes returned by verification are the bytes consumed"
  ]
  @known_limits [
    "sha256 content identity does not authenticate the declaring authority",
    "no signature verification",
    "no file sandboxing or path authorization"
  ]

  @doc """
  Declares the narrow file-content verification behavior and its limits.
  """
  def capabilities do
    %{
      "algorithm" => "sha256",
      "digest_encoding" => "lowercase_hex",
      "verification_scope" => "exact_file_bytes",
      "verification_order" => "before_parse_or_consume",
      "assumptions" => @assumptions,
      "known_limits" => @known_limits
    }
  end

  @doc """
  Verifies a file against `%{"sha256" => lowercase_hex_digest}`.

  On success the returned `:bytes` are the exact bytes that were hashed and the
  `:evidence` map is deterministic for the same path, consumer, identity, and
  content. Failures include the same evidence shape under
  `{:input_content_verification_failed, evidence}`.
  """
  def verify_file(path, content_identity, opts \\ [])

  def verify_file(path, content_identity, opts) when is_binary(path) and is_list(opts) do
    consumer = Keyword.get(opts, :consumer, "file_input")

    case declared_sha256(content_identity) do
      {:ok, expected_sha256} ->
        verify_read_bytes(path, expected_sha256, consumer)

      {:error, reason, declared_sha256} ->
        verification_error(path, consumer, reason, declared_sha256)
    end
  end

  def verify_file(path, content_identity, opts) do
    consumer =
      if is_list(opts), do: Keyword.get(opts, :consumer, "file_input"), else: "file_input"

    verification_error(
      inspect(path),
      consumer,
      "invalid_path",
      identity_sha256(content_identity)
    )
  end

  defp verify_read_bytes(path, expected_sha256, consumer) do
    case File.read(path) do
      {:ok, bytes} ->
        actual_sha256 = sha256(bytes)

        if actual_sha256 == expected_sha256 do
          {:ok,
           %{
             bytes: bytes,
             evidence:
               evidence(path, consumer, "pass", "content_identity_match", expected_sha256,
                 actual_sha256: actual_sha256,
                 byte_count: byte_size(bytes)
               )
           }}
        else
          verification_error(path, consumer, "sha256_mismatch", expected_sha256,
            actual_sha256: actual_sha256,
            byte_count: byte_size(bytes)
          )
        end

      {:error, reason} ->
        verification_error(path, consumer, "file_read_error", expected_sha256,
          file_error: Atom.to_string(reason)
        )
    end
  end

  defp verification_error(path, consumer, reason, expected_sha256, opts \\ []) do
    {:error,
     {:input_content_verification_failed,
      evidence(path, consumer, "fail", reason, expected_sha256, opts)}}
  end

  defp evidence(path, consumer, status, reason, expected_sha256, opts) do
    actual_sha256 = Keyword.get(opts, :actual_sha256)
    byte_count = Keyword.get(opts, :byte_count)
    file_error = Keyword.get(opts, :file_error)

    %{
      "verification_id" => verification_id(consumer, path, expected_sha256),
      "consumer" => consumer,
      "status" => status,
      "reason" => reason,
      "message" => evidence_message(reason, file_error),
      "path" => path,
      "algorithm" => "sha256",
      "expected_sha256" => expected_sha256,
      "actual_sha256" => actual_sha256,
      "byte_count" => byte_count,
      "file_error" => file_error,
      "verification_scope" => "exact_file_bytes",
      "verified_before_consumption" => status == "pass",
      "assumptions" => @assumptions,
      "known_limits" => @known_limits
    }
  end

  defp declared_sha256(nil), do: {:error, "missing_content_identity", nil}

  defp declared_sha256(%{} = content_identity) do
    values =
      [:sha256, "sha256"]
      |> Enum.flat_map(fn key ->
        case Map.fetch(content_identity, key) do
          {:ok, value} -> [value]
          :error -> []
        end
      end)
      |> Enum.uniq()

    case values do
      [] -> {:error, "missing_sha256", nil}
      [sha256] when is_binary(sha256) -> validate_sha256(sha256)
      [_sha256] -> {:error, "malformed_sha256", identity_sha256(content_identity)}
      _values -> {:error, "conflicting_sha256", identity_sha256(content_identity)}
    end
  end

  defp declared_sha256(content_identity),
    do: {:error, "malformed_content_identity", identity_sha256(content_identity)}

  defp validate_sha256(sha256) do
    if Regex.match?(@sha256_regex, sha256) do
      {:ok, sha256}
    else
      {:error, "malformed_sha256", sha256}
    end
  end

  defp identity_sha256(%{} = identity),
    do: Map.get(identity, "sha256") || Map.get(identity, :sha256)

  defp identity_sha256(_identity), do: nil

  defp verification_id(consumer, path, expected_sha256) do
    if is_binary(expected_sha256) and Regex.match?(@sha256_regex, expected_sha256) do
      "file_content_verification:#{consumer}:sha256:#{expected_sha256}"
    else
      suffix =
        sha256(Enum.join([to_string(consumer), to_string(path), inspect(expected_sha256)], "\0"))

      "file_content_verification:#{consumer}:unverified:#{binary_part(suffix, 0, 16)}"
    end
  end

  defp evidence_message("content_identity_match", _file_error),
    do: "file bytes match the declared sha256 content identity"

  defp evidence_message("sha256_mismatch", _file_error),
    do: "file bytes do not match the declared sha256 content identity"

  defp evidence_message("missing_content_identity", _file_error),
    do: "content_identity is required for this file-backed input"

  defp evidence_message("missing_sha256", _file_error),
    do: "content_identity.sha256 is required for this file-backed input"

  defp evidence_message("malformed_sha256", _file_error),
    do: "content_identity.sha256 must be a lowercase 64-character hex digest"

  defp evidence_message("conflicting_sha256", _file_error),
    do: "content_identity has conflicting atom and string sha256 values"

  defp evidence_message("malformed_content_identity", _file_error),
    do: "content_identity must be an object containing sha256"

  defp evidence_message("file_read_error", file_error),
    do: "could not read file bytes: #{file_error}"

  defp evidence_message("invalid_path", _file_error), do: "path must be a string"

  defp sha256(bytes) do
    :crypto.hash(:sha256, bytes)
    |> Base.encode16(case: :lower)
  end
end
