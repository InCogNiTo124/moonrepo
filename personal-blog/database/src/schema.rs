diesel::table! {
    posts (id) {
        id -> Integer,
        date -> Text,
        title -> Text,
        subtitle -> Text,
        content -> Text,
        show -> Bool,
        slug -> Text,
    }
}

diesel::table! {
    tags (id) {
        id -> Integer,
        tag_name -> Text,
    }
}

diesel::table! {
    post_tags (post_id, tag_id) {
        post_id -> Integer,
        tag_id -> Integer,
    }
}

diesel::joinable!(post_tags -> posts (post_id));
diesel::joinable!(post_tags -> tags (tag_id));

diesel::allow_tables_to_appear_in_same_query!(posts, tags, post_tags,);
