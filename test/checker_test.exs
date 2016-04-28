defmodule CheckerTest do
  use ExUnit.Case
  import Funchaku.Checker, only: [ check: 1 ]

  test "validates a URL" do
    { status, results } = check "http://validationhell.com"

    assert status == :ok

    messages = [ first_message | _ ] = results[:messages]
    errors   = [ first_error   | _ ] = results[:errors]

    assert length(messages) == 11
    assert length(errors)   == 11

    message = %{ "extract"     => " href=\"/\"><img\n src=\"/images/fire.png\" align=\"absmiddle\" width=\"30\" hspace=\"5\"><stron",
                 "firstColumn" => 37, "firstLine" => 55, "hiliteLength" => 69,
                 "hiliteStart" => 10, "lastColumn" => 64, "lastLine" => 56,
                 "message"     => "The “align” attribute on the “img” element is obsolete. Use CSS instead.",
                 "type"        => "error" }

    assert first_message == message
    assert first_error   == message
  end
end
