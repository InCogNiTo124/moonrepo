import { env } from '$env/dynamic/private';

interface Arguments {
  params: {
    slug: string;
    image: string;
  };
}

/** @type {import('./$types').RequestHandler} */
export async function GET({ params }: Arguments): Promise<Response> {
  const { slug, image } = params;
  const blog_db = env.BLOG_DB;
  const response = await fetch(`http://${blog_db}/post/${encodeURIComponent(slug)}/${encodeURIComponent(image)}`);
  return new Response(response.body, {
    headers: {
      'content-type': response.headers.get('content-type') || 'application/octet-stream'
    }
  });
}
