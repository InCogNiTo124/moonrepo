#[macro_use]
extern crate rocket;
extern crate diesel;

mod models;
mod schema;

use diesel::prelude::*;
use diesel::r2d2::{self, ConnectionManager};
use rocket::fs::NamedFile;
use rocket::serde::json::Json;
use rocket::State;
use std::path::Path;

use crate::models::*;
use crate::schema::{posts, tags};

type DbPool = r2d2::Pool<ConnectionManager<SqliteConnection>>;

#[get("/posts/<post_id>/tags")]
fn get_post_tags(post_id: i32, pool: &State<DbPool>) -> Json<ApiTagList> {
    let mut conn = pool.get().expect("database connection failed");

    let db_tags = crate::schema::post_tags::table
        .filter(crate::schema::post_tags::post_id.eq(post_id))
        .inner_join(tags::table)
        .select(tags::all_columns)
        .load::<Tag>(&mut conn)
        .expect("Error loading tags");

    let api_tags: Vec<ApiTag> = db_tags.into_iter().map(ApiTag::from).collect();
    Json(ApiTagList { tags: api_tags })
}

#[get("/post/<slug>")]
fn get_post_by_slug(slug: &str, pool: &State<DbPool>) -> Json<ApiPostResponse> {
    let mut conn = pool.get().expect("database connection failed");

    let post = posts::table
        .filter(posts::slug.eq(slug))
        .first::<Post>(&mut conn)
        .expect("Error loading post");

    // Fetch tags for this post
    // Note: In a real app, you might want to do this in a single query or batch it,
    // but for a single post view, a second query is fine.
    let db_tags = crate::schema::post_tags::table
        .filter(crate::schema::post_tags::post_id.eq(post.id))
        .inner_join(tags::table)
        .select(tags::all_columns)
        .load::<Tag>(&mut conn)
        .unwrap_or_default();

    let api_post = ApiPost::from_db(post, db_tags);

    Json(ApiPostResponse { post: api_post })
}

#[get("/post/<slug>/<image>")]
async fn get_post_image(slug: &str, image: &str) -> Option<NamedFile> {
    let path = Path::new(slug).join(image);
    NamedFile::open(path).await.ok()
}

#[get("/tags/<tag_id>")]
fn get_tag(tag_id: i32, pool: &State<DbPool>) -> Json<ApiTagResponse> {
    let mut conn = pool.get().expect("database connection failed");

    let tag_name = tags::table
        .find(tag_id)
        .select(tags::tag_name)
        .first::<String>(&mut conn)
        .unwrap_or_default();

    Json(ApiTagResponse { tagName: tag_name })
}

#[get("/posts/<page>")]
fn get_post_list(page: u32, pool: &State<DbPool>) -> Json<Vec<ApiPost>> {
    let offset = 10 * (page.saturating_sub(1));
    let mut conn = pool.get().expect("database connection failed");

    let db_posts = posts::table
        .filter(posts::show.eq(true))
        .order(posts::date.desc())
        .limit(11)
        .offset(offset as i64)
        .load::<Post>(&mut conn)
        .expect("Error loading posts");

    // For the list view, we currently return empty tags as per original implementation
    // "tags: vec![]" was in the original code.
    let api_posts: Vec<ApiPost> = db_posts
        .into_iter()
        .map(|p| ApiPost::from_db(p, vec![]))
        .collect();

    Json(api_posts)
}

#[get("/filter/tags/<tag_name>?<page>")]
fn filter_posts_by_tag(
    tag_name: &str,
    page: Option<u32>,
    pool: &State<DbPool>,
) -> Json<Vec<ApiPost>> {
    let offset = 10 * (page.unwrap_or(1).saturating_sub(1));
    let mut conn = pool.get().expect("database connection failed");

    // Join posts -> post_tags -> tags
    let db_posts = posts::table
        .inner_join(crate::schema::post_tags::table.inner_join(tags::table))
        .filter(tags::tag_name.eq(tag_name))
        .filter(posts::show.eq(true))
        .order(posts::date.desc())
        .limit(11)
        .offset(offset as i64)
        .select(posts::all_columns)
        .load::<Post>(&mut conn)
        .expect("Error loading posts by tag");

    // Again, returning empty tags list for the summary view as per original
    let api_posts: Vec<ApiPost> = db_posts
        .into_iter()
        .map(|p| {
            // Original code set content to "" for this endpoint
            let mut api_p = ApiPost::from_db(p, vec![]);
            api_p.content = "".to_string();
            api_p
        })
        .collect();

    Json(api_posts)
}

#[launch]
fn rocket() -> _ {
    // rocket manages r2d2 pool
    // r2d2 pool manages the diesel connection manager
    // diesel connnection manager manages the connection to Sqlite
    let db_path = std::env::var("DB_PATH").unwrap_or_else(|_| "db.sqlite3".to_string());
    let manager = ConnectionManager::<SqliteConnection>::new(db_path);
    let pool = r2d2::Pool::builder()
        .build(manager)
        .expect("Failed to create pool.");

    rocket::build().manage(pool).mount(
        "/",
        routes![
            filter_posts_by_tag,
            get_post_by_slug,
            get_post_image,
            get_post_list,
            get_post_tags,
            get_tag,
        ],
    )
}
