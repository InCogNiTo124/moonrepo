import { json } from '@sveltejs/kit';
import { env } from '$env/dynamic/private';

interface Arguments {
  params: {
    slug: string;
  };
}

interface Body {
  post: Post;
}

/** @type {import('./$types').RequestHandler} */
export async function GET({ params }: Arguments): Promise<Response> {
  const { slug } = params;
  const blog_db = env.BLOG_DB;
  const responseData: Body = await fetch(`http://${blog_db}/post/${slug}`).then(res => res.json());
  return json(responseData);
}
