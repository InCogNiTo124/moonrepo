/** @type {import('./$types').PageLoad} */
export async function load({ params, fetch }) {
  let res = await fetch(`/api/getters/post/${params.postid}`);
  const { post } = await res.json();

  res = await fetch(`/api/getters/tags/${post.id}`);
  post.tags = (await res.json()).tags;

  if (post) {
    return {
      post,
    };
  }
}
