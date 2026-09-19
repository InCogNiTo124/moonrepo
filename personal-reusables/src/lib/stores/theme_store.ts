import { writable } from 'svelte/store';
import Cookies from 'js-cookie';
import { COOKIE_KEY_THEME, DARK, LIGHT } from '../utils.js';

const createTheme = () => {
  const { subscribe, set, update } = writable(LIGHT);

  return {
    subscribe,
    toggle: () => update((current) => (current === LIGHT ? DARK : LIGHT)),
    /**
     * Browser-only: adopt the theme saved in the cookie, then keep the cookie
     * and the <body> class in sync with every change. Returns the teardown.
     */
    init: () => {
      set(Cookies.get(COOKIE_KEY_THEME) || LIGHT);
      return subscribe((current) => {
        Cookies.set(COOKIE_KEY_THEME, current, { domain: 'msmetko.xyz' });
        document.body.setAttribute('class', current);
      });
    },
  };
};

export const theme = createTheme();
