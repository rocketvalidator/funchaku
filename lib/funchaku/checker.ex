defmodule Funchaku.Checker do
  def check(url, options \\ []) do
    options = Keyword.merge(default_options, options)

    vnu_request_querystring(options[:checker_url], url)
    |> HTTPoison.get
    |> handle_response
  end

  defp vnu_request_querystring(checker_url, url) do
    "#{checker_url}?out=json&doc=#{url}"
  end

  defp handle_response({ :ok, %{ status_code: 200, body: body }}) do
    { :ok,    Poison.Parser.parse!(body) |> parsed_messages }
  end

  defp handle_response({ :error, %{ reason: reason } }) do
    { :error, reason }
  end

  defp parsed_messages(json) do
    messages = json["messages"]
    errors   = Enum.filter(messages, &(&1["type"]    == "error"))
    warnings = Enum.filter(messages, &(&1["subType"] == "warning"))
    extra    = (messages -- errors) -- warnings

    %{
       messages: messages,
       errors:   errors,
       warnings: warnings,
       extra:    extra
    }
  end

  defp default_options do
    [
      checker_url: "http://validator.w3.org/nu/"
    ]
  end
end
