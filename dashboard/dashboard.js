// AWS FinOps Dashboard JavaScript

let charts = {};
let refreshInterval;

// Initialize dashboard on page load
document.addEventListener('DOMContentLoaded', function() {
    initializeDashboard();
    loadData();
    
    // Set up auto-refresh every 5 minutes
    refreshInterval = setInterval(loadData, 300000);
});

function initializeDashboard() {
    // Initialize charts
    initializeCharts();
    
    // Load available data files
    loadDataFiles();
}

function initializeCharts() {
    // Daily Cost Trends Chart
    const dailyCostCtx = document.getElementById('dailyCostChart').getContext('2d');
    charts.dailyCost = new Chart(dailyCostCtx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Daily Cost',
                data: [],
                borderColor: 'rgb(75, 192, 192)',
                backgroundColor: 'rgba(75, 192, 192, 0.1)',
                tension: 0.1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return '$' + value.toFixed(2);
                        }
                    }
                }
            },
            plugins: {
                title: {
                    display: true,
                    text: 'Daily Cost Trends (Last 30 Days)'
                }
            }
        }
    });

    // Service Cost Chart
    const serviceCtx = document.getElementById('serviceChart').getContext('2d');
    charts.service = new Chart(serviceCtx, {
        type: 'doughnut',
        data: {
            labels: [],
            datasets: [{
                data: [],
                backgroundColor: [
                    '#FF6384',
                    '#36A2EB',
                    '#FFCE56',
                    '#4BC0C0',
                    '#9966FF',
                    '#FF9F40',
                    '#FF6384',
                    '#36A2EB'
                ]
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                title: {
                    display: true,
                    text: 'Cost Distribution by Service'
                },
                legend: {
                    position: 'bottom'
                }
            }
        }
    });

    // Region Cost Chart
    const regionCtx = document.getElementById('regionChart').getContext('2d');
    charts.region = new Chart(regionCtx, {
        type: 'bar',
        data: {
            labels: [],
            datasets: [{
                label: 'Cost by Region',
                data: [],
                backgroundColor: 'rgba(54, 162, 235, 0.6)',
                borderColor: 'rgba(54, 162, 235, 1)',
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        callback: function(value) {
                            return '$' + value.toFixed(2);
                        }
                    }
                }
            },
            plugins: {
                title: {
                    display: true,
                    text: 'Cost Distribution by Region'
                }
            }
        }
    });
}

async function loadData() {
    try {
        // Load cost data from API
        const costData = await fetchLatestCostData();
        
        if (costData) {
            console.log('Loaded cost data:', costData);
            updateMetrics(costData);
            updateCharts(costData);
        } else {
            console.warn('No cost data available');
            showError('No cost data available. Please run the FinOps scripts to generate data.');
        }
        
        // Update last refresh time
        updateLastRefresh();
        
    } catch (error) {
        console.error('Error loading data:', error);
        showError('Failed to load data. Please check if the API is running.');
    }
}

async function fetchLatestCostData() {
    try {
        // Try to fetch from API first
        const response = await fetch('http://localhost:8081/api/latest-data');
        if (response.ok) {
            return await response.json();
        }
    } catch (error) {
        console.log('API not available, trying direct file access...');
    }
    
    // Fallback to direct file access
    return await fetchDataFromFiles();
}

async function fetchDataFromFiles() {
    try {
        // Get list of available files
        const files = await listDataFiles();
        
        if (files.length === 0) {
            throw new Error('No data files found');
        }
        
        // Load the most recent cost data
        const costData = await loadMostRecentFile(files, 'daily_costs_');
        const serviceData = await loadMostRecentFile(files, 'monthly_costs_by_service_');
        const regionData = await loadMostRecentFile(files, 'costs_by_region_');
        
        return {
            dailyCosts: costData,
            serviceCosts: serviceData,
            regionCosts: regionData
        };
        
    } catch (error) {
        console.error('Error fetching data from files:', error);
        return null;
    }
}

async function listDataFiles() {
    // This would need to be implemented based on your file structure
    // For now, return a mock list
    return [
        'daily_costs_20250716_100000.json',
        'monthly_costs_by_service_20250716_100000.json',
        'costs_by_region_20250716_100000.json'
    ];
}

async function loadMostRecentFile(files, prefix) {
    const matchingFiles = files.filter(f => f.includes(prefix));
    if (matchingFiles.length === 0) return null;
    
    // Sort by timestamp (assuming filename format includes timestamp)
    const mostRecent = matchingFiles.sort().reverse()[0];
    
    try {
        const response = await fetch(`/data/account1/${mostRecent}`);
        if (response.ok) {
            return await response.json();
        }
    } catch (error) {
        console.error(`Error loading file ${mostRecent}:`, error);
    }
    
    return null;
}

function updateMetrics(data) {
    // Update total cost
    if (data.daily_costs && data.daily_costs.ResultsByTime) {
        const totalCost = calculateTotalCost(data.daily_costs);
        document.getElementById('total-cost').textContent = '$' + totalCost.toFixed(2);
    } else {
        document.getElementById('total-cost').textContent = 'N/A';
    }
    
    // Update forecasted cost from real data
    if (data.forecast && data.forecast.Total) {
        const forecastAmount = parseFloat(data.forecast.Total.Amount);
        document.getElementById('forecasted-cost').textContent = '$' + forecastAmount.toFixed(2);
    } else {
        document.getElementById('forecasted-cost').textContent = 'N/A';
    }
    
    // Update RI utilization from real data
    if (data.ri_utilization && data.ri_utilization.Total) {
        const riUtilization = parseFloat(data.ri_utilization.Total.UtilizationPercentage);
        document.getElementById('ri-utilization').textContent = riUtilization.toFixed(1) + '%';
    } else {
        document.getElementById('ri-utilization').textContent = 'N/A';
    }
    
    // Update Savings Plans utilization from real data
    if (data.savings_plans && data.savings_plans.Total && data.savings_plans.Total.Utilization) {
        const spUtilization = parseFloat(data.savings_plans.Total.Utilization.UtilizationPercentage);
        document.getElementById('sp-utilization').textContent = spUtilization.toFixed(1) + '%';
    } else {
        document.getElementById('sp-utilization').textContent = 'N/A';
    }
    
    // Update cost change indicator
    updateCostChangeIndicator(data);
}

function updateCharts(data) {
    // Update daily cost chart
    if (data.daily_costs && data.daily_costs.ResultsByTime) {
        updateDailyCostChart(data.daily_costs);
    }
    
    // Update service cost chart
    if (data.service_costs && data.service_costs.ResultsByTime) {
        updateServiceChart(data.service_costs);
    }
    
    // Update region cost chart
    if (data.region_costs && data.region_costs.ResultsByTime) {
        updateRegionChart(data.region_costs);
    }
}

function updateDailyCostChart(data) {
    const labels = [];
    const costs = [];
    
    if (!data || !data.ResultsByTime || !Array.isArray(data.ResultsByTime)) {
        console.warn('Invalid data for daily cost chart:', data);
        return;
    }
    
    data.ResultsByTime.forEach(item => {
        try {
            if (item && item.TimePeriod && item.TimePeriod.Start && 
                item.Total && item.Total.BlendedCost && item.Total.BlendedCost.Amount) {
                labels.push(moment(item.TimePeriod.Start).format('MMM DD'));
                const amount = parseFloat(item.Total.BlendedCost.Amount);
                costs.push(isNaN(amount) ? 0 : amount);
            }
        } catch (error) {
            console.warn('Error processing daily cost item:', item, error);
        }
    });
    
    charts.dailyCost.data.labels = labels;
    charts.dailyCost.data.datasets[0].data = costs;
    charts.dailyCost.update();
}

function updateServiceChart(data) {
    const services = {};
    
    if (!data || !data.ResultsByTime || !Array.isArray(data.ResultsByTime)) {
        console.warn('Invalid data for service chart:', data);
        return;
    }
    
    data.ResultsByTime.forEach(period => {
        try {
            if (period && period.Groups && Array.isArray(period.Groups)) {
                period.Groups.forEach(group => {
                    try {
                        if (group && group.Keys && group.Keys[0] && 
                            group.Metrics && group.Metrics.BlendedCost && group.Metrics.BlendedCost.Amount) {
                            const service = group.Keys[0];
                            const cost = parseFloat(group.Metrics.BlendedCost.Amount);
                            if (!isNaN(cost)) {
                                services[service] = (services[service] || 0) + cost;
                            }
                        }
                    } catch (error) {
                        console.warn('Error processing service group:', group, error);
                    }
                });
            }
        } catch (error) {
            console.warn('Error processing service period:', period, error);
        }
    });
    
    const labels = Object.keys(services);
    const costs = Object.values(services);
    
    charts.service.data.labels = labels;
    charts.service.data.datasets[0].data = costs;
    charts.service.update();
}

function updateRegionChart(data) {
    const regions = {};
    
    if (!data || !data.ResultsByTime || !Array.isArray(data.ResultsByTime)) {
        console.warn('Invalid data for region chart:', data);
        return;
    }
    
    data.ResultsByTime.forEach(period => {
        try {
            if (period && period.Groups && Array.isArray(period.Groups)) {
                period.Groups.forEach(group => {
                    try {
                        if (group && group.Keys && group.Keys[0] && 
                            group.Metrics && group.Metrics.BlendedCost && group.Metrics.BlendedCost.Amount) {
                            const region = group.Keys[0];
                            const cost = parseFloat(group.Metrics.BlendedCost.Amount);
                            if (!isNaN(cost)) {
                                regions[region] = (regions[region] || 0) + cost;
                            }
                        }
                    } catch (error) {
                        console.warn('Error processing region group:', group, error);
                    }
                });
            }
        } catch (error) {
            console.warn('Error processing region period:', period, error);
        }
    });
    
    const labels = Object.keys(regions);
    const costs = Object.values(regions);
    
    charts.region.data.labels = labels;
    charts.region.data.datasets[0].data = costs;
    charts.region.update();
}

function calculateTotalCost(data) {
    let total = 0;
    
    if (!data || !data.ResultsByTime || !Array.isArray(data.ResultsByTime)) {
        console.warn('Invalid data structure for cost calculation:', data);
        return 0;
    }
    
    data.ResultsByTime.forEach(item => {
        try {
            if (item && item.Total && item.Total.BlendedCost && item.Total.BlendedCost.Amount) {
                const amount = parseFloat(item.Total.BlendedCost.Amount);
                if (!isNaN(amount)) {
                    total += amount;
                }
            }
        } catch (error) {
            console.warn('Error processing cost item:', item, error);
        }
    });
    
    return total;
}

function updateCostChangeIndicator(data) {
    // This would calculate cost change percentage if historical data is available
    // For now, just show a placeholder
    const costChangeElement = document.getElementById('cost-change');
    if (costChangeElement) {
        costChangeElement.textContent = 'Data updated';
    }
}

function updateLastRefresh() {
    const now = new Date();
    console.log('Data refreshed at:', now.toLocaleString());
}

function loadDataFiles() {
    // Load and display available data files
    const dataFilesContainer = document.getElementById('data-files');
    
    // Mock data files for now
    const mockFiles = [
        { name: 'daily_costs_20250716_100000.json', account: 'account1', size: '45 KB', time: '10 mins ago' },
        { name: 'monthly_costs_by_service_20250716_100000.json', account: 'account1', size: '32 KB', time: '10 mins ago' },
        { name: 'ri_utilization_20250716_095000.json', account: 'account2', size: '28 KB', time: '15 mins ago' },
        { name: 'cost_forecast_20250716_094000.json', account: 'account3', size: '18 KB', time: '20 mins ago' }
    ];
    
    dataFilesContainer.innerHTML = '';
    
    mockFiles.forEach(file => {
        const fileCard = document.createElement('div');
        fileCard.className = 'col-md-3 mb-3';
        fileCard.innerHTML = `
            <div class="card">
                <div class="card-body">
                    <h6 class="card-title">${file.name}</h6>
                    <p class="card-text">
                        <small class="text-muted">
                            ${file.account} • ${file.size} • ${file.time}
                        </small>
                    </p>
                    <a href="/data/${file.account}/${file.name}" class="btn btn-sm btn-outline-primary" target="_blank">
                        View JSON
                    </a>
                </div>
            </div>
        `;
        dataFilesContainer.appendChild(fileCard);
    });
}

function refreshData() {
    // Show loading state
    const refreshBtn = document.querySelector('.refresh-btn');
    const originalText = refreshBtn.innerHTML;
    refreshBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Refreshing...';
    refreshBtn.disabled = true;
    
    // Reload data
    loadData().then(() => {
        // Restore button
        refreshBtn.innerHTML = originalText;
        refreshBtn.disabled = false;
    }).catch(() => {
        // Restore button on error
        refreshBtn.innerHTML = originalText;
        refreshBtn.disabled = false;
    });
}

function showError(message) {
    // Simple error display
    const errorDiv = document.createElement('div');
    errorDiv.className = 'alert alert-danger alert-dismissible fade show';
    errorDiv.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.insertBefore(errorDiv, document.body.firstChild);
    
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
        errorDiv.remove();
    }, 5000);
}
