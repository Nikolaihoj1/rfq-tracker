/* global document, window, fetch */

const sortByEl = document.getElementById('sortBy');
const orderEl = document.getElementById('order');
const refreshBtn = document.getElementById('refreshBtn');
const tilesEl = document.getElementById('tiles');
const tileTemplate = /** @type {HTMLTemplateElement} */ (document.getElementById('tile-template'));

const statusClass = (status) => {
  const key = String(status || '').toLowerCase().replace(/\s+/g, '-');
  switch (key) {
    case 'created': return 'status-created';
    case 'draft': return 'status-draft';
    case 'send': return 'status-send';
    case 'followed-up': return 'status-followed-up';
    case 'received': return 'status-received';
    default: return '';
  }
};

async function loadRfqs() {
  const sortBy = sortByEl.value;
  const order = orderEl.value;
  const url = `/api/rfqs?sort_by=${encodeURIComponent(sortBy)}&order=${encodeURIComponent(order)}`;
  const res = await fetch(url);
  const data = await res.json();
  renderTiles(Array.isArray(data.items) ? data.items : []);
}

function renderTiles(items) {
  tilesEl.innerHTML = '';
  for (const item of items) {
    const node = tileTemplate.content.cloneNode(true);
    const tile = node.querySelector('.tile');

    tile.querySelector('.client-name').textContent = item.client_name;
    tile.querySelector('.rfq-date').textContent = item.rfq_date;
    tile.querySelector('.due-date').textContent = item.due_date;
    tile.querySelector('.client-contact').textContent = item.client_contact;
    tile.querySelector('.our-contact').textContent = item.our_contact;
    const link = tile.querySelector('.folder-link');
    link.href = item.network_folder_link;

    const badge = tile.querySelector('.status-badge');
    badge.textContent = item.status;
    badge.classList.add(statusClass(item.status));

    const select = tile.querySelector('.status-select');
    select.value = item.status;
    select.addEventListener('change', async (e) => {
      const newStatus = e.target.value;
      try {
        const res = await fetch(`/api/rfqs/${item.rfq_id}/status`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ status: newStatus })
        });
        if (!res.ok) throw new Error('Failed to update status');
        // Update badge immediately without full refresh for responsiveness
        badge.textContent = newStatus;
        badge.className = 'status-badge ' + statusClass(newStatus);
      } catch (err) {
        console.error(err);
        // Revert select on error
        select.value = item.status;
        alert('Could not update status. See console for details.');
      }
    });

    tilesEl.appendChild(node);
  }
}

refreshBtn.addEventListener('click', loadRfqs);
sortByEl.addEventListener('change', loadRfqs);
orderEl.addEventListener('change', loadRfqs);

window.addEventListener('DOMContentLoaded', () => {
  // Default sort by rfq_date ascending per spec
  sortByEl.value = 'rfq_date';
  orderEl.value = 'asc';
  loadRfqs();
});


