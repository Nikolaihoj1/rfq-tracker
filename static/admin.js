/* global document, fetch, alert */

const tableBody = document.querySelector('#rfqTable tbody');
const form = document.getElementById('rfqForm');
const resetBtn = document.getElementById('resetBtn');
const refreshBtn = document.getElementById('refreshBtn');
const showOpenBtn = document.getElementById('showOpenBtn');
const limitSelect = document.getElementById('limitSelect');
let showOpenOnly = false;

const fields = [
  'rfq_id', 'rfq_number', 'client_name', 'rfq_date', 'due_date', 'client_contact', 'client_email', 'our_contact', 'network_folder_link', 'status', 'comments'
];

function getField(id) { return document.getElementById(id); }
function clearForm() { for (const f of fields) { const el = getField(f); if (el) el.value = ''; } }
function fillForm(item) { for (const f of fields) { if (f in item && getField(f)) getField(f).value = item[f] ?? ''; } }

async function loadList() {
  const limit = limitSelect.value;
  const res = await fetch(`/api/rfqs?sort_by=rfq_id&order=desc&limit=${limit}`);
  const data = await res.json();
  let items = Array.isArray(data.items) ? data.items : [];
  
  // Filter to show only open RFQs if button is active
  if (showOpenOnly) {
    items = items.filter(item => item.status !== 'Send' && item.status !== 'Followed up');
  }
  
  renderTable(items);
}

function renderTable(items) {
  tableBody.innerHTML = '';
  for (const item of items) {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td>${item.rfq_id}</td>
      <td>${escapeHtml(item.rfq_number || '')}</td>
      <td>${escapeHtml(item.client_name)}</td>
      <td>${escapeHtml(item.rfq_date)}</td>
      <td>${escapeHtml(item.due_date)}</td>
      <td>${item.client_contact ? escapeHtml(item.client_contact) : ''}</td>
      <td>${item.client_email ? `<a href="mailto:${escapeAttr(item.client_email)}" class="folder-link">e-mail</a>` : ''}</td>
      <td>${escapeHtml(item.our_contact)}</td>
      <td>${escapeHtml(item.status)}</td>
      <td><a href="${escapeAttr(item.network_folder_link)}" target="_blank" rel="noopener">Åbn</a></td>
      <td style="max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" title="${escapeAttr(item.comments || '')}">${escapeHtml(item.comments || '')}</td>
      <td>
        <button data-action="edit" data-id="${item.rfq_id}">Rediger</button>
        <button data-action="delete" data-id="${item.rfq_id}">Slet</button>
      </td>
    `;
    tableBody.appendChild(tr);
  }
}

tableBody.addEventListener('click', async (e) => {
  const btn = e.target.closest('button');
  if (!btn) return;
  const id = Number(btn.getAttribute('data-id'));
  const action = btn.getAttribute('data-action');
  if (action === 'edit') {
    const row = btn.closest('tr');
    // Extract email from the mailto link if it exists
    const emailLink = row.children[6].querySelector('a');
    const clientEmail = emailLink ? emailLink.href.replace('mailto:', '') : '';
    // Extract network folder link (it's in column 9)
    const folderLink = row.children[9].querySelector('a');
    const networkFolderLink = folderLink ? folderLink.href : '';
    // Extract comments (it's in column 10)
    const comments = row.children[10].textContent || '';
    
    fillForm({
      rfq_id: id,
      rfq_number: row.children[1].textContent,
      client_name: row.children[2].textContent,
      rfq_date: row.children[3].textContent,
      due_date: row.children[4].textContent,
      client_contact: row.children[5].textContent,
      client_email: clientEmail,
      our_contact: row.children[7].textContent,
      status: row.children[8].textContent,
      network_folder_link: networkFolderLink,
      comments: comments,
    });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  } else if (action === 'delete') {
    if (!confirm('Slet denne RFQ?')) return;
    try {
      const res = await fetch(`/api/rfqs/${id}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('Delete failed');
      await loadList();
    } catch (err) {
      console.error(err);
      alert('Kunne ikke slette RFQ.');
    }
  }
});

form.addEventListener('submit', async (e) => {
  e.preventDefault();
  const payload = {};
  for (const f of fields) { const el = getField(f); if (el) payload[f] = el.value.trim(); }
  const required = ['client_name','rfq_date','due_date','our_contact','network_folder_link','status'];
  for (const key of required) { if (!payload[key]) { alert(`Mangler ${key}`); return; } }
  try {
    if (payload.rfq_id) {
      const { rfq_id, ...updates } = payload;
      const res = await fetch(`/api/rfqs/${rfq_id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates)
      });
      if (!res.ok) throw new Error('Update failed');
    } else {
      const res = await fetch('/api/rfqs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      if (!res.ok) throw new Error('Create failed');
    }
    clearForm();
    await loadList();
  } catch (err) {
    console.error(err);
    alert('Kunne ikke gemme RFQ.');
  }
});

resetBtn.addEventListener('click', () => {
  clearForm();
  setDefaultFormValues();
});

refreshBtn.addEventListener('click', () => {
  loadList();
});

showOpenBtn.addEventListener('click', () => {
  showOpenOnly = !showOpenOnly;
  if (showOpenOnly) {
    showOpenBtn.textContent = 'Vis alle RFQ\'er';
    showOpenBtn.classList.add('active');
  } else {
    showOpenBtn.textContent = 'Vis åbne RFQ\'er';
    showOpenBtn.classList.remove('active');
  }
  loadList();
});

limitSelect.addEventListener('change', () => {
  loadList();
});

function escapeHtml(s) { return String(s).replace(/[&<>\"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;','\'':'&#39;'}[c])); }
function escapeAttr(s) { return String(s).replace(/[\"']/g, c => ({'\"':'&quot;','\'':'&#39;'}[c])); }

function addWorkdays(date, days) {
  let current = new Date(date);
  let added = 0;
  while (added < days) {
    current.setDate(current.getDate() + 1);
    const dayOfWeek = current.getDay();
    if (dayOfWeek !== 0 && dayOfWeek !== 6) { // Skip weekends
      added++;
    }
  }
  return current;
}

function setDefaultFormValues() {
  const rfqNumberEl = getField('rfq_number');
  const rfqDateEl = getField('rfq_date');
  const dueDateEl = getField('due_date');
  const folderEl = getField('network_folder_link');
  
  if (rfqNumberEl && !rfqNumberEl.value) {
    rfqNumberEl.value = 'Tilbud 26.000';
  }
  
  if (rfqDateEl && !rfqDateEl.value) {
    const today = new Date();
    rfqDateEl.value = today.toISOString().split('T')[0];
  }
  
  if (dueDateEl && !dueDateEl.value) {
    const today = new Date();
    const dueDate = addWorkdays(today, 5);
    dueDateEl.value = dueDate.toISOString().split('T')[0];
  }
  
  if (folderEl && !folderEl.value) {
    folderEl.value = 'file://network/folder';
  }
}

window.addEventListener('DOMContentLoaded', () => {
  loadList();
  setDefaultFormValues();
});