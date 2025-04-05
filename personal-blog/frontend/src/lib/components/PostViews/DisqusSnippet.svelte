<script lang="ts">
  import { browser } from '$app/environment';
  /**
   *  RECOMMENDED CONFIGURATION VARIABLES: EDIT AND UNCOMMENT THE SECTION BELOW TO INSERT DYNAMIC VALUES FROM YOUR PLATFORM OR CMS.
   *  LEARN WHY DEFINING THESE VARIABLES IS IMPORTANT: https://disqus.com/admin/universalcode/#configuration-variables
   */

  if (browser) {
    const postUrl = window.location.href;

    const disqus_config = function () {
      this.page.url = postUrl; // Replace PAGE_URL with your page's canonical URL variable
      this.page.identifier = postUrl; // Replace PAGE_IDENTIFIER with your page's unique identifier variable
    };
    (function () {
      // DON'T EDIT BELOW THIS LINE
      const d = document,
        s = d.createElement('script');
      s.src = 'https://blog-msmetko.disqus.com/embed.js';
      s.setAttribute('data-timestamp', +new Date());
      (d.head || d.body).appendChild(s);
    })();
  }
</script>

<div id="disqus_thread"></div>
<noscript>
  Please enable JavaScript to view the
  <a href="https://disqus.com/?ref_noscript"> comments powered by Disqus.</a>
</noscript>
