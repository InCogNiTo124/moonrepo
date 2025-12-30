/** @type {import('./$types').PageLoad} */
export async function load({ fetch, url: { searchParams } }) {
  let res = await fetch(`/api/getters/posts/${searchParams.get('page') || 1}`);
  const { posts, lastPage } = await res.json();

  return {
    posts,
    noPosts: !posts.length,
    page: Number(searchParams.get('page')) || 1,
    lastPage,
  };
}
