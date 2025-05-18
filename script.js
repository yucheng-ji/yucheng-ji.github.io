/**
 * 文件浏览器
 * 列顺序：Name | Description | Size | Modified time
 */

document.addEventListener('DOMContentLoaded', async () => {
    try {
        const response = await fetch('components/HE-resistant-materials-design.json');
        if (!response.ok) throw new Error('Failed to load files.json');
        const data = await response.json();

        const container = document.querySelector('.file-browser');
        const tableContainer = document.createElement('div');
        tableContainer.className = 'table-container';

        const table = document.createElement('table');
        table.className = 'file-table';
        table.innerHTML = `
            <thead>
                <tr>
                    <th class="col-name">Name</th>
                    <th class="col-desc">Description</th>
                    <th class="col-size">Size</th>
                    <th class="col-modified">Modified time</th>
                </tr>
            </thead>
            <tbody>
                ${generateFileRows(data.files)}
            </tbody>
        `;

        tableContainer.appendChild(table);
        container.appendChild(tableContainer);
        adjustColumnWidths(table);

    } catch (error) {
        document.querySelector('.file-browser').innerHTML = `
            <div class="error">Error loading files: ${error.message}</div>
        `;
    }
});

function adjustColumnWidths(table) {
    const cols = ['name', 'desc', 'size', 'modified'];

    cols.forEach(col => {
        const header = table.querySelector(`th.col-${col}`);
        const cells = [...table.querySelectorAll(`td.col-${col}`)];

        const maxWidth = Math.max(
            header.scrollWidth,
            ...cells.map(cell => cell.scrollWidth)
        );

        header.style.minWidth = `${maxWidth}px`;
        cells.forEach(cell => cell.style.minWidth = `${maxWidth}px`);
    });
}

function generateFileRows(files, depth = 0) {
    return files.map(file => {
        const isDir = file.type === 'directory';
        const indent = '&nbsp;'.repeat(depth * 4);

        return `
            <tr class="${isDir ? 'directory' : 'file'}">
                <td class="col-name">
                    ${indent}${isDir ? '📁' : '📄'} ${file.name}
                </td>
                <td class="col-desc">${file.description || ' '}</td>
                <td class="col-size">${isDir ? ' ' : formatSize(file.size)}</td>
                <td class="col-modified">${formatDate(file.modified)}</td>
            </tr>
            ${isDir && file.children ? generateFileRows(file.children, depth + 1) : ''}
        `;
    }).join('');
}

function formatSize(bytes) {
    if (bytes === 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return `${(bytes / Math.pow(1024, i)).toFixed(1)} ${units[i]}`;
}

function formatDate(isoString) {
    const date = new Date(isoString);
    return date.toLocaleString();
}

// 在DOMContentLoaded事件中添加
document.getElementById('download-all').addEventListener('click', function(e) {
    // 可以在这里添加下载前的确认或统计
    console.log('开始下载ZIP文件');

    // 如果需要先确认
    if(!confirm('确定要下载整个项目的ZIP文件吗？')) {
        e.preventDefault(); // 取消默认下载行为
    }
});