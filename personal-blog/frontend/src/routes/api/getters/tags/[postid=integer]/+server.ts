import { json } from '@sveltejs/kit';
import { env } from '$env/dynamic/private';

interface Body {
  tags: string[];
}

/** @type {import('./$types').RequestHandler} */
export async function GET({ params }): Promise<Response> {
  const { postid } = params;
  const blog_db = env.BLOG_DB;

  const responseData: Body = await fetch(`http://${blog_db}/posts/${postid}/tags`).then(res => res.json());
  // console.log(responseData);

  return json(responseData);
}
