import { BLOG_DB } from '$app/env/private';

interface Arguments { params: { slug: string } }
interface Body { post: Post }

/** @type {import('./$types').RequestHandler} */
export async function GET({ params }: Arguments): Promise<Response> {
  const { slug } = params;
  const blog_db = BLOG_DB;
  const responseData: Body = await fetch(`http://${blog_db}/post/${slug}`).then((res) => res.json());
  return Response.json(responseData);
}
