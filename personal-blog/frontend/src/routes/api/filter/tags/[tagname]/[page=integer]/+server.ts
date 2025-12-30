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

  const responseData: Body = {
    posts: posts.length === 11 ? posts.slice(0, -1) : posts,
    lastPage: posts.length < 11,
  };
  return json(responseData);
}
