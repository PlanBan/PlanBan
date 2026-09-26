const menuButton = document.querySelector('.menu-toggle');
const nav = document.querySelector('.main-nav');

menuButton?.addEventListener('click', () => {
  const open = nav.classList.toggle('is-open');
  menuButton.setAttribute('aria-expanded', String(open));
});

document.querySelectorAll('.main-nav a').forEach(link => {
  link.addEventListener('click', () => {
    nav.classList.remove('is-open');
    menuButton?.setAttribute('aria-expanded', 'false');
  });
});

const toast = document.querySelector('.toast');
let toastTimer;
function showToast(message = 'Демо-режим: дані не надсилаються') {
  if (!toast) return;
  toast.textContent = message;
  toast.classList.add('is-visible');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove('is-visible'), 2800);
}

document.querySelectorAll('.demo-form').forEach(form => {
  form.addEventListener('submit', event => {
    event.preventDefault();
    if (!form.checkValidity()) {
      form.reportValidity();
      return;
    }
    showToast();
    form.reset();
  });
});

const reviews = [...document.querySelectorAll('.review-card')];
let reviewIndex = 0;
function renderReview(index) {
  reviews.forEach((review, i) => review.classList.toggle('is-active', i === index));
}

document.querySelector('[data-review-next]')?.addEventListener('click', () => {
  reviewIndex = (reviewIndex + 1) % reviews.length;
  renderReview(reviewIndex);
});
document.querySelector('[data-review-prev]')?.addEventListener('click', () => {
  reviewIndex = (reviewIndex - 1 + reviews.length) % reviews.length;
  renderReview(reviewIndex);
});

document.querySelectorAll('.faq-item > button').forEach(button => {
  button.addEventListener('click', () => {
    const item = button.closest('.faq-item');
    const isOpen = item.classList.toggle('is-open');
    button.setAttribute('aria-expanded', String(isOpen));
    button.querySelector('b').textContent = isOpen ? '−' : '+';
  });
});

const revealItems = document.querySelectorAll('.reveal');
if ('IntersectionObserver' in window) {
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12 });
  revealItems.forEach(item => observer.observe(item));
} else {
  revealItems.forEach(item => item.classList.add('is-visible'));
}

document.querySelectorAll('[data-year]').forEach(node => {
  node.textContent = new Date().getFullYear();
});