#[macro_use]
extern crate rocket;
use rocket::serde::json::Json;
use rocket::serde::Serialize;
use sqlite;

#[derive(Serialize, Clone)]
#[serde(crate = "rocket::serde")]
struct Tag {
    id: u32,
    tag_name: String,
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
struct TagList {
    tags: Vec<Tag>,
}
#[derive(Serialize, Clone)]
#[serde(crate = "rocket::serde")]
struct Post {
    id: u32,
    date: String,
    title: String,
    subtitle: String,
    content: String,
    tags: Vec<Tag>,
}

#[derive(Serialize, Clone)]
#[serde(crate = "rocket::serde")]
struct PostResponse {
    post: Post,
}
#[derive(Serialize, Clone)]
#[serde(crate = "rocket::serde")]
#[allow(non_snake_case)]
struct TagResponse {
    tagName: String,
}

#[get("/posts/<post_id>/tags")]
fn post_tags(post_id: u32) -> Json<TagList> {
    let connection = sqlite::open("/db.sqlite3").unwrap();
    let query = "select tags.tag_name as tag_name, tags.id as id from post_tags join tags on post_tags.tag_id = tags.id where post_tags.post_id = ?;";
    let mut tags: Vec<Tag> = vec![];
    // TODO optimize
    for row in connection
        .prepare(query)
        .unwrap()
        .into_iter()
        .bind((1, post_id as i64))
        .unwrap()
        .map(|row| row.unwrap())
    {
        tags.push(Tag {
            id: row.read::<i64, _>("id") as u32,
            tag_name: row.read::<&str, _>("tag_name").to_string(),
        });
    }
    Json(TagList { tags: tags })
}

#[get("/post/<post_id>")]
fn get_post(post_id: u32) -> Json<PostResponse> {
    let connection = sqlite::open("/db.sqlite3").unwrap();
    let query = "SELECT * FROM posts where id = ?";
    let mut posts: Vec<Post> = vec![];
    for row in connection
        .prepare(query)
        .unwrap()
        .into_iter()
        .bind((1, post_id as i64))
        .unwrap()
        .map(|row| row.unwrap())
    {
        posts.push(Post {
            id: row.read::<i64, _>("id") as u32,
            date: row.read::<&str, _>("date").to_string(),
            title: row.read::<&str, _>("title").to_string(),
            subtitle: row.read::<&str, _>("subtitle").to_string(),
            content: row.read::<&str, _>("content").to_string(),
            tags: vec![],
        });
    }
    Json(PostResponse {
        post: posts[0].clone(),
    })
}

#[get("/tags/<tag_id>")]
fn get_tag(tag_id: u32) -> Json<TagResponse> {
    let connection = sqlite::open("/db.sqlite3").unwrap();
    let query = "SELECT tag_name FROM tags where id = ?";
    for row in connection
        .prepare(query)
        .unwrap()
        .into_iter()
        .bind((1, tag_id as i64))
        .unwrap()
        .map(|row| row.unwrap())
    {
        return Json(TagResponse {
            tagName: row.read::<&str, _>("tag_name").to_string(),
        });
    }
    return Json(TagResponse {
        tagName: "".to_string(),
    });
}

#[get("/posts/<page>")]
fn get_post_list(page: u32) -> Json<Vec<Post>> {
    let offset = 10 * (page - 1);
    let connection = sqlite::open("/db.sqlite3").unwrap();
    let query = "SELECT * FROM posts WHERE show = 1 ORDER BY date DESC LIMIT 11 OFFSET ?";
    let mut posts: Vec<Post> = vec![];
    for row in connection
        .prepare(query)
        .unwrap()
        .into_iter()
        .bind((1, offset as i64))
        .unwrap()
        .map(|row| row.unwrap())
    {
        posts.push(Post {
            id: row.read::<i64, _>("id") as u32,
            date: row.read::<&str, _>("date").to_string(),
            title: row.read::<&str, _>("title").to_string(),
            subtitle: row.read::<&str, _>("subtitle").to_string(),
            content: row.read::<&str, _>("content").to_string(),
            tags: vec![],
        });
    }
    Json(posts)
}



#[get("/filter/tags/<tag_id>?<page>")]
fn filter_posts_by_tag(tag_id: u32, page: Option<u32>) -> Json<Vec<Post>> {
    println!("tag_id: {}, page: {:?}", tag_id, page);
    let connection = sqlite::open("/db.sqlite3").unwrap();
    let query = "select posts.id as id, posts.title as title, posts.date as date, posts.subtitle as subtitle from post_tags join posts on posts.id = post_tags.post_id join tags on post_tags.tag_id = tags.id where post_tags.tag_id = ? and posts.show = 1 order by date desc limit 11 offset ?";    
    let mut posts: Vec<Post> = vec![];
    for row in connection
        .prepare(query)
        .unwrap()
        .into_iter()
        .bind_iter::<_, (_, sqlite::Value)>([
            (1, (tag_id as i64).into()),
            (2, (match page {
                Some(page) => 10*(page-1),
                None => 0,
            } as i64).into())
        ])
        .unwrap()
        .map(|row| row.unwrap())
    {
        println!("{:?}", row);
        posts.push(Post {
            id: row.read::<i64, _>("id") as u32,
            date: row.read::<&str, _>("date").to_string(),
            title: row.read::<&str, _>("title").to_string(),
            subtitle: row.read::<&str, _>("subtitle").to_string(),
            content: "".to_string(),
            tags: vec![],
        });
    }
    Json(posts)
}

#[launch]
fn rocket() -> _ {
    rocket::build().mount("/", routes![post_tags, get_post, get_tag, get_post_list, filter_posts_by_tag])
}