// Добавьте эту функцию для отладки
async function debugInfo() {
    try {
        const response = await fetch(`${API_BASE}/api/hosts`);
        const data = await response.json();
        console.log('Debug info:', data);

        if (data.success) {
            console.log('File exists:', data.content.length > 0);
            console.log('Entries count:', data.entries ? data.entries.length : 0);
        }
    } catch (error) {
        console.error('Debug error:', error);
    }
}

// Вызывайте при загрузке
document.addEventListener('DOMContentLoaded', function() {
    console.log('Docker Hosts Manager initialized');
    loadHosts();
    updateSystemInfo();
    debugInfo(); // Добавьте эту строку

    // Авто-обновление каждые 10 секунд
    setInterval(() => {
        if (document.visibilityState === 'visible') {
            loadHosts();
        }
    }, 10000);
});
