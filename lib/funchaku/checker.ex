defmodule Funchaku.Checker do
  def check(url) do
    validator_url(url)
    |> HTTPoison.get
    |> handle_response
  end

  def validator_url(url) do
    "http://validator.w3.org/nu/?out=json&doc=#{url}"
  end

  def handle_response({ :ok, %{status_code: 200, body: body }}) do
    { :ok,    Poison.Parser.parse!(body) |> parsed_messages }
  end

  def handle_response({ _,   %{status_code: _,   body: body}}) do
    { :error, Poison.Parser.parse!(body) }
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
end
