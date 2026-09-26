const BACKEND_URL = 'https://kfvseygjvzljfspgjmiv.supabase.co/functions/v1/submit-lead';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmdnNleWdqdnpsamZzcGdqbWl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk5NzkzMzYsImV4cCI6MjEwNTU1NTMzNn0.JJpCL-o3_ytkJ2F6FMPQwNsZt-IpzhlFEiMncPS3W8I';

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
function showToast(message, type = 'success') {
  if (!toast) return;
  toast.textContent = message;
  toast.classList.remove('is-success', 'is-error');
  toast.classList.add(type === 'error' ? 'is-error' : 'is-success', 'is-visible');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove('is-visible'), 3600);
}

function formPayload(form) {
  const data = new FormData(form);
  return {
    name: String(data.get('name') || '').trim(),
    phone: String(data.get('phone') || '').trim(),
    email: String(data.get('email') || '').trim(),
    city: String(data.get('city') || '').trim(),
    message: String(data.get('message') || data.get('question') || '').trim(),
    website: String(data.get('website') || '').trim(),
    source: form.dataset.source || 'website',
    page_url: location.href,
  };
}

async function submitLead(form) {
  const button = form.querySelector('button[type="submit"]');
  const originalText = button?.textContent || 'Надіслати';

  if (button) {
    button.disabled = true;
    button.textContent = 'Надсилаємо…';
  }

  try {
    const response = await fetch(BACKEND_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
        'apikey': SUPABASE_ANON_KEY,
      },
      body: JSON.stringify(formPayload(form)),
    });

    const result = await response.json().catch(() => ({}));

    if (!response.ok || !result.ok) {
      throw new Error(result.message || 'Не вдалося надіслати заявку. Спробуйте ще раз.');
    }

    form.reset();
    showToast('Дякуємо! Заявку прийнято. Ми звʼяжемося з вами.', 'success');
  } catch (error) {
    console.error('Lead submit failed', error);
    showToast(error?.message || 'Помилка надсилання. Спробуйте ще раз.', 'error');
  } finally {
    if (button) {
      button.disabled = false;
      button.textContent = originalText;
    }
  }
}

document.querySelectorAll('.demo-form').forEach(form => {
  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (!form.checkValidity()) {
      form.reportValidity();
      return;
    }
    await submitLead(form);
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
