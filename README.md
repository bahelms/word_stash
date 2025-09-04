# Word Stash

Save your articles for later! (without worrying about them being deleted) (also LLM enhanced!)

## Dev setup
### AI

    docker build . -t word_stash_ai
    docker run --rm -p 8080:8080 word_stash_ai

Test it with 

    curl -X POST localhost:8080 \ 
        -H "Content-Type: application/json" \ 
        -d '{"url":"https://example.com/some-blog-post"}'


## Dev TODO
- Click article card -> show article
    - move visit to show page
- Article: add tags, summary, status (pending, complete), author, published_at, archived_at
- Delete article
- Archive article
- Host LLM
