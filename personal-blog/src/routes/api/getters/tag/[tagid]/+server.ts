import { json } from '@sveltejs/kit';
import { env } from '$env/dynamic/private';

interface Body {
  tagName: string;
}

/** @type {import('./$types').RequestHandler} */
export async function GET({ params }): Promise<Response> {
  const { tagid } = params;
  const blog_db = env.BLOG_DB;
  const responseData: Body = await fetch(`http://${blog_db}/tags/${tagid}`).then(res => res.json());

  return json(responseData);
}
