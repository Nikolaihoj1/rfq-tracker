/* global document, window, fetch */

const sortByEl = document.getElementById('sortBy');
const orderEl = document.getElementById('order');
const showFollowUpEl = document.getElementById('showFollowUp');
const refreshBtn = document.getElementById('refreshBtn');
const tilesEl = document.getElementById('tiles');
const tileTemplate = /** @type {HTMLTemplateElement} */ (document.getElementById('tile-template'));
const recentTableBody = document.querySelector('#recentTable tbody');

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

function updateStats(items) {
  const counts = {
    'Received': 0,
    'Created': 0,
    'Draft': 0,
    'Send': 0,
    'Followed up': 0
  };
  
  for (const item of items) {
    if (item.status in counts) {
      counts[item.status]++;
    }
  }
  
  const total = items.length || 1;
  const showFollowUp = showFollowUpEl.checked;
  
  const barReceived = document.getElementById('barReceived');
  const barCreated = document.getElementById('barCreated');
  const barDraft = document.getElementById('barDraft');
  const barSend = document.getElementById('barSend');
  const barFollowedUp = document.getElementById('barFollowedUp');
  
  const countReceived = document.getElementById('countReceived');
  const countCreated = document.getElementById('countCreated');
  const countDraft = document.getElementById('countDraft');
  const countSend = document.getElementById('countSend');
  const countFollowedUp = document.getElementById('countFollowedUp');
  
  // Always show Received, Created, Draft
  if (barReceived) barReceived.style.width = `${(counts['Received'] / total) * 100}%`;
  if (barCreated) barCreated.style.width = `${(counts['Created'] / total) * 100}%`;
  if (barDraft) barDraft.style.width = `${(counts['Draft'] / total) * 100}%`;
  
  if (countReceived) countReceived.textContent = counts['Received'];
  if (countCreated) countCreated.textContent = counts['Created'];
  if (countDraft) countDraft.textContent = counts['Draft'];
  
  // Show/hide Send and Followed up rows based on checkbox
  const sendRow = document.getElementById('barSend')?.closest('.stat-row');
  const followedUpRow = document.getElementById('barFollowedUp')?.closest('.stat-row');
  
  if (showFollowUp) {
    if (sendRow) sendRow.style.display = 'flex';
    if (followedUpRow) followedUpRow.style.display = 'flex';
    if (barSend) barSend.style.width = `${(counts['Send'] / total) * 100}%`;
    if (barFollowedUp) barFollowedUp.style.width = `${(counts['Followed up'] / total) * 100}%`;
    if (countSend) countSend.textContent = counts['Send'];
    if (countFollowedUp) countFollowedUp.textContent = counts['Followed up'];
  } else {
    if (sendRow) sendRow.style.display = 'none';
    if (followedUpRow) followedUpRow.style.display = 'none';
  }
}

async function loadRfqs() {
  const sortBy = sortByEl.value;
  const order = orderEl.value;
  const url = `/api/rfqs?sort_by=${encodeURIComponent(sortBy)}&order=${encodeURIComponent(order)}`;
  const res = await fetch(url);
  const data = await res.json();
  let items = Array.isArray(data.items) ? data.items : [];
  // Update stats bar chart before filtering
  updateStats(items);
  // Update recent completed table
  updateRecentTable(items);
  // Default filter: hide Send and Followed up unless checkbox is on
  if (!showFollowUpEl.checked) {
    items = items.filter(it => it.status !== 'Send' && it.status !== 'Followed up');
  } else {
    // If showing follow-up, optionally filter to only 'Send'
    items = items.filter(it => it.status === 'Send');
  }
  renderTiles(items);
}

function renderTiles(items) {
  tilesEl.innerHTML = '';
  for (const item of items) {
    const node = tileTemplate.content.cloneNode(true);
    const tile = node.querySelector('.tile');

    tile.querySelector('.client-name').textContent = item.client_name;
    const rfqNumLinkEl = tile.querySelector('.rfq-number-link');
    if (rfqNumLinkEl) {
      rfqNumLinkEl.textContent = item.rfq_number || '';
      rfqNumLinkEl.addEventListener('click', async (e) => {
        e.preventDefault();
        try {
          await navigator.clipboard.writeText(item.network_folder_link);
          const originalText = rfqNumLinkEl.textContent;
          rfqNumLinkEl.textContent = 'Link kopieret';
          rfqNumLinkEl.style.color = '#10b981';
          setTimeout(() => {
            rfqNumLinkEl.textContent = originalText;
            rfqNumLinkEl.style.color = '';
          }, 2000);
        } catch (err) {
          console.error('Failed to copy link:', err);
          alert('Kunne ikke kopiere link');
        }
      });
    }
    tile.querySelector('.rfq-date').textContent = item.rfq_date;
    tile.querySelector('.due-date').textContent = item.due_date;
    
    // Hide/show client contact field
    const clientContactDiv = tile.querySelector('.client-contact').closest('div');
    if (item.client_contact && item.client_contact.trim()) {
      tile.querySelector('.client-contact').textContent = item.client_contact;
      if (clientContactDiv) clientContactDiv.style.display = '';
    } else {
      if (clientContactDiv) clientContactDiv.style.display = 'none';
    }
    
    // Hide/show client email field
    const clientEmailDiv = tile.querySelector('.client-email-link').closest('div');
    const clientEmailEl = tile.querySelector('.client-email-link');
    if (clientEmailEl && item.client_email && item.client_email.trim()) {
      clientEmailEl.href = `mailto:${item.client_email}`;
      clientEmailEl.style.display = 'inline';
      if (clientEmailDiv) clientEmailDiv.style.display = '';
    } else {
      if (clientEmailEl) clientEmailEl.style.display = 'none';
      if (clientEmailDiv) clientEmailDiv.style.display = 'none';
    }
    
    tile.querySelector('.our-contact').textContent = item.our_contact;

    // Show/hide comments field
    const commentsDiv = tile.querySelector('.tile-comments');
    const commentsTextEl = tile.querySelector('.comments-text');
    if (item.comments && item.comments.trim()) {
      if (commentsTextEl) commentsTextEl.textContent = item.comments;
      if (commentsDiv) commentsDiv.style.display = '';
    } else {
      if (commentsDiv) commentsDiv.style.display = 'none';
    }

    // Check due date and apply background color
    if (item.due_date) {
      // Parse date string (YYYY-MM-DD) and create date objects without timezone issues
      const dueDateParts = item.due_date.split('-');
      const dueDate = new Date(parseInt(dueDateParts[0]), parseInt(dueDateParts[1]) - 1, parseInt(dueDateParts[2]));
      
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      dueDate.setHours(0, 0, 0, 0);
      
      const todayTime = today.getTime();
      const dueTime = dueDate.getTime();
      
      if (dueTime < todayTime) {
        // Overdue - red background
        tile.classList.add('overdue');
      } else if (dueTime === todayTime) {
        // Due today - yellow background
        tile.classList.add('due-today');
      }
    }

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
        alert('Kunne ikke opdatere status. Se konsollen for detaljer.');
      }
    });

    tilesEl.appendChild(node);
  }
}

function updateRecentTable(items) {
  // Filter for Send and Followed up, sort by completed_date desc (most recent first), take last 10
  const completed = items
    .filter(it => it.status === 'Send' || it.status === 'Followed up')
    .filter(it => it.completed_date) // Only show items with completed_date
    .sort((a, b) => new Date(b.completed_date) - new Date(a.completed_date))
    .slice(0, 10);
  
  if (!recentTableBody) return;
  recentTableBody.innerHTML = '';
  
  for (const item of completed) {
    const completedDate = item.completed_date ? formatDateTime(item.completed_date) : '';
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${escapeHtml(item.client_name)}</td>
      <td>${escapeHtml(item.rfq_number || '')}</td>
      <td>${escapeHtml(item.rfq_date)}</td>
      <td>${completedDate}</td>
      <td>${escapeHtml(item.status)}</td>
    `;
    recentTableBody.appendChild(tr);
  }
}

function formatDateTime(isoString) {
  if (!isoString) return '';
  const date = new Date(isoString);
  const dateStr = date.toLocaleDateString();
  const timeStr = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  return `${dateStr} ${timeStr}`;
}

function escapeHtml(s) {
  return String(s || '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

refreshBtn.addEventListener('click', loadRfqs);
sortByEl.addEventListener('change', loadRfqs);
orderEl.addEventListener('change', loadRfqs);
showFollowUpEl.addEventListener('change', loadRfqs);

window.addEventListener('DOMContentLoaded', () => {
  // Default sort: due_date ASC
  sortByEl.value = 'due_date';
  orderEl.value = 'asc';
  loadRfqs();
  // Auto-refresh tiles every 2 minutes
  setInterval(loadRfqs, 120000);
});


