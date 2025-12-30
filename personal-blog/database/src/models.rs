use diesel::prelude::*;
use rocket::serde::Serialize;

// --- Database Models (Diesel) ---

#[derive(Queryable, Selectable, Identifiable, Debug, Clone)]
#[diesel(table_name = crate::schema::posts)]
pub struct Post {
    pub id: i32,
    pub date: String,
    pub title: String,
    pub subtitle: String,
    pub content: String,
    pub show: bool,
    pub slug: String,
}

#[derive(Queryable, Selectable, Identifiable, Debug, Clone)]
#[diesel(table_name = crate::schema::tags)]
pub struct Tag {
    pub id: i32,
    pub tag_name: String,
}

#[derive(Queryable, Selectable, Identifiable, Associations, Debug, Clone)]
#[diesel(belongs_to(Post))]
#[diesel(belongs_to(Tag))]
#[diesel(table_name = crate::schema::post_tags)]
#[diesel(primary_key(post_id, tag_id))]
pub struct PostTag {
    pub post_id: i32,
    pub tag_id: i32,
}

// --- API Response Models (JSON) ---

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct ApiTagList {
    pub tags: Vec<String>,
}

#[derive(Serialize, Clone)]
#[serde(crate = "rocket::serde")]
pub struct ApiPost {
    pub date: String,
    pub title: String,
    pub subtitle: String,
    pub content: String,
    pub tags: Vec<String>,
    pub slug: String,
}

#[derive(Serialize, Clone)]
#[serde(crate = "rocket::serde")]
pub struct ApiPostResponse {
    pub post: ApiPost,
}

#[derive(Serialize, Clone)]
#[serde(crate = "rocket::serde")]
#[allow(non_snake_case)]
pub struct ApiTagResponse {
    pub tagName: String,
}

// --- Conversion Helpers ---

impl ApiPost {
    pub fn from_db(post: Post, tags: Vec<Tag>) -> Self {
        Self {
            date: post.date,
            title: post.title,
            subtitle: post.subtitle,
            content: post.content,
            tags: tags.into_iter().map(|t| t.tag_name).collect(),
            slug: post.slug,
        }
    }
}
