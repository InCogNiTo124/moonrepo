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
use std::collections::HashMap;
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

    let api_tags: Vec<String> = db_tags.into_iter().map(|t| t.tag_name).collect();
    Json(ApiTagList { tags: api_tags })
}

#[get("/post/<slug>")]
fn get_post_by_slug(slug: &str, pool: &State<DbPool>) -> Json<ApiPostResponse> {
    let mut conn = pool.get().expect("database connection failed");

    // Single query: Join posts -> post_tags -> tags
    let results = posts::table
        .left_join(crate::schema::post_tags::table.inner_join(tags::table))
        .filter(posts::slug.eq(slug))
        .select((posts::all_columns, Option::<Tag>::as_select()))
        .load::<(Post, Option<Tag>)>(&mut conn)
        .expect("Error loading post");

    if results.is_empty() {
        // In a real app, return 404. Here we panic/error as per original behavior expectation
        panic!("Post not found");
    }

    // Grouping logic: The post is the same for all rows, tags vary
    let (post, tags): (Post, Vec<Tag>) = results.into_iter().fold(
        (
            Post {
                id: 0,
                date: "".to_string(),
                title: "".to_string(),
                subtitle: "".to_string(),
                content: "".to_string(),
                show: false,
                slug: "".to_string(),
            },
            vec![],
        ),
        |mut acc, (p, t)| {
            if acc.0.id == 0 {
                acc.0 = p;
            }
            if let Some(tag) = t {
                acc.1.push(tag);
            }
            acc
        },
    );

    let api_post = ApiPost::from_db(post, tags);

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

#[get("/feed.rss")]
async fn get_rss_feed() -> Option<NamedFile> {
    NamedFile::open("feed.rss").await.ok()
}

fn attach_tags(conn: &mut SqliteConnection, posts: Vec<Post>) -> Vec<ApiPost> {
    let post_ids: Vec<i32> = posts.iter().map(|p| p.id).collect();

    let tags_data: Vec<(i32, Tag)> = crate::schema::post_tags::table
        .inner_join(tags::table)
        .filter(crate::schema::post_tags::post_id.eq_any(&post_ids))
        .select((crate::schema::post_tags::post_id, tags::all_columns))
        .load::<(i32, Tag)>(conn)
        .unwrap_or_default();

    let mut tags_map: HashMap<i32, Vec<Tag>> = HashMap::new();
    for (pid, tag) in tags_data {
        tags_map.entry(pid).or_default().push(tag);
    }

    posts
        .into_iter()
        .map(|p| {
            let p_tags = tags_map.remove(&p.id).unwrap_or_default();
            ApiPost::from_db(p, p_tags)
        })
        .collect()
}

#[get("/posts/<page>")]
fn get_post_list(page: u32, pool: &State<DbPool>) -> Json<Vec<ApiPost>> {
    let offset = 10 * (page.saturating_sub(1));
    let mut conn = pool.get().expect("database connection failed");

    // 1. Fetch page of posts
    let db_posts = posts::table
        .filter(posts::show.eq(true))
        .order((posts::date.desc(), posts::id.desc()))
        .limit(11)
        .offset(offset as i64)
        .load::<Post>(&mut conn)
        .expect("Error loading posts");

    Json(attach_tags(&mut conn, db_posts))
}

#[get("/filter/tags/<tag_name>?<page>")]
fn filter_posts_by_tag(
    tag_name: &str,
    page: Option<u32>,
    pool: &State<DbPool>,
) -> Json<Vec<ApiPost>> {
    let offset = 10 * (page.unwrap_or(1).saturating_sub(1));
    let mut conn = pool.get().expect("database connection failed");

    // 1. Fetch posts filtered by tag
    let db_posts = posts::table
        .inner_join(crate::schema::post_tags::table.inner_join(tags::table))
        .filter(tags::tag_name.eq(tag_name))
        .filter(posts::show.eq(true))
        .order((posts::date.desc(), posts::id.desc()))
        .limit(11)
        .offset(offset as i64)
        .select(posts::all_columns)
        .load::<Post>(&mut conn)
        .expect("Error loading posts by tag");

    let mut api_posts = attach_tags(&mut conn, db_posts);

    // Clear content for this view
    for p in &mut api_posts {
        p.content.clear();
    }

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
            get_rss_feed,
        ],
    )
}
