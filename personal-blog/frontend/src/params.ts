import { defineParams } from '@sveltejs/kit/params';

function matchInteger(param: string) {
  return (/^\d+$/).test(param);
}

export const params = defineParams({
	integer: (param) => (matchInteger(param) ? param : undefined)
});
