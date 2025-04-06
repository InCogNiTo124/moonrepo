/** @type {import('./$types').PageLoad} */
export async function load({ params, fetch, url: { searchParams } }) {
  const { tagid } = params;
  const page = parseInt(searchParams.get('page')) || 1;

  let res = await fetch(`/api/filter/tags/${tagid}/${page}`);
  const { posts, lastPage } = await res.json();

  let tagName = tagid;
  if (Number(tagid)) {
    res = await fetch(`/api/getters/tag/${tagid}`);
    ({ tagName } = await res.json());
  }

  return {
    posts,
    tagName,
    noPosts: !posts.length,
    page,
    lastPage,
  };
}
