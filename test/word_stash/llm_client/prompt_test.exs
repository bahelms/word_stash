defmodule WordStash.LLMClient.PromptTest do
  use ExUnit.Case, async: true

  alias WordStash.LLMClient.Prompt

  describe "Prompt.build_analysis_prompt/2" do
    test "includes URL and HTML content" do
      html = "<html><body>Test content</body></html>"
      url = "https://example.com/article"

      prompt = Prompt.build_analysis_prompt(html, url)

      assert prompt =~ url
      assert prompt =~ "Test content"
      assert prompt =~ "JSON"
    end

    test "truncates long HTML content" do
      long_html = String.duplicate("a", 20_000)
      url = "https://example.com/article"

      prompt = Prompt.build_analysis_prompt(long_html, url)

      assert prompt =~ "[Content truncated...]"
      assert String.length(prompt) < 20_000
    end

    test "cleans HTML before truncating" do
      html = """
      <html>
        <script>console.log('test');</script>
        <body>
          <p>Article content</p>
        </body>
      </html>
      """

      prompt = Prompt.build_analysis_prompt(html, "https://example.com")

      refute prompt =~ "console.log"
      assert prompt =~ "Article content"
    end
  end

  describe "Prompt.clean_html/1" do
    test "removes script tags and content" do
      html = """
      <html>
        <body>
          <p>Article content</p>
          <script>console.log('tracking');</script>
          <p>More content</p>
        </body>
      </html>
      """

      result = Prompt.clean_html(html)

      refute result =~ "script"
      refute result =~ "console.log"
      assert result =~ "Article content"
      assert result =~ "More content"
    end

    test "removes style tags and content" do
      html = """
      <html>
        <style>body { color: red; }</style>
        <body><p>Content</p></body>
      </html>
      """

      result = Prompt.clean_html(html)

      refute result =~ "style"
      refute result =~ "color: red"
      assert result =~ "Content"
    end

    test "removes navigation, header, footer, and aside tags" do
      html = """
      <html>
        <header><nav>Menu items</nav></header>
        <main>
          <article>Article content</article>
          <aside>Sidebar ads</aside>
        </main>
        <footer>Copyright info</footer>
      </html>
      """

      result = Prompt.clean_html(html)

      refute result =~ "Menu items"
      refute result =~ "Sidebar ads"
      refute result =~ "Copyright info"
      assert result =~ "Article content"
    end

    test "removes iframe and noscript tags" do
      html = """
      <html>
        <body>
          <p>Content</p>
          <iframe src="ads.html">Ad content</iframe>
          <noscript>Please enable JavaScript</noscript>
        </body>
      </html>
      """

      result = Prompt.clean_html(html)

      refute result =~ "iframe"
      refute result =~ "Ad content"
      refute result =~ "noscript"
      refute result =~ "enable JavaScript"
      assert result =~ "Content"
    end

    test "removes SVG graphics" do
      html = """
      <html>
        <body>
          <p>Content</p>
          <svg width="100" height="100">
            <circle cx="50" cy="50" r="40" />
          </svg>
        </body>
      </html>
      """

      result = Prompt.clean_html(html)

      refute result =~ "svg"
      refute result =~ "circle"
      assert result =~ "Content"
    end

    test "removes HTML comments" do
      html = """
      <html>
        <!-- This is a comment -->
        <body>
          <p>Content</p>
          <!-- TODO: Add more content -->
        </body>
      </html>
      """

      result = Prompt.clean_html(html)

      refute result =~ "<!--"
      refute result =~ "This is a comment"
      refute result =~ "TODO"
      assert result =~ "Content"
    end

    test "collapses whitespace and newlines" do
      html = """
      <html>
        <body>


          <p>Content    with    spaces</p>


        </body>
      </html>
      """

      result = Prompt.clean_html(html)

      # Should have single spaces, not multiple
      refute result =~ "  "
      assert result =~ "Content with spaces"
    end

    test "keeps useful content tags" do
      html = """
      <html>
        <head>
          <title>Article Title</title>
          <meta name="author" content="John Doe">
        </head>
        <body>
          <article>
            <h1>Main Heading</h1>
            <p>First paragraph with <strong>bold</strong> text.</p>
            <h2>Subheading</h2>
            <p>Second paragraph with <a href="#">link</a>.</p>
            <time datetime="2024-01-01">January 1, 2024</time>
          </article>
        </body>
      </html>
      """

      result = Prompt.clean_html(html)

      assert result =~ "Article Title"
      assert result =~ "author"
      assert result =~ "John Doe"
      assert result =~ "Main Heading"
      assert result =~ "First paragraph"
      assert result =~ "bold"
      assert result =~ "Subheading"
      assert result =~ "link"
      assert result =~ "2024-01-01"
    end

    test "handles nested tags correctly" do
      html = """
      <html>
        <body>
          <div>
            <nav>
              <ul>
                <li><a href="#">Link</a></li>
              </ul>
            </nav>
            <p>Keep this</p>
          </div>
        </body>
      </html>
      """

      result = Prompt.clean_html(html)

      refute result =~ "<nav"
      refute result =~ "Link"
      assert result =~ "Keep this"
    end

    test "handles case-insensitive tag matching" do
      html = """
      <HTML>
        <SCRIPT>alert('test');</SCRIPT>
        <P>Content</P>
      </HTML>
      """

      result = Prompt.clean_html(html)

      refute result =~ "alert"
      assert result =~ "Content"
    end

    test "handles self-closing tags with attributes" do
      html = """
      <html>
        <body>
          <p>Content</p>
          <script src="external.js" type="text/javascript"></script>
        </body>
      </html>
      """

      result = Prompt.clean_html(html)

      refute result =~ "script"
      refute result =~ "external.js"
      assert result =~ "Content"
    end

    test "handles non-string input" do
      assert Prompt.clean_html(nil) == ""
      assert Prompt.clean_html(123) == ""
    end

    test "significantly reduces HTML size for typical web page" do
      html = """
      <!DOCTYPE html>
      <html>
        <head>
          <title>Article Title</title>
          <script src="analytics.js"></script>
          <style>
            body { font-family: Arial; }
            .container { max-width: 1200px; }
          </style>
        </head>
        <body>
          <header>
            <nav>
              <ul>
                <li><a href="/">Home</a></li>
                <li><a href="/about">About</a></li>
              </ul>
            </nav>
          </header>
          <main>
            <article>
              <h1>Important Article</h1>
              <p>This is the actual content we care about.</p>
            </article>
            <aside>
              <h3>Related Articles</h3>
              <ul><li>Article 1</li></ul>
            </aside>
          </main>
          <footer>
            <p>&copy; 2024 Example.com</p>
            <nav>
              <a href="/privacy">Privacy</a>
            </nav>
          </footer>
        </body>
      </html>
      """

      result = Prompt.clean_html(html)

      # Should be significantly smaller
      assert String.length(result) < String.length(html) / 2

      # Should keep important content
      assert result =~ "Article Title"
      assert result =~ "Important Article"
      assert result =~ "actual content we care about"

      # Should remove noise
      refute result =~ "analytics.js"
      refute result =~ "font-family"
      refute result =~ "Home"
      refute result =~ "About"
      refute result =~ "Related Articles"
      refute result =~ "Privacy"
    end
  end

  describe "Prompt.truncate_html/1" do
    test "returns HTML as-is if under limit" do
      short_html = String.duplicate("a", 1000)
      assert Prompt.truncate_html(short_html) == short_html
    end

    test "truncates HTML if over limit" do
      long_html = String.duplicate("a", 20_000)
      result = Prompt.truncate_html(long_html)

      assert result =~ "[Content truncated...]"
      assert String.length(result) < String.length(long_html)
    end

    test "handles non-string input" do
      assert Prompt.truncate_html(nil) == ""
      assert Prompt.truncate_html(123) == ""
    end
  end
end
