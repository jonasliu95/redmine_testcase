document.addEventListener('DOMContentLoaded', function() {
  initTestCases();
});

function initTestCases() {
  initTestcaseSortable();
  initTestcaseStepRows();
  // Add toggle functionality to test case items
  const testcaseHeaders = document.querySelectorAll('.testcase-header');

  testcaseHeaders.forEach(function(header) {
    if (header.dataset.testcaseBound === 'true') {
      return;
    }

    // Make header clickable
    header.style.cursor = 'pointer';

    // Add collapse/expand icon when not already present
    let toggleIcon = header.querySelector('.toggle-icon');
    if (!toggleIcon) {
      toggleIcon = document.createElement('span');
      toggleIcon.className = 'toggle-icon';
      toggleIcon.innerHTML = '&#9660;'; // Down arrow
      header.insertBefore(toggleIcon, header.firstChild);
    }

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

    header.dataset.testcaseBound = 'true';
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

function initTestcaseSortable() {
  if (typeof jQuery === 'undefined' || !jQuery.fn.sortable) {
    return;
  }

  jQuery('.test-cases-list[data-reorder-url]').each(function() {
    var list = jQuery(this);
    if (list.data('sortableBound')) {
      return;
    }
    list.data('sortableBound', true);
    list.sortable({
      items: '.testcase-item',
      handle: '.testcase-header',
      axis: 'y',
      distance: 5,
      update: function() {
        var ids = list.children('.testcase-item').map(function() {
          return jQuery(this).data('testcase-id');
        }).get();
        jQuery.ajax({
          url: list.data('reorder-url'),
          type: 'PATCH',
          dataType: 'json',
          data: {ordered_ids: ids},
          error: function() {
            window.location.reload();
          }
        });
      }
    });
  });
}


function initTestcaseStepRows() {
  var body = document.getElementById('testcase-steps-body');
  var template = document.getElementById('testcase-step-template');
  var addButton = document.getElementById('add-testcase-step');
  if (!body || !template) {
    return;
  }

  if (!body.dataset.rowsBound) {
    body.dataset.rowsBound = 'true';
    body.addEventListener('click', function(e) {
      var link = e.target.closest('.remove-testcase-step');
      if (!link) {
        return;
      }
      e.preventDefault();
      var row = link.closest('.testcase-step-row');
      if (!row) {
        return;
      }
      if (row.dataset.persisted === 'true') {
        var destroy = row.querySelector('.testcase-step-destroy');
        if (destroy) {
          destroy.value = '1';
        }
        row.style.display = 'none';
      } else {
        row.parentNode.removeChild(row);
      }
      renumberTestcaseSteps();
    });
  }

  if (addButton && !addButton.dataset.bound) {
    addButton.dataset.bound = 'true';
    addButton.addEventListener('click', function(e) {
      e.preventDefault();
      var index = 'new_' + Date.now();
      var html = template.innerHTML.replace(/NEW_RECORD/g, index);
      var wrapper = document.createElement('tbody');
      wrapper.innerHTML = html;
      var row = wrapper.firstElementChild;
      if (!row) {
        return;
      }
      body.appendChild(row);
      initTestcaseStepToolbars(row);
      renumberTestcaseSteps();
    });
  }

  renumberTestcaseSteps();
}

function initTestcaseStepToolbars(row) {
  if (typeof jsToolBar === 'undefined') {
    return;
  }
  var table = document.getElementById('testcase-steps-table');
  var previewUrl = table ? table.dataset.previewUrl : null;
  row.querySelectorAll('textarea.wiki-edit').forEach(function(textarea) {
    var toolbar = new jsToolBar(textarea);
    if (previewUrl) {
      toolbar.setPreviewUrl(previewUrl);
    }
    toolbar.draw();
  });
}

function renumberTestcaseSteps() {
  var rows = document.querySelectorAll('#testcase-steps-body .testcase-step-row');
  var visibleIndex = 0;
  rows.forEach(function(row) {
    if (row.style.display === 'none') {
      return;
    }
    visibleIndex += 1;
    var cell = row.querySelector('.step-number');
    if (cell) {
      cell.textContent = visibleIndex;
    }
  });
}
