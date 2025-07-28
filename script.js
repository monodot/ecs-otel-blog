import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
  vus: 3,
  duration: '10m',
};

export default function() {
  let res = http.get('http://localhost:8080/packages');
  check(res, { "status is 200": (res) => res.status === 200 });
  sleep(1);
}
