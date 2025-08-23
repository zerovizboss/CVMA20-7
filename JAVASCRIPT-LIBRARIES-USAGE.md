# CVMA JavaScript Libraries Usage Guide

This document provides usage examples for the JavaScript libraries downloaded for the CVMA Salesforce project.

## 📊 Chart.js - Data Visualization

**Static Resource**: `ChartJS`
**Usage**: Already implemented in `dynamicResultsViewer` component

```javascript
import { loadScript } from 'lightning/platformResourceLoader';
import ChartJS from '@salesforce/resourceUrl/ChartJS';

// Load and use Chart.js
await loadScript(this, ChartJS);
const ctx = canvas.getContext('2d');
const chart = new Chart(ctx, {
    type: 'bar',
    data: chartData,
    options: chartOptions
});
```

## 🛠️ Lodash - Utility Functions

**Static Resource**: `Lodash`

```javascript
import { loadScript } from 'lightning/platformResourceLoader';
import LodashLib from '@salesforce/resourceUrl/Lodash';

await loadScript(this, LodashLib);
// Use lodash utilities
const uniqueValues = _.uniq(arrayData);
const groupedData = _.groupBy(members, 'membershipLevel');
```

## 📅 Date Libraries

### Moment.js
**Static Resource**: `Momentjs`

```javascript
import { loadScript } from 'lightning/platformResourceLoader';
import MomentLib from '@salesforce/resourceUrl/Momentjs';

await loadScript(this, MomentLib);
const formattedDate = moment(date).format('MMMM Do YYYY, h:mm a');
```

## 🚨 SweetAlert2 - Beautiful Alerts

**Static Resource**: `SweetAlert2`

```javascript
import { loadScript } from 'lightning/platformResourceLoader';
import SweetAlert from '@salesforce/resourceUrl/SweetAlert2';

await loadScript(this, SweetAlert);
Swal.fire({
    title: 'Success!',
    text: 'Member profile updated successfully',
    icon: 'success',
    confirmButtonText: 'OK'
});
```

## 📈 ApexCharts - Alternative Charting

**Static Resource**: `ApexCharts`

```javascript
import { loadScript } from 'lightning/platformResourceLoader';
import ApexChartsLib from '@salesforce/resourceUrl/ApexCharts';

await loadScript(this, ApexChartsLib);
const options = {
    series: [{
        name: 'Members',
        data: [30, 40, 35, 50, 49, 60, 70, 91, 125]
    }],
    chart: {
        type: 'line',
        height: 350
    }
};
const chart = new ApexCharts(this.template.querySelector('.chart'), options);
chart.render();
```

## 🎯 Best Practices for Salesforce LWC

### 1. Loading Libraries
```javascript
async connectedCallback() {
    try {
        await loadScript(this, LibraryResource);
        this.libraryLoaded = true;
        this.initializeLibrary();
    } catch (error) {
        console.error('Failed to load library:', error);
    }
}
```

### 2. Conditional Usage
```javascript
handleAction() {
    if (this.libraryLoaded && typeof LibraryGlobal !== 'undefined') {
        // Use library functionality
        LibraryGlobal.doSomething();
    } else {
        console.warn('Library not loaded yet');
    }
}
```

### 3. Memory Management
```javascript
disconnectedCallback() {
    // Clean up library instances
    if (this.chartInstance) {
        this.chartInstance.destroy();
    }
}
```

## 📦 Available Libraries

### Core Libraries (Ready to Use)
- **ChartJS**: Chart.js library for data visualization
- **Lodash**: Utility library for JavaScript operations
- **Momentjs**: Date manipulation and formatting
- **SweetAlert2**: Beautiful popup alerts and confirmations
- **ApexCharts**: Modern charting alternative to Chart.js

### Additional Libraries Downloaded
The following libraries are available in `salesforce-static-resources/` and can be set up as static resources when needed:

- **d3.min.js**: D3.js for advanced data visualizations
- **axios.min.js**: HTTP client for external API calls
- **dayjs.min.js**: Lightweight alternative to Moment.js
- **leaflet.min.js**: Interactive maps library
- **toastify.min.js**: Toast notifications
- **prism.min.js**: Syntax highlighting
- **sortable.min.js**: Drag and drop lists
- **hammer.min.js**: Touch gesture detection
- **particles.min.js**: Particle backgrounds
- **aos.min.js**: Animate on scroll
- **validate.min.js**: Form validation

## 🚀 Deployment

1. Deploy the core static resources:
```bash
sf project deploy start --source-dir src/staticresources
```

2. Import in LWC components:
```javascript
import LibraryName from '@salesforce/resourceUrl/StaticResourceName';
```

3. Load and use in your components as shown in the examples above

## 📋 Quick Reference

### Chart.js (Already Working)
```javascript
import ChartJS from '@salesforce/resourceUrl/ChartJS';
await loadScript(this, ChartJS);
// Use Chart constructor
```

### Lodash Utilities
```javascript
import Lodash from '@salesforce/resourceUrl/Lodash';
await loadScript(this, Lodash);
// Use _ utilities
```

### Beautiful Alerts
```javascript
import SweetAlert2 from '@salesforce/resourceUrl/SweetAlert2';
await loadScript(this, SweetAlert2);
// Use Swal.fire()
```

### Date Formatting
```javascript
import Momentjs from '@salesforce/resourceUrl/Momentjs';
await loadScript(this, Momentjs);
// Use moment() functions
```

### Modern Charts
```javascript
import ApexCharts from '@salesforce/resourceUrl/ApexCharts';
await loadScript(this, ApexCharts);
// Use ApexCharts constructor
```

Generated with [Claude Code](https://claude.ai/code) for CVMA Chapter 20-7
