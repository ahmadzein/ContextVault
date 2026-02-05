/* ContextVault Documentation JS */

// Search index - will be populated from search-index.json
let searchIndex = [];

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  initSearch();
  initMobileMenu();
  initVersionDropdown();
  initFAQ();
  highlightActiveNav();
  initCopyButtons();
});

// --- Search Functionality ---
async function initSearch() {
  const searchInput = document.querySelector('.search-input');
  const searchResults = document.querySelector('.search-results');

  if (!searchInput || !searchResults) return;

  // Load search index
  try {
    const response = await fetch('/docs/assets/search-index.json');
    searchIndex = await response.json();
  } catch (e) {
    console.warn('Search index not loaded:', e);
    searchIndex = [];
  }

  // Search input handler
  searchInput.addEventListener('input', (e) => {
    const query = e.target.value.toLowerCase().trim();

    if (query.length < 2) {
      searchResults.classList.remove('active');
      return;
    }

    const results = searchIndex.filter(item =>
      item.title.toLowerCase().includes(query) ||
      item.content.toLowerCase().includes(query) ||
      (item.keywords && item.keywords.some(k => k.toLowerCase().includes(query)))
    ).slice(0, 8);

    if (results.length === 0) {
      searchResults.innerHTML = '<div class="search-result"><div class="search-result-title">No results found</div></div>';
    } else {
      searchResults.innerHTML = results.map(item => `
        <a href="${item.url}" class="search-result">
          <div class="search-result-title">${highlightMatch(item.title, query)}</div>
          <div class="search-result-snippet">${getSnippet(item.content, query)}</div>
          <div class="search-result-page">${item.page}</div>
        </a>
      `).join('');
    }

    searchResults.classList.add('active');
  });

  // Close on outside click
  document.addEventListener('click', (e) => {
    if (!e.target.closest('.search-wrapper')) {
      searchResults.classList.remove('active');
    }
  });

  // Keyboard navigation
  searchInput.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      searchResults.classList.remove('active');
      searchInput.blur();
    }
  });
}

function highlightMatch(text, query) {
  const regex = new RegExp(`(${escapeRegex(query)})`, 'gi');
  return text.replace(regex, '<mark>$1</mark>');
}

function getSnippet(content, query) {
  const index = content.toLowerCase().indexOf(query.toLowerCase());
  if (index === -1) return content.slice(0, 100) + '...';

  const start = Math.max(0, index - 40);
  const end = Math.min(content.length, index + query.length + 60);
  let snippet = content.slice(start, end);

  if (start > 0) snippet = '...' + snippet;
  if (end < content.length) snippet += '...';

  return highlightMatch(snippet, query);
}

function escapeRegex(string) {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// --- Mobile Menu ---
function initMobileMenu() {
  const menuBtn = document.querySelector('.mobile-menu-btn');
  const sidebar = document.querySelector('.docs-sidebar');

  if (!menuBtn || !sidebar) return;

  menuBtn.addEventListener('click', () => {
    sidebar.classList.toggle('open');
  });

  // Close on link click (mobile)
  sidebar.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
      if (window.innerWidth <= 900) {
        sidebar.classList.remove('open');
      }
    });
  });
}

// --- Version Dropdown ---
function initVersionDropdown() {
  const versionBtn = document.querySelector('.version-btn');
  const versionMenu = document.querySelector('.version-menu');

  if (!versionBtn || !versionMenu) return;

  versionBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    versionMenu.classList.toggle('active');
  });

  document.addEventListener('click', () => {
    versionMenu.classList.remove('active');
  });
}

// --- FAQ Accordion ---
function initFAQ() {
  document.querySelectorAll('.faq-question').forEach(question => {
    question.addEventListener('click', () => {
      const item = question.parentElement;
      const isOpen = item.classList.contains('open');

      // Close all others
      document.querySelectorAll('.faq-item.open').forEach(i => {
        if (i !== item) i.classList.remove('open');
      });

      // Toggle current
      item.classList.toggle('open', !isOpen);
    });
  });
}

// --- Active Navigation ---
function highlightActiveNav() {
  const currentPath = window.location.pathname;
  const currentPage = currentPath.split('/').pop() || 'index.html';

  document.querySelectorAll('.sidebar-links a').forEach(link => {
    const href = link.getAttribute('href');
    if (href === currentPage || (currentPage === '' && href === 'index.html')) {
      link.classList.add('active');
    }
  });
}

// --- Copy Code Buttons ---
function initCopyButtons() {
  document.querySelectorAll('pre').forEach(pre => {
    const wrapper = document.createElement('div');
    wrapper.className = 'code-wrapper';
    wrapper.style.position = 'relative';

    const btn = document.createElement('button');
    btn.className = 'copy-btn';
    btn.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>';
    btn.style.cssText = 'position:absolute;top:8px;right:8px;background:var(--stone-700);border:none;border-radius:4px;padding:6px;cursor:pointer;color:var(--stone-400);opacity:0;transition:opacity 0.2s;';

    btn.addEventListener('click', async () => {
      const code = pre.querySelector('code')?.textContent || pre.textContent;
      await navigator.clipboard.writeText(code);
      btn.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--gold-400)" stroke-width="2"><polyline points="20 6 9 17 4 12"></polyline></svg>';
      setTimeout(() => {
        btn.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>';
      }, 2000);
    });

    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);
    wrapper.appendChild(btn);

    wrapper.addEventListener('mouseenter', () => btn.style.opacity = '1');
    wrapper.addEventListener('mouseleave', () => btn.style.opacity = '0');
  });
}

// --- Smooth scroll for anchor links ---
document.addEventListener('click', (e) => {
  const link = e.target.closest('a[href^="#"]');
  if (link) {
    e.preventDefault();
    const target = document.querySelector(link.getAttribute('href'));
    if (target) {
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      history.pushState(null, null, link.getAttribute('href'));
    }
  }
});
