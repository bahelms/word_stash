defmodule WordStash.HTMLParserTest do
  use ExUnit.Case, async: true

  alias WordStash.HTMLParser

  describe "extract_title/1" do
    test "successfully extracts title from HTML" do
      html = """
      <!DOCTYPE html>
      <html>
        <head>
          <title>Test Page Title</title>
        </head>
        <body>
          <h1>Hello World</h1>
        </body>
      </html>
      """

      assert {:ok, "Test Page Title"} = HTMLParser.extract_title(html)
    end

    test "handles empty title" do
      html = """
      <!DOCTYPE html>
      <html>
        <head>
          <title></title>
        </head>
        <body>
          <h1>Hello World</h1>
        </body>
      </html>
      """

      assert {:error, "Empty title"} = HTMLParser.extract_title(html)
    end

    test "handles missing title tag" do
      html = """
      <!DOCTYPE html>
      <html>
        <head>
        </head>
        <body>
          <h1>Hello World</h1>
        </body>
      </html>
      """

      assert {:error, "No title found"} = HTMLParser.extract_title(html)
    end

    test "handles title with attributes" do
      html = """
      <!DOCTYPE html>
      <html>
        <head>
          <title lang="en">Title with Attributes</title>
        </head>
        <body>
          <h1>Hello World</h1>
        </body>
      </html>
      """

      assert {:ok, "Title with Attributes"} = HTMLParser.extract_title(html)
    end

    test "trims whitespace from title" do
      html = """
      <!DOCTYPE html>
      <html>
        <head>
          <title>  Title with Spaces  </title>
        </head>
        <body>
          <h1>Hello World</h1>
        </body>
      </html>
      """

      assert {:ok, "Title with Spaces"} = HTMLParser.extract_title(html)
    end
  end
end
