module rooch_examples::blog_remove_article_logic {
    use std::vector;
    use moveos_std::object_id::ObjectID;
    use rooch_examples::article_removed_from_blog;
    use rooch_examples::blog;

    friend rooch_examples::blog_aggregate;

    public(friend) fun verify(
        //storage_ctx: &mut StorageContext,
        article_id: ObjectID,
        blog: &blog::Blog,
    ): blog::ArticleRemovedFromBlog {
        //let _ = storage_ctx;
        blog::new_article_removed_from_blog(
            blog,
            article_id,
        )
    }

    public(friend) fun mutate(
        //storage_ctx: &mut StorageContext,
        article_removed_from_blog: &blog::ArticleRemovedFromBlog,
        blog: &mut blog::Blog,
    ) {
        //let _ = storage_ctx;
        let article_id = article_removed_from_blog::article_id(article_removed_from_blog);
        let articles = blog::articles(blog);
        let (found, idx) = vector::index_of(&articles, &article_id);
        if (found) {
            vector::remove(&mut articles, idx);
            blog::set_articles(blog, articles);
        };
    }
}
