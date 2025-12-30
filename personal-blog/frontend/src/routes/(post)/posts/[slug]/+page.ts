/** @type {import('./$types').PageLoad} */
export async function load({ params, fetch }) {
  let res = await fetch(`/api/getters/post/${params.slug}`);
  const { post } = await res.json();

  if (post) {
    return {
      post,
    };
  }
}
