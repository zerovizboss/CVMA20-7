#!/bin/bash
# Deploy JavaScript libraries as Salesforce Static Resources

echo "🚀 Deploying JavaScript Libraries to Salesforce..."

# Deploy static resources
if sf project deploy start --source-dir src/staticresources; then
    echo "✅ JavaScript libraries deployed successfully!"
    echo ""
    echo "📋 Available Static Resources:"
    echo "   - @salesforce/resourceUrl/ChartJS (Chart.js - already in use)"
    echo "   - @salesforce/resourceUrl/Lodash (Utility functions)"  
    echo "   - @salesforce/resourceUrl/Momentjs (Date manipulation)"
    echo "   - @salesforce/resourceUrl/SweetAlert2 (Beautiful alerts)"
    echo "   - @salesforce/resourceUrl/ApexCharts (Modern charts)"
    echo ""
    echo "📖 See JAVASCRIPT-LIBRARIES-USAGE.md for usage examples"
    echo ""
    echo "🎯 Next Steps:"
    echo "1. Import libraries in LWC components using:"
    echo "   import LibraryName from '@salesforce/resourceUrl/StaticResourceName';"
    echo "2. Load using loadScript() in connectedCallback()"
    echo "3. Test functionality in your Salesforce org"
else
    echo "❌ Deployment failed!"
    exit 1
fi