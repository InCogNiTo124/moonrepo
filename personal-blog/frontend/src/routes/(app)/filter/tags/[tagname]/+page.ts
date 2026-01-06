/** @type {import('./$types').PageLoad} */
export async function load({ params, fetch, url: { searchParams } }) {
  const { tagname } = params;
  const page = parseInt(searchParams.get('page') ?? '1') || 1;

  let res = await fetch(`/api/filter/tags/${tagname}/${page}`);
  const { posts, lastPage } = await res.json();

  return {
    posts,
    tagName: tagname,
    noPosts: !posts.length,
    page,
    lastPage,
  };
}
