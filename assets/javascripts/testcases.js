document.addEventListener('DOMContentLoaded', function() {
  initTestCases();
});

function initTestCases() {
  // Add toggle functionality to test case items
  const testcaseHeaders = document.querySelectorAll('.testcase-header');

  testcaseHeaders.forEach(function(header) {
    // Make header clickable
    header.style.cursor = 'pointer';

    // Add collapse/expand icon
    const toggleIcon = document.createElement('span');
    toggleIcon.className = 'toggle-icon';
    toggleIcon.innerHTML = '&#9660;'; // Down arrow
    header.insertBefore(toggleIcon, header.firstChild);

    // Add click event
    header.addEventListener('click', function(e) {
      // Don't toggle if clicking on action buttons
      if (e.target.closest('.testcase-actions')) {
        return;
      }

      const testcaseItem = this.closest('.testcase-item');
      const body = testcaseItem.querySelector('.testcase-body');
      const icon = this.querySelector('.toggle-icon');

      if (body.style.display === 'none') {
        body.style.display = 'block';
        icon.innerHTML = '&#9660;'; // Down arrow
        testcaseItem.classList.remove('collapsed');
      } else {
        body.style.display = 'none';
        icon.innerHTML = '&#9658;'; // Right arrow
        testcaseItem.classList.add('collapsed');
      }
    });
  });

  // Collapse/Expand all buttons
  const collapseAllBtn = document.getElementById('collapse-all-btn');
  const expandAllBtn = document.getElementById('expand-all-btn');

  if (collapseAllBtn) {
    collapseAllBtn.addEventListener('click', function(e) {
      e.preventDefault();
      collapseAll();
    });
  }

  if (expandAllBtn) {
    expandAllBtn.addEventListener('click', function(e) {
      e.preventDefault();
      expandAll();
    });
  }

  // Status filter
  const statusFilter = document.getElementById('testcase-status-filter');
  if (statusFilter) {
    statusFilter.addEventListener('change', function() {
      filterByStatus(this.value);
    });
  }

  // Search functionality
  const searchInput = document.getElementById('testcase-search');
  if (searchInput) {
    searchInput.addEventListener('input', function() {
      searchTestCases(this.value);
    });
  }
}

function collapseAll() {
  const testcaseItems = document.querySelectorAll('.testcase-item');
  testcaseItems.forEach(function(item) {
    const body = item.querySelector('.testcase-body');
    const icon = item.querySelector('.toggle-icon');
    if (body) {
      body.style.display = 'none';
      item.classList.add('collapsed');
    }
    if (icon) {
      icon.innerHTML = '&#9658;'; // Right arrow
    }
  });
}

function expandAll() {
  const testcaseItems = document.querySelectorAll('.testcase-item');
  testcaseItems.forEach(function(item) {
    const body = item.querySelector('.testcase-body');
    const icon = item.querySelector('.toggle-icon');
    if (body) {
      body.style.display = 'block';
      item.classList.remove('collapsed');
    }
    if (icon) {
      icon.innerHTML = '&#9660;'; // Down arrow
    }
  });
}

function filterByStatus(status) {
  const testcaseItems = document.querySelectorAll('.testcase-item');

  testcaseItems.forEach(function(item) {
    if (status === '' || status === 'all') {
      item.style.display = 'block';
    } else {
      const statusBadge = item.querySelector('.badge');
      if (statusBadge && statusBadge.classList.contains('status-' + status)) {
        item.style.display = 'block';
      } else {
        item.style.display = 'none';
      }
    }
  });
}

function searchTestCases(query) {
  const testcaseItems = document.querySelectorAll('.testcase-item');
  const searchLower = query.toLowerCase();

  testcaseItems.forEach(function(item) {
    const testcaseId = item.querySelector('.testcase-id').textContent.toLowerCase();
    const testcaseTitle = item.querySelector('.testcase-title').textContent.toLowerCase();

    if (testcaseId.includes(searchLower) || testcaseTitle.includes(searchLower)) {
      item.style.display = 'block';
    } else {
      item.style.display = 'none';
    }
  });
}
