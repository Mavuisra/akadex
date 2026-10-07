const CART_KEY = 'akadex_learn_cart_v1';

const listeners = new Set();

function read() {
  try {
    const raw = localStorage.getItem(CART_KEY);
    const list = raw ? JSON.parse(raw) : [];
    return Array.isArray(list) ? list : [];
  } catch {
    return [];
  }
}

function write(items) {
  localStorage.setItem(CART_KEY, JSON.stringify(items));
  listeners.forEach((fn) => fn(items));
}

export function getCart() {
  return read();
}

export function cartCount() {
  return read().length;
}

export function cartTotal() {
  return read().reduce((sum, i) => sum + (Number(i.priceUsd) || 0), 0);
}

export function hasCourse(courseId) {
  return read().some((i) => String(i.courseId) === String(courseId));
}

export function addCourse(course, priceUsd) {
  const id = String(course.id);
  if (hasCourse(id)) return false;
  const items = [
    ...read(),
    {
      courseId: id,
      title: course.title || '',
      teacher: teacherName(course),
      coverUrl: course.cover_url || '',
      code: course.code || '',
      priceUsd: Number(priceUsd) || 0,
    },
  ];
  write(items);
  return true;
}

export function removeCourse(courseId) {
  write(read().filter((i) => String(i.courseId) !== String(courseId)));
}

export function clearCart() {
  write([]);
}

export function onCartChange(fn) {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

export function teacherName(course) {
  return (
    course.teacher_full_name ||
    (Array.isArray(course.teacher_names) && course.teacher_names[0]) ||
    course.teacher_name ||
    'Instructeur'
  );
}

export function formatPrice(amount) {
  const n = Number(amount) || 0;
  return n === Math.round(n) ? `${n}$` : `${n.toFixed(2)}$`;
}
