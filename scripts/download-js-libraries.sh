#!/bin/bash
# CVMA JavaScript Libraries Download Script
# Downloads Chart.js and other frequently used JS libraries for Salesforce Static Resources

set -e

# Configuration
LIBS_DIR="salesforce-static-resources"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "📦 CVMA JavaScript Libraries Download"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create libraries directory
mkdir -p "${LIBS_DIR}"
cd "${LIBS_DIR}"

echo "📁 Created directory: ${LIBS_DIR}"
echo "📍 Working in: $(pwd)"

# Function to download and verify library
download_library() {
    local name="$1"
    local url="$2"
    local filename="$3"
    local description="$4"
    
    echo ""
    echo "📥 Downloading ${name}..."
    echo "   Description: ${description}"
    echo "   URL: ${url}"
    
    if curl -L -o "${filename}" "${url}"; then
        local size=$(ls -lh "${filename}" | awk '{print $5}')
        echo "   ✅ Downloaded: ${filename} (${size})"
        
        # Basic verification - check if file is not empty and is valid
        if [ -s "${filename}" ]; then
            # Check if it's a valid JavaScript/CSS file
            if [[ "${filename}" == *.js ]]; then
                if grep -q "function\|var\|const\|let\|=>" "${filename}" 2>/dev/null; then
                    echo "   ✅ JavaScript file verified"
                else
                    echo "   ⚠️  Warning: May not be a valid JavaScript file"
                fi
            elif [[ "${filename}" == *.css ]]; then
                if grep -q "{.*}" "${filename}" 2>/dev/null; then
                    echo "   ✅ CSS file verified"
                else
                    echo "   ⚠️  Warning: May not be a valid CSS file"
                fi
            fi
        else
            echo "   ❌ Error: Downloaded file is empty"
            return 1
        fi
    else
        echo "   ❌ Failed to download ${name}"
        return 1
    fi
}

echo ""
echo "🎯 Starting library downloads..."

# 1. Chart.js - For data visualization (already referenced in dynamicResultsViewer)
download_library "Chart.js" \
    "https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.min.js" \
    "chart.min.js" \
    "Popular JavaScript charting library for creating responsive charts and graphs"

# 2. Chart.js CSS (if available)
download_library "Chart.js CSS" \
    "https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.min.css" \
    "chart.min.css" \
    "Chart.js CSS styles" || echo "   ℹ️  Chart.js CSS not available (normal for v4+)"

# 3. Lodash - Utility library for JavaScript
download_library "Lodash" \
    "https://cdn.jsdelivr.net/npm/lodash@4.17.21/lodash.min.js" \
    "lodash.min.js" \
    "Modern JavaScript utility library delivering modularity, performance & extras"

# 4. Moment.js - Date manipulation library
download_library "Moment.js" \
    "https://cdn.jsdelivr.net/npm/moment@2.30.1/min/moment.min.js" \
    "moment.min.js" \
    "Parse, validate, manipulate, and display dates and times in JavaScript"

# 5. Day.js - Lightweight alternative to Moment.js
download_library "Day.js" \
    "https://cdn.jsdelivr.net/npm/dayjs@1.11.10/dayjs.min.js" \
    "dayjs.min.js" \
    "Fast 2kB alternative to Moment.js with the same modern API"

# 6. D3.js - Data-driven documents (for advanced visualizations)
download_library "D3.js" \
    "https://cdn.jsdelivr.net/npm/d3@7.8.5/dist/d3.min.js" \
    "d3.min.js" \
    "Data-driven documents library for creating complex data visualizations"

# 7. Axios - HTTP client library
download_library "Axios" \
    "https://cdn.jsdelivr.net/npm/axios@1.6.5/dist/axios.min.js" \
    "axios.min.js" \
    "Promise-based HTTP client for the browser and Node.js"

# 8. SweetAlert2 - Beautiful popup alerts
download_library "SweetAlert2" \
    "https://cdn.jsdelivr.net/npm/sweetalert2@11.10.3/dist/sweetalert2.all.min.js" \
    "sweetalert2.min.js" \
    "Beautiful, responsive, customizable popup boxes"

# 9. Toastify - Lightweight toast notifications
download_library "Toastify JS" \
    "https://cdn.jsdelivr.net/npm/toastify-js@1.12.0/src/toastify.min.js" \
    "toastify.min.js" \
    "Vanilla JavaScript library for toast notifications"

download_library "Toastify CSS" \
    "https://cdn.jsdelivr.net/npm/toastify-js@1.12.0/src/toastify.min.css" \
    "toastify.min.css" \
    "Toastify CSS styles for toast notifications"

# 10. ApexCharts - Modern charting library (alternative to Chart.js)
download_library "ApexCharts" \
    "https://cdn.jsdelivr.net/npm/apexcharts@3.45.2/dist/apexcharts.min.js" \
    "apexcharts.min.js" \
    "Modern charting library for creating interactive visualizations"

# 11. Leaflet - Interactive maps library
download_library "Leaflet" \
    "https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.min.js" \
    "leaflet.min.js" \
    "Leading open-source JavaScript library for mobile-friendly interactive maps"

download_library "Leaflet CSS" \
    "https://cdn.jsdelivr.net/npm/leaflet@1.9.4/dist/leaflet.min.css" \
    "leaflet.min.css" \
    "Leaflet CSS styles for interactive maps"

# 12. Prism.js - Syntax highlighting
download_library "Prism.js Core" \
    "https://cdn.jsdelivr.net/npm/prismjs@1.29.0/prism.min.js" \
    "prism.min.js" \
    "Lightweight, extensible syntax highlighter"

download_library "Prism.js CSS" \
    "https://cdn.jsdelivr.net/npm/prismjs@1.29.0/themes/prism.min.css" \
    "prism.min.css" \
    "Prism.js CSS theme for syntax highlighting"

# 13. Sortable.js - Drag and drop lists
download_library "Sortable.js" \
    "https://cdn.jsdelivr.net/npm/sortablejs@1.15.2/Sortable.min.js" \
    "sortable.min.js" \
    "JavaScript library for reorderable drag-and-drop lists"

# 14. Hammer.js - Touch gesture library
download_library "Hammer.js" \
    "https://cdn.jsdelivr.net/npm/hammerjs@2.0.8/hammer.min.js" \
    "hammer.min.js" \
    "JavaScript library for detecting touch gestures"

# 15. Particles.js - Particle backgrounds
download_library "Particles.js" \
    "https://cdn.jsdelivr.net/npm/particles.js@2.0.0/particles.min.js" \
    "particles.min.js" \
    "Lightweight JavaScript library for creating particles backgrounds"

# 16. AOS - Animate On Scroll
download_library "AOS" \
    "https://cdn.jsdelivr.net/npm/aos@2.3.4/dist/aos.min.js" \
    "aos.min.js" \
    "Animate On Scroll library for scroll-triggered animations"

download_library "AOS CSS" \
    "https://cdn.jsdelivr.net/npm/aos@2.3.4/dist/aos.min.css" \
    "aos.min.css" \
    "AOS CSS animations for scroll-triggered effects"

# 17. Validate.js - Form validation
download_library "Validate.js" \
    "https://cdn.jsdelivr.net/npm/validate.js@0.13.1/validate.min.js" \
    "validate.min.js" \
    "Declarative validation written in JavaScript"

echo ""
echo "📊 Download Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Count successful downloads
SUCCESSFUL_JS=$(ls -1 *.js 2>/dev/null | wc -l)
SUCCESSFUL_CSS=$(ls -1 *.css 2>/dev/null | wc -l)
TOTAL_FILES=$(ls -1 *.js *.css 2>/dev/null | wc -l)

echo "📁 Files downloaded: ${TOTAL_FILES}"
echo "   JavaScript files: ${SUCCESSFUL_JS}"
echo "   CSS files: ${SUCCESSFUL_CSS}"
echo ""

# List all downloaded files with sizes
echo "📋 Downloaded Libraries:"
for file in *.js *.css 2>/dev/null; do
    if [ -f "$file" ]; then
        size=$(ls -lh "$file" | awk '{print $5}')
        echo "   ${file} (${size})"
    fi
done

echo ""
echo "🔧 Salesforce Static Resource Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create Static Resource directory structure
mkdir -p "../src/staticresources"

# Create metadata files for each JavaScript library
create_static_resource_metadata() {
    local filename="$1"
    local description="$2"
    local resource_name=$(echo "$filename" | sed 's/\.min\././g' | sed 's/\.[^.]*$//' | sed 's/[.-]//g')
    
    # Capitalize first letter for Salesforce naming convention
    resource_name=$(echo "$resource_name" | sed 's/^./\U&/')
    
    local metadata_file="../src/staticresources/${resource_name}.resource-meta.xml"
    
    cat > "$metadata_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<StaticResource xmlns="http://soap.sforce.com/2006/04/metadata">
    <cacheControl>Public</cacheControl>
    <contentType>text/javascript</contentType>
    <description>${description}</description>
</StaticResource>
EOF
    
    # Copy the actual file
    cp "$filename" "../src/staticresources/${resource_name}.resource"
    
    echo "   ✅ ${resource_name} → src/staticresources/"
}

echo "📦 Creating Salesforce Static Resources..."

# Create static resources for JavaScript files
if [ -f "chart.min.js" ]; then
    create_static_resource_metadata "chart.min.js" "Chart.js - JavaScript charting library for responsive charts"
fi

if [ -f "lodash.min.js" ]; then
    create_static_resource_metadata "lodash.min.js" "Lodash - Modern JavaScript utility library"
fi

if [ -f "moment.min.js" ]; then
    create_static_resource_metadata "moment.min.js" "Moment.js - Date manipulation library"
fi

if [ -f "dayjs.min.js" ]; then
    create_static_resource_metadata "dayjs.min.js" "Day.js - Lightweight date library"
fi

if [ -f "d3.min.js" ]; then
    create_static_resource_metadata "d3.min.js" "D3.js - Data-driven documents library"
fi

if [ -f "axios.min.js" ]; then
    create_static_resource_metadata "axios.min.js" "Axios - HTTP client library"
fi

if [ -f "sweetalert2.min.js" ]; then
    create_static_resource_metadata "sweetalert2.min.js" "SweetAlert2 - Beautiful popup alerts"
fi

if [ -f "apexcharts.min.js" ]; then
    create_static_resource_metadata "apexcharts.min.js" "ApexCharts - Modern charting library"
fi

if [ -f "leaflet.min.js" ]; then
    create_static_resource_metadata "leaflet.min.js" "Leaflet - Interactive maps library"
fi

echo ""

# Create usage documentation
cat > "../JAVASCRIPT-LIBRARIES-USAGE.md" << 'EOF'
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
import MomentLib from '@salesforce/resourceUrl/Momentjs';

await loadScript(this, MomentLib);
const formattedDate = moment(date).format('MMMM Do YYYY, h:mm a');
```

### Day.js (Lightweight Alternative)
**Static Resource**: `Dayjs`

```javascript
import DayLib from '@salesforce/resourceUrl/Dayjs';

await loadScript(this, DayLib);
const formattedDate = dayjs(date).format('MMMM D, YYYY h:mm A');
```

## 🎨 D3.js - Advanced Visualizations

**Static Resource**: `D3js`

```javascript
import D3Lib from '@salesforce/resourceUrl/D3js';

await loadScript(this, D3Lib);
// Create advanced data visualizations
d3.select(this.template.querySelector('.chart-container'))
  .selectAll('.bar')
  .data(data)
  .enter().append('div')
  .style('height', d => d.value + 'px');
```

## 🌐 Axios - HTTP Requests

**Static Resource**: `Axios`

```javascript
import AxiosLib from '@salesforce/resourceUrl/Axios';

await loadScript(this, AxiosLib);
// Make HTTP requests (for external APIs only)
const response = await axios.get('/services/data/v61.0/sobjects/');
```

## 🚨 SweetAlert2 - Beautiful Alerts

**Static Resource**: `Sweetalert2`

```javascript
import SweetAlert from '@salesforce/resourceUrl/Sweetalert2';

await loadScript(this, SweetAlert);
Swal.fire({
    title: 'Success!',
    text: 'Member profile updated successfully',
    icon: 'success',
    confirmButtonText: 'OK'
});
```

## 📈 ApexCharts - Alternative Charting

**Static Resource**: `Apexcharts`

```javascript
import ApexChartsLib from '@salesforce/resourceUrl/Apexcharts';

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

## 🗺️ Leaflet - Interactive Maps

**Static Resource**: `Leaflet`

```javascript
import LeafletLib from '@salesforce/resourceUrl/Leaflet';
import LeafletCSS from '@salesforce/resourceUrl/LeafletCSS';

await Promise.all([
    loadScript(this, LeafletLib),
    loadStyle(this, LeafletCSS)
]);

const map = L.map(this.template.querySelector('.map')).setView([30.3322, -81.6557], 13);
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);
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

## 📝 Static Resource Naming Convention

- **ChartJS**: Chart.js library
- **Lodash**: Lodash utility library  
- **Momentjs**: Moment.js date library
- **Dayjs**: Day.js lightweight date library
- **D3js**: D3.js data visualization
- **Axios**: Axios HTTP client
- **Sweetalert2**: SweetAlert2 popup library
- **Apexcharts**: ApexCharts visualization
- **Leaflet**: Leaflet mapping library

## 🚀 Deployment

1. Deploy static resources:
```bash
sf project deploy start --source-dir src/staticresources
```

2. Import in LWC components as shown in examples above

3. Test library loading and functionality in Salesforce org

Generated with [Claude Code](https://claude.ai/code) for CVMA Chapter 20-7
EOF

echo "📖 Created usage documentation: JAVASCRIPT-LIBRARIES-USAGE.md"

# Create deployment script
cat > "../scripts/deploy-js-libraries.sh" << 'EOF'
#!/bin/bash
# Deploy JavaScript libraries as Salesforce Static Resources

echo "🚀 Deploying JavaScript Libraries to Salesforce..."

# Deploy static resources
if sf project deploy start --source-dir src/staticresources; then
    echo "✅ JavaScript libraries deployed successfully!"
    echo ""
    echo "📋 Available Static Resources:"
    echo "   - @salesforce/resourceUrl/ChartJS"
    echo "   - @salesforce/resourceUrl/Lodash"  
    echo "   - @salesforce/resourceUrl/Momentjs"
    echo "   - @salesforce/resourceUrl/Dayjs"
    echo "   - @salesforce/resourceUrl/D3js"
    echo "   - @salesforce/resourceUrl/Axios"
    echo "   - @salesforce/resourceUrl/Sweetalert2"
    echo "   - @salesforce/resourceUrl/Apexcharts"
    echo "   - @salesforce/resourceUrl/Leaflet"
    echo ""
    echo "📖 See JAVASCRIPT-LIBRARIES-USAGE.md for usage examples"
else
    echo "❌ Deployment failed!"
    exit 1
fi
EOF

chmod +x "../scripts/deploy-js-libraries.sh"

echo "🚀 Created deployment script: scripts/deploy-js-libraries.sh"

echo ""
echo "✅ JavaScript Libraries Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Downloaded libraries in: ${LIBS_DIR}/"
echo "📦 Static resources created in: src/staticresources/"
echo "📖 Usage guide: JAVASCRIPT-LIBRARIES-USAGE.md"
echo "🚀 Deploy script: scripts/deploy-js-libraries.sh"
echo ""
echo "Next Steps:"
echo "1. Review downloaded libraries in ${LIBS_DIR}/"
echo "2. Deploy to Salesforce: bash scripts/deploy-js-libraries.sh"
echo "3. Import libraries in LWC components as shown in usage guide"
echo "4. Test functionality in your Salesforce org"
echo ""
echo "🎖️ Ready for CVMA development with modern JavaScript libraries!"