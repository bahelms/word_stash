# Word Stash

Save your articles for later! (without worrying about them being deleted)

(also LLM enhanced!)

## Dev TODO
- Remove newsletter query param from article urls
- After submitting url, go to show page
    - Background job starts for processing
    - add achived_at field
    - add status field enum: pending, pending_ai, complete
    - Add Read, Archive, and Delete buttons
- Click article card on index page -> show article
- Article processing: generate tags, summary, author, published_at
- Host LLM
