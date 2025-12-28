import { json } from '@sveltejs/kit';
import { env } from '$env/dynamic/private';


interface Arguments {
  params: {
    tagname: string;
    page: string;
  };
}

interface Body {
  posts: Post[];
  lastPage: boolean;
}

/** @type {import('./$types').RequestHandler} */
export async function GET({ params }: Arguments): Promise<Response>{
  const { tagname, page } = params;
  const blog_db = env.BLOG_DB;

  const posts: Post[] = await fetch(`http://${blog_db}/filter/tags/${tagname}?page=${page}`).then((res) => res.json());
  for (const post of posts) {
    post.tags = await fetch(`http://${blog_db}/posts/${post.id}/tags`).then((res) => res.json()).then((tags) => {console.log(tags.tags); return tags.tags});
  }

  const responseData: Body = {
    posts: posts.length === 11 ? posts.slice(0, -1) : posts,
    lastPage: posts.length < 11,
  };
  return json(responseData);
}
