import { json } from '@sveltejs/kit';
import { env } from '$env/dynamic/private';

interface Arguments {
  params: {
    postid: string;
  };
}

interface Body {
  post: Post;
}

/** @type {import('./$types').RequestHandler} */
export async function GET({ params }: Arguments): Promise<Response> {
  const { postid } = params;
  const blog_db = env.BLOG_DB;
  const responseData: Body = await fetch(`http://${blog_db}/post/${postid}`).then(res => res.json());
  return json(responseData);
}
